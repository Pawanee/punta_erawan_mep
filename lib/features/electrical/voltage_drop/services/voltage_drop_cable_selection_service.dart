import '../../cable_design/enums/core_type.dart';
import '../../cable_design/models/cable_table_row.dart';
import '../../cable_design/services/grouping_factor_service.dart';
import '../enums/voltage_drop_core_type.dart';
import '../models/voltage_drop_cable_selection_request.dart';
import '../models/voltage_drop_cable_selection_result.dart';
import '../models/voltage_drop_request.dart';
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
    GroupingFactorService? groupingFactorService,
    VoltageDropRepository? voltageDropRepository,
    VoltageDropCalculationService? voltageDropCalculationService,
  })  : groupingFactorService =
            groupingFactorService ?? GroupingFactorService(),
        voltageDropRepository =
            voltageDropRepository ?? const VoltageDropRepository(),
        voltageDropCalculationService =
            voltageDropCalculationService ??
                const VoltageDropCalculationService();

  final GroupingFactorService groupingFactorService;
  final VoltageDropRepository voltageDropRepository;
  final VoltageDropCalculationService voltageDropCalculationService;

  static const double maxSingleCableSize = 240.0;
  static const int maxParallelRuns = 20;

  Future<VoltageDropCableSelectionResult> select({
    required VoltageDropCableSelectionRequest request,
    required List<CableTableRow> candidates,
  }) async {
    final cableRequest = request.cableRequest;

    if (cableRequest.loadCurrent <= 0) {
      return VoltageDropCableSelectionResult.error(
        'Load Current ต้องมากกว่า 0 A',
      );
    }

    if (request.lengthM <= 0) {
      return VoltageDropCableSelectionResult.error(
        'Length ต้องมากกว่า 0 m',
      );
    }

    if (request.systemVoltage <= 0) {
      return VoltageDropCableSelectionResult.error(
        'System Voltage ต้องมากกว่า 0 V',
      );
    }

    if (request.allowableVoltageDropPercent <= 0) {
      return VoltageDropCableSelectionResult.error(
        'Allowable Voltage Drop ต้องมากกว่า 0 %',
      );
    }

    if (cableRequest.coreType == CoreType.singleCore &&
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

    filtered.sort(
      (a, b) => a.cableSizeSqmm.compareTo(b.cableSizeSqmm),
    );

    final groupingFactor = await groupingFactorService.getFactor(
      circuits: cableRequest.groupingCircuits,
      enclosed: cableRequest.installationMethod.name == 'group1',
    );

    if (groupingFactor <= 0) {
      return VoltageDropCableSelectionResult.error(
        'Grouping Factor ไม่ถูกต้อง',
      );
    }

    final requiredCurrent =
        cableRequest.loadCurrent / groupingFactor;

    final tableRows = await voltageDropRepository.loadTable(
      insulation: request.insulation,
      coreType: cableRequest.coreType == CoreType.singleCore
          ? VoltageDropCoreType.singleCore
          : VoltageDropCoreType.multiCore,
    );

    if (tableRows.isEmpty) {
      return VoltageDropCableSelectionResult.error(
        'Voltage Drop Table 9.1 - 9.4 ไม่มีข้อมูล',
      );
    }

    for (int runs = 1; runs <= maxParallelRuns; runs++) {
      // Required Current / Run is used ONLY for ampacity checking.
      final requiredCurrentPerRun = requiredCurrent / runs;

      // Voltage Drop must use the actual load current carried by
      // each parallel run, not the derated/required current.
      final actualLoadCurrentPerRun =
          cableRequest.loadCurrent / runs;

      for (final cable in filtered) {
        if (cable.cableSizeSqmm > maxSingleCableSize) {
          continue;
        }

        // ---------------------------------------------------------------
        // เงื่อนไขที่ 1: Ampacity
        // ---------------------------------------------------------------
        if (cable.ampacity < requiredCurrentPerRun) {
          continue;
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
            currentA: actualLoadCurrentPerRun,
            lengthM: request.lengthM,
            systemVoltage: request.systemVoltage,
            allowableVoltageDropPercent:
                request.allowableVoltageDropPercent,
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

        final sizeText = cable.cableSizeSqmm % 1 == 0
            ? cable.cableSizeSqmm.toInt().toString()
            : cable.cableSizeSqmm.toString();

        return VoltageDropCableSelectionResult.success(
  cableSizeSqmm: cable.cableSizeSqmm,
  ampacity: cable.ampacity,
  cableArrangement: '$runs × $sizeText sq.mm',

  // Ampacity source
  ampacityReference: cable.reference,

  // Voltage Drop source
  voltageDropReference: vdResult.table!,

  groupingFactor: groupingFactor,
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
