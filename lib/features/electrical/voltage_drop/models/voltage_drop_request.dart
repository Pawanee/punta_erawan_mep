import '../enums/cable_arrangement.dart';
import '../enums/cable_insulation.dart';
import '../enums/voltage_drop_core_type.dart';
import '../enums/voltage_phase.dart';
import '../enums/voltage_drop_installation_group.dart';

/// ============================================================================
/// VOLTAGE DROP REQUEST
///
/// PART 2 (REVISED)
///
/// ใช้ค่าจาก Table 9.1 - 9.4 เป็นฐานในการคำนวณ Voltage Drop
///
/// สูตรที่ใช้กับค่าตาราง mV/A/m:
/// Voltage Drop (V) = (mV/A/m × I × L) / 1000
/// Voltage Drop (%) = Voltage Drop (V) / System Voltage × 100
///
/// ไม่มีการคำนวณ R / X / power factor แยกต่างหาก
/// ============================================================================

class VoltageDropRequest {
  const VoltageDropRequest({
    required this.insulation,
    required this.coreType,
    required this.phase,
    required this.sizeSqmm,
    required this.currentA,
    required this.lengthM,
    required this.systemVoltage,
    required this.allowableVoltageDropPercent,
    required this.installationGroup,
    this.arrangement,
  });

  final CableInsulation insulation;
  final VoltageDropCoreType coreType;
  final VoltagePhase phase;

  /// ขนาดสายที่ต้องการตรวจสอบ
  final double sizeSqmm;

  /// กระแสใช้งานจริง (A)
  final double currentA;

  /// ระยะทางเดินสายจริง (m)
  final double lengthM;

  /// แรงดันระบบ เช่น 230 V / 400 V
  final double systemVoltage;

  /// ค่า Voltage Drop สูงสุดที่ยอมให้ (%)
  final double allowableVoltageDropPercent;

  /// กลุ่มการติดตั้งจริงสำหรับ Table 9.1 / 9.3
  /// Group 1, 2 และ 5 ใช้คอลัมน์เดียวกันในตาราง
  final VoltageDropInstallationGroup installationGroup;

  /// ใช้เมื่อเป็น Group 3, 4, 6 หรือ 7 ของ Single Core
  final CableArrangement? arrangement;
}
