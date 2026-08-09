import '../../cable_design/models/cable_design_request.dart';
import '../enums/cable_arrangement.dart';
import '../enums/cable_insulation.dart';
import '../enums/voltage_phase.dart';
import '../enums/voltage_drop_installation_group.dart';

/// ============================================================================
/// VOLTAGE DROP CABLE SELECTION REQUEST
///
/// PART 3
///
/// รวมข้อมูลที่จำเป็นสำหรับการเลือกสายโดยพิจารณา
///
/// 1. Ampacity + Grouping Factor
/// 2. ระยะทางจริง
/// 3. Voltage Drop จาก Table 9.1 - 9.4
///
/// ไม่มีการคำนวณ R / X และไม่มีการ interpolate ตาราง
/// ============================================================================
class VoltageDropCableSelectionRequest {
  const VoltageDropCableSelectionRequest({
    required this.cableRequest,
    required this.insulation,
    required this.phase,
    required this.lengthM,
    required this.systemVoltage,
    required this.allowableVoltageDropPercent,
    required this.installationGroup,
    this.arrangement,
  });

  final CableDesignRequest cableRequest;
  final CableInsulation insulation;
  final VoltagePhase phase;
  final double lengthM;
  final double systemVoltage;
  final double allowableVoltageDropPercent;

  /// กลุ่มการติดตั้งสำหรับ Table 9.1 / 9.3
  final VoltageDropInstallationGroup installationGroup;

  /// ใช้กับ Single Core เท่านั้น
  /// Multi Core ให้เป็น null
  final CableArrangement? arrangement;
}
