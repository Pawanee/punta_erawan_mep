 import '../enums/cable_type.dart';
import '../enums/core_type.dart';
import '../enums/installation_method.dart';
import '../enums/phase_system.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Cable Design Request
///
/// เก็บข้อมูลที่ผู้ใช้กรอกจากหน้าจอ Cable Design
///
/// ไฟล์นี้เป็น Input Model ของ Cable Design Engine
/// ============================================================================

class CableDesignRequest {
  /// กระแสโหลด (Ampere)
  final double loadCurrent;

  /// ระบบไฟฟ้า
  ///
  /// เช่น
  /// - singlePhase
  /// - threePhase
  final PhaseSystem phaseSystem;

  /// ชนิดสาย
  final CableType cableType;

  /// วิธีติดตั้ง
  final InstallationMethod installationMethod;

  /// จำนวนตัวนำที่มีกระแสไหล
  final int loadedConductors;

  /// ลักษณะสาย
  final CoreType coreType;

  /// อุณหภูมิแวดล้อม (°C)
  final double ambientTemperature;

  /// จำนวนวงจรที่เดินรวมกัน
  final int groupingCircuits;

  /// ค่าแรงดันตกที่ยอมรับได้ (%)
  final double allowableVoltageDrop;

  const CableDesignRequest({
    required this.loadCurrent,
    required this.phaseSystem,
    required this.cableType,
    required this.installationMethod,
    required this.loadedConductors,
    required this.coreType,
    this.ambientTemperature = 30.0,
    this.groupingCircuits = 1,
    this.allowableVoltageDrop = 3.0,
  });

  CableDesignRequest copyWith({
    double? loadCurrent,
    PhaseSystem? phaseSystem,
    CableType? cableType,
    InstallationMethod? installationMethod,
    int? loadedConductors,
    CoreType? coreType,
    double? ambientTemperature,
    int? groupingCircuits,
    double? allowableVoltageDrop,
  }) {
    return CableDesignRequest(
      loadCurrent: loadCurrent ?? this.loadCurrent,
      phaseSystem: phaseSystem ?? this.phaseSystem,
      cableType: cableType ?? this.cableType,
      installationMethod:
          installationMethod ?? this.installationMethod,
      loadedConductors:
          loadedConductors ?? this.loadedConductors,
      coreType: coreType ?? this.coreType,
      ambientTemperature:
          ambientTemperature ?? this.ambientTemperature,
      groupingCircuits:
          groupingCircuits ?? this.groupingCircuits,
      allowableVoltageDrop:
          allowableVoltageDrop ?? this.allowableVoltageDrop,
    );
  }

  @override
  String toString() {
    return '''
CableDesignRequest(
  loadCurrent: $loadCurrent,
  phaseSystem: $phaseSystem,
  cableType: $cableType,
  installationMethod: $installationMethod,
  loadedConductors: $loadedConductors,
  coreType: $coreType,
  ambientTemperature: $ambientTemperature,
  groupingCircuits: $groupingCircuits,
  allowableVoltageDrop: $allowableVoltageDrop
)
''';
  }
}