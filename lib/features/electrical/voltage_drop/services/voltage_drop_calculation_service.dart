import '../enums/cable_arrangement.dart';
import '../enums/voltage_drop_core_type.dart';
import '../enums/voltage_drop_installation_group.dart';
import '../enums/voltage_phase.dart';
import '../models/voltage_drop_request.dart';
import '../models/voltage_drop_result.dart';
import '../models/voltage_drop_table_entry.dart';

/// ============================================================================
/// VOLTAGE DROP CALCULATION SERVICE
///
/// PART 2 — CORRECTED GROUP MAPPING
///
/// Table 9.1 / 9.3 หัวตารางระบุ "Group 1, 2 and 5"
/// ไม่ใช่ "Group 1.25"
///
/// Mapping:
///   Group 1 / Group 2 / Group 5 -> *_Group1_2_5
///   Group 3 / 4 / 6 / 7 -> ใช้ arrangement ที่ระบุในตาราง
///
/// สูตรจากค่า mV/A/m:
///   VD(V) = mV/A/m × I × L / 1000
///   VD(%) = VD(V) / System Voltage × 100
/// ============================================================================
class VoltageDropCalculationService {
  const VoltageDropCalculationService();

  VoltageDropResult calculate({
    required VoltageDropRequest request,
    required List<VoltageDropTableEntry> rows,
  }) {
    if (request.currentA <= 0) {
      return VoltageDropResult.error('Current ต้องมากกว่า 0 A');
    }
    if (request.lengthM <= 0) {
      return VoltageDropResult.error('Length ต้องมากกว่า 0 m');
    }
    if (request.systemVoltage <= 0) {
      return VoltageDropResult.error('System Voltage ต้องมากกว่า 0 V');
    }
    if (request.allowableVoltageDropPercent <= 0) {
      return VoltageDropResult.error(
        'Allowable Voltage Drop ต้องมากกว่า 0 %',
      );
    }

    final entry = _findEntry(
      rows: rows,
      sizeSqmm: request.sizeSqmm,
    );

    if (entry == null) {
      return VoltageDropResult.error(
        'ไม่พบขนาดสาย ${request.sizeSqmm} sq.mm ใน Table',
      );
    }

    final mvPerAperM = _getTableValue(
      entry: entry,
      phase: request.phase,
      coreType: request.coreType,
      installationGroup: request.installationGroup,
      arrangement: request.arrangement,
    );

    if (mvPerAperM == null) {
      return VoltageDropResult.error(
        'ไม่พบค่า mV/A/m สำหรับ Group / Phase / Arrangement ที่เลือก',
      );
    }

    final voltageDropV =
        (mvPerAperM * request.currentA * request.lengthM) / 1000.0;

    final voltageDropPercent =
        (voltageDropV / request.systemVoltage) * 100.0;

    final isWithinLimit =
        voltageDropPercent <= request.allowableVoltageDropPercent;

    return VoltageDropResult.success(
      table: entry.table,
      temperatureC: entry.temperatureC,
      sizeSqmm: entry.sizeSqmm,
      mvPerAperM: mvPerAperM,
      currentA: request.currentA,
      lengthM: request.lengthM,
      systemVoltage: request.systemVoltage,
      voltageDropV: voltageDropV,
      voltageDropPercent: voltageDropPercent,
      isWithinLimit: isWithinLimit,
    );
  }

  VoltageDropTableEntry? _findEntry({
    required List<VoltageDropTableEntry> rows,
    required double sizeSqmm,
  }) {
    for (final row in rows) {
      if ((row.sizeSqmm - sizeSqmm).abs() < 0.000001) {
        return row;
      }
    }
    return null;
  }

  double? _getTableValue({
    required VoltageDropTableEntry entry,
    required VoltagePhase phase,
    required VoltageDropCoreType coreType,
    required VoltageDropInstallationGroup installationGroup,
    required CableArrangement? arrangement,
  }) {
    // Table 9.2 / 9.4: Multi Core ใช้ค่าเดียวทุกกลุ่ม
    if (coreType == VoltageDropCoreType.multiCore) {
      return phase == VoltagePhase.singlePhase
          ? entry.singlePhaseAll
          : entry.threePhaseAll;
    }

    // Table 9.1 / 9.3: Group 1, 2 และ 5 ใช้คอลัมน์เดียวกัน
    if (installationGroup.isGroup1_2_5) {
      return phase == VoltagePhase.singlePhase
          ? entry.singlePhaseGroup1_2_5
          : entry.threePhaseGroup1_2_5;
    }

    // Groups 3, 4, 6, 7 ต้องระบุรูปแบบการวางสายตามหัวตาราง
    if (arrangement == null) {
      return null;
    }

    if (phase == VoltagePhase.singlePhase) {
      switch (arrangement) {
        case CableArrangement.touching:
          return entry.singlePhaseTouching;
        case CableArrangement.spaced:
          return entry.singlePhaseSpaced;
        case CableArrangement.trefoil:
        case CableArrangement.flat:
          return null;
      }
    }

    switch (arrangement) {
      case CableArrangement.trefoil:
        return entry.threePhaseTrefoil;
      case CableArrangement.flat:
        return entry.threePhaseFlat;
      case CableArrangement.spaced:
        return entry.threePhaseSpaced;
      case CableArrangement.touching:
        return null;
    }
  }
}
