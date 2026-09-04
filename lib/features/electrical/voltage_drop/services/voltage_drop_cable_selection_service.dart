import '../../cable_design/enums/core_type.dart';
import '../../cable_design/models/cable_table_row.dart';
import '../../cable_design/models/table_5_43_temperature_factor.dart';
import '../../cable_design/services/ampacity_correction_service.dart';
import '../../cable_design/enums/conductor_temperature_class.dart';
import '../enums/voltage_drop_core_type.dart';
import '../models/voltage_drop_cable_selection_request.dart';
import '../models/voltage_drop_cable_selection_result.dart';
import '../models/voltage_drop_request.dart';
import '../models/voltage_drop_table_entry.dart';
import '../repositories/voltage_drop_repository.dart';
import 'voltage_drop_calculation_service.dart';

/// ============================================================================
/// VOLTAGE DROP CABLE SELECTION SERVICE
///
/// PART 3
///
/// หน้าที่
/// 1. รับ Candidate จาก Table 5-20
/// 2. คำนวณ Required Current จาก Grouping Factor
/// 3. ตรวจ Ampacity ต่อจำนวน Parallel Run
/// 4. ตรวจ Voltage Drop จาก Table 9.1 - 9.4
/// 5. เลือกสายขนาดเล็กที่สุดที่ผ่านทั้งสองเงื่อนไข
///
/// หลักสำคัญ
/// - ใช้ค่าตาราง mV/A/m โดยตรง
/// - ใช้ Current จริงต่อ Run
/// - ใช้ Length จริง
/// - ไม่คำนวณ R/X
/// - ไม่ interpolate
/// - ไม่สร้างค่าตารางเอง
/// ============================================================================
class VoltageDropCableSelectionService {
  VoltageDropCableSelectionService({
    VoltageDropRepository? voltageDropRepository,
    VoltageDropCalculationService? voltageDropCalculationService,
    AmpacityCorrectionService? ampacityCorrectionService,
  }) : voltageDropRepository =
           voltageDropRepository ?? const VoltageDropRepository(),
       voltageDropCalculationService =
           voltageDropCalculationService ??
           const VoltageDropCalculationService(),
       ampacityCorrectionService =
           ampacityCorrectionService ?? const AmpacityCorrectionService();

  final VoltageDropRepository voltageDropRepository;
  final VoltageDropCalculationService voltageDropCalculationService;
  final AmpacityCorrectionService ampacityCorrectionService;

  static const double maxSingleCableSize = 240.0;
  static const int maxParallelRuns = 20;

  Future<VoltageDropCableSelectionResult> select({
    required VoltageDropCableSelectionRequest request,
    required List<CableTableRow> candidates,
    required double groupingFactor,
    required double temperatureFactor,
    required ConductorTemperatureClass conductorTemperatureClass,
  }) async {
    final cableRequest = request.cableRequest;

    if (cableRequest.loadCurrent <= 0) {
      return VoltageDropCableSelectionResult.error(
        'Load Current ต้องมากกว่า 0 A',
      );
    }

    if (request.voltageDropEnabled && request.lengthM <= 0) {
      return VoltageDropCableSelectionResult.error('Length ต้องมากกว่า 0 m');
    }

    if (request.voltageDropEnabled && request.systemVoltage <= 0) {
      return VoltageDropCableSelectionResult.error(
        'System Voltage ต้องมากกว่า 0 V',
      );
    }

    if (request.voltageDropEnabled &&
        request.allowableVoltageDropPercent <= 0) {
      return VoltageDropCableSelectionResult.error(
        'Allowable Voltage Drop ต้องมากกว่า 0 %',
      );
    }

    if (request.voltageDropEnabled &&
        cableRequest.coreType == CoreType.singleCore &&
        !request.installationGroup.isGroup1_2_5 &&
        request.arrangement == null) {
      return VoltageDropCableSelectionResult.error(
        'Single Core สำหรับ Group 3, 4, 6, 7 ต้องระบุ Cable Arrangement',
      );
    }

    final filtered = candidates.where((row) {
      return row.cableType == cableRequest.cableType &&
          row.installationMethod == cableRequest.installationMethod &&
          row.loadedConductors == cableRequest.loadedConductors &&
          row.coreType == cableRequest.coreType;
    }).toList();

    if (filtered.isEmpty) {
      return VoltageDropCableSelectionResult.error(
        'ไม่พบ Candidate ใน Table 5-20',
      );
    }

    filtered.sort((a, b) => a.cableSizeSqmm.compareTo(b.cableSizeSqmm));

    if (groupingFactor <= 0) {
      return VoltageDropCableSelectionResult.error(
        'Grouping Factor ไม่ถูกต้อง',
      );
    }

    // Retained for existing result compatibility. Selection itself evaluates
    // corrected ampacity per run against actual current per run below.
    final requiredCurrent = cableRequest.loadCurrent / groupingFactor;

    final tableRows = request.voltageDropEnabled
        ? await voltageDropRepository.loadTable(
            insulation: request.insulation,
            coreType: cableRequest.coreType == CoreType.singleCore
                ? VoltageDropCoreType.singleCore
                : VoltageDropCoreType.multiCore,
          )
        : const <VoltageDropTableEntry>[];

    if (request.voltageDropEnabled && tableRows.isEmpty) {
      return VoltageDropCableSelectionResult.error(
        'Voltage Drop Table 9.1 - 9.4 ไม่มีข้อมูล',
      );
    }

    for (int runs = 1; runs <= maxParallelRuns; runs++) {
      final currentPerRun = cableRequest.loadCurrent / runs;

      for (final cable in filtered) {
        if (cable.cableSizeSqmm > maxSingleCableSize) {
          continue;
        }

        // ---------------------------------------------------------------
        // เงื่อนไขที่ 1: Ampacity
        // ---------------------------------------------------------------
        final correctedAmpacityPerRun = ampacityCorrectionService.calculate(
          baseAmpacity: cable.ampacity,
          groupingFactor: groupingFactor,
          temperatureFactor: temperatureFactor,
        );

        if (correctedAmpacityPerRun == null ||
            correctedAmpacityPerRun < currentPerRun) {
          continue;
        }

        final sizeText = cable.cableSizeSqmm % 1 == 0
            ? cable.cableSizeSqmm.toInt().toString()
            : cable.cableSizeSqmm.toString();

        if (!request.voltageDropEnabled) {
          return VoltageDropCableSelectionResult.ampacityOnly(
            cableSizeSqmm: cable.cableSizeSqmm,
            ampacity: cable.ampacity,
            cableArrangement: '$runs × $sizeText sq.mm',
            ampacityReference: cable.reference,
            groupingFactor: groupingFactor,
            temperatureFactor: temperatureFactor,
            baseAmpacityPerRun: cable.ampacity,
            correctedAmpacityPerRun: correctedAmpacityPerRun,
            sourceTableId: cable.sourceTableId,
            sourceTableDisplayName: cable.sourceTableDisplayName,
            installationMethod: cable.installationMethod,
            loadedConductors: cable.loadedConductors,
            coreType: cable.coreType,
            cableType: cableRequest.cableType,
            conductorTemperatureClass: conductorTemperatureClass,
            ambientTemperatureC: cableRequest.ambientTemperature,
            groupingCircuits: cableRequest.groupingCircuits,
            groupingReference: 'Table 5-8',
            temperatureReference: Table543TemperatureFactor.reference,
            requiredCurrent: requiredCurrent,
            runs: runs,
          );
        }

        // ---------------------------------------------------------------
        // เงื่อนไขที่ 2: Voltage Drop
        // ---------------------------------------------------------------
        final vdResult = voltageDropCalculationService.calculate(
          request: VoltageDropRequest(
            insulation: request.insulation,
            coreType: cableRequest.coreType == CoreType.singleCore
                ? VoltageDropCoreType.singleCore
                : VoltageDropCoreType.multiCore,
            phase: request.phase,
            sizeSqmm: cable.cableSizeSqmm,
            currentA: currentPerRun,
            lengthM: request.lengthM,
            systemVoltage: request.systemVoltage,
            allowableVoltageDropPercent: request.allowableVoltageDropPercent,
            installationGroup: request.installationGroup,
            arrangement: request.arrangement,
          ),
          rows: tableRows,
        );

        if (!vdResult.isSuccess) {
          continue;
        }

        if (vdResult.isWithinLimit != true) {
          continue;
        }

        return VoltageDropCableSelectionResult.success(
          cableSizeSqmm: cable.cableSizeSqmm,
          ampacity: cable.ampacity,
          cableArrangement: '$runs × $sizeText sq.mm',

          // Ampacity source
          ampacityReference: cable.reference,

          // Voltage Drop source
          voltageDropReference: vdResult.table!,

          groupingFactor: groupingFactor,
          temperatureFactor: temperatureFactor,
          baseAmpacityPerRun: cable.ampacity,
          correctedAmpacityPerRun: correctedAmpacityPerRun,
          sourceTableId: cable.sourceTableId,
          sourceTableDisplayName: cable.sourceTableDisplayName,
          installationMethod: cable.installationMethod,
          loadedConductors: cable.loadedConductors,
          coreType: cable.coreType,
          cableType: cableRequest.cableType,
          conductorTemperatureClass: conductorTemperatureClass,
          ambientTemperatureC: cableRequest.ambientTemperature,
          groupingCircuits: cableRequest.groupingCircuits,
          groupingReference: 'Table 5-8',
          temperatureReference: Table543TemperatureFactor.reference,
          requiredCurrent: requiredCurrent,
          voltageDropV: vdResult.voltageDropV!,
          voltageDropPercent: vdResult.voltageDropPercent!,
          mvPerAperM: vdResult.mvPerAperM!,
          runs: runs,
        );
      }
    }

    return VoltageDropCableSelectionResult.error(
      'ไม่พบขนาดสายที่ผ่านทั้ง Ampacity และ Voltage Drop',
    );
  }
}
