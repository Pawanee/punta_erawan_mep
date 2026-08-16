import '../../cable_design/enums/cable_type.dart';
import '../../cable_design/enums/conductor_temperature_class.dart';
import '../../cable_design/enums/core_type.dart';
import '../../cable_design/enums/installation_method.dart';

/// ============================================================================
/// VOLTAGE DROP CABLE SELECTION RESULT
///
/// PART 3 / PART 6 / PART 9.4
///
/// ผลการเลือกสายจาก
/// - Ampacity
/// - Grouping Factor
/// - Voltage Drop
///
/// Reference Traceability
/// - Ampacity Reference
/// - Voltage Drop Reference
/// ============================================================================

class VoltageDropCableSelectionResult {
  const VoltageDropCableSelectionResult({
    required this.isSuccess,
    required this.message,
    this.cableSizeSqmm,
    this.ampacity,
    this.cableArrangement,

    // Legacy reference
    this.reference,

    // PART 9.4
    this.ampacityReference,
    this.voltageDropReference,

    this.groupingFactor,
    this.temperatureFactor,
    this.baseAmpacityPerRun,
    this.correctedAmpacityPerRun,
    this.sourceTableId,
    this.sourceTableDisplayName,
    this.installationMethod,
    this.loadedConductors,
    this.coreType,
    this.cableType,
    this.conductorTemperatureClass,
    this.ambientTemperatureC,
    this.groupingCircuits,
    this.groupingReference,
    this.temperatureReference,
    this.requiredCurrent,
    this.voltageDropV,
    this.voltageDropPercent,
    this.mvPerAperM,
    this.runs,
  });

  final bool isSuccess;
  final String message;

  /// ขนาดสาย
  final double? cableSizeSqmm;

  /// Ampacity ของสาย 1 Run
  final double? ampacity;

  /// รูปแบบสาย เช่น 1 x 95 sq.mm
  final String? cableArrangement;

  /// Legacy reference
  final String? reference;

  /// Reference สำหรับ Ampacity / Table 5-20
  final String? ampacityReference;

  /// Reference สำหรับ Voltage Drop / Table 9.1 - 9.4
  final String? voltageDropReference;

  /// Grouping Factor
  final double? groupingFactor;

  /// Table 5-43 ambient-temperature correction factor.
  final double? temperatureFactor;

  /// Published ampacity from Table 5-20 or Table 5-27 for one run.
  final double? baseAmpacityPerRun;

  /// Base ampacity after grouping and temperature corrections for one run.
  final double? correctedAmpacityPerRun;
  final String? sourceTableId;
  final String? sourceTableDisplayName;
  final InstallationMethod? installationMethod;
  final int? loadedConductors;
  final CoreType? coreType;

  /// Alias for the published ampacity of the selected candidate.
  double? get baseAmpacity => baseAmpacityPerRun ?? ampacity;

  final CableType? cableType;
  final ConductorTemperatureClass? conductorTemperatureClass;
  final double? ambientTemperatureC;
  final int? groupingCircuits;
  final String? groupingReference;
  final String? temperatureReference;

  /// Required Current
  final double? requiredCurrent;

  /// Voltage Drop
  final double? voltageDropV;

  /// Voltage Drop %
  final double? voltageDropPercent;

  /// mV/A/m
  final double? mvPerAperM;

  /// จำนวน Parallel Runs
  final int? runs;

  factory VoltageDropCableSelectionResult.success({
    required double cableSizeSqmm,
    required double ampacity,
    required String cableArrangement,

    // Legacy compatibility
    String? reference,

    // PART 9.4
    String? ampacityReference,
    String? voltageDropReference,

    required double groupingFactor,
    double? temperatureFactor,
    double? baseAmpacityPerRun,
    double? correctedAmpacityPerRun,
    String? sourceTableId,
    String? sourceTableDisplayName,
    InstallationMethod? installationMethod,
    int? loadedConductors,
    CoreType? coreType,
    CableType? cableType,
    ConductorTemperatureClass? conductorTemperatureClass,
    double? ambientTemperatureC,
    int? groupingCircuits,
    String? groupingReference,
    String? temperatureReference,
    required double requiredCurrent,
    required double voltageDropV,
    required double voltageDropPercent,
    required double mvPerAperM,
    required int runs,
  }) {
    return VoltageDropCableSelectionResult(
      isSuccess: true,
      message: 'Cable selected successfully with voltage drop check.',
      cableSizeSqmm: cableSizeSqmm,
      ampacity: ampacity,
      cableArrangement: cableArrangement,

      // Legacy compatibility
      reference: reference ??
          ampacityReference ??
          voltageDropReference,

      // PART 9.4
      ampacityReference: ampacityReference,
      voltageDropReference: voltageDropReference,

      groupingFactor: groupingFactor,
      temperatureFactor: temperatureFactor,
      baseAmpacityPerRun: baseAmpacityPerRun,
      correctedAmpacityPerRun: correctedAmpacityPerRun,
      sourceTableId: sourceTableId,
      sourceTableDisplayName: sourceTableDisplayName,
      installationMethod: installationMethod,
      loadedConductors: loadedConductors,
      coreType: coreType,
      cableType: cableType,
      conductorTemperatureClass: conductorTemperatureClass,
      ambientTemperatureC: ambientTemperatureC,
      groupingCircuits: groupingCircuits,
      groupingReference: groupingReference,
      temperatureReference: temperatureReference,
      requiredCurrent: requiredCurrent,
      voltageDropV: voltageDropV,
      voltageDropPercent: voltageDropPercent,
      mvPerAperM: mvPerAperM,
      runs: runs,
    );
  }

  factory VoltageDropCableSelectionResult.error(String message) {
    return VoltageDropCableSelectionResult(
      isSuccess: false,
      message: message,
    );
  }
}
