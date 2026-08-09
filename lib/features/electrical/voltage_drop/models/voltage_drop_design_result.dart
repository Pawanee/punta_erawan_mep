 /// ============================================================================
/// VOLTAGE DROP DESIGN RESULT
///
/// PART 9.4 - Reference Traceability
///
/// Final Result สำหรับ UI
///
/// Reference แยกเป็น
/// - Ampacity Reference
/// - Voltage Drop Reference
///
/// Legacy reference ยังคงไว้เพื่อ compatibility กับ test / code เดิม
/// ============================================================================

class VoltageDropDesignResult {
  const VoltageDropDesignResult({
    required this.isSuccess,
    required this.message,
    this.loadCurrent,
    this.groupingFactor,
    this.requiredCurrent,
    this.runs,
    this.currentPerRun,
    this.cableSizeSqmm,
    this.ampacityPerRun,
    this.totalAmpacity,
    this.cableArrangement,
    this.cableLengthM,
    this.voltageDropV,
    this.voltageDropPercent,
    this.mvPerAperM,
    this.ampacityReference,
    this.voltageDropReference,
    this.reference,
  });

  final bool isSuccess;
  final String message;

  final double? loadCurrent;
  final double? groupingFactor;
  final double? requiredCurrent;

  final int? runs;
  final double? currentPerRun;
  final double? cableSizeSqmm;
  final double? ampacityPerRun;
  final double? totalAmpacity;
  final String? cableArrangement;

  final double? cableLengthM;
  final double? voltageDropV;
  final double? voltageDropPercent;
  final double? mvPerAperM;

  /// Reference สำหรับ Ampacity / Table 5-20
  final String? ampacityReference;

  /// Reference สำหรับ Voltage Drop / Table 9.1 - 9.4
  final String? voltageDropReference;

  /// Legacy field สำหรับ compatibility
  final String? reference;

  factory VoltageDropDesignResult.success({
    required double loadCurrent,
    required double groupingFactor,
    required double requiredCurrent,
    required int runs,
    required double currentPerRun,
    required double cableSizeSqmm,
    required double ampacityPerRun,
    required double totalAmpacity,
    required String cableArrangement,
    required double cableLengthM,
    required double voltageDropV,
    required double voltageDropPercent,
    required double mvPerAperM,
    String? ampacityReference,
    String? voltageDropReference,
    String? reference,
  }) {
    return VoltageDropDesignResult(
      isSuccess: true,
      message:
          'Cable selected successfully with ampacity and voltage drop checks.',
      loadCurrent: loadCurrent,
      groupingFactor: groupingFactor,
      requiredCurrent: requiredCurrent,
      runs: runs,
      currentPerRun: currentPerRun,
      cableSizeSqmm: cableSizeSqmm,
      ampacityPerRun: ampacityPerRun,
      totalAmpacity: totalAmpacity,
      cableArrangement: cableArrangement,
      cableLengthM: cableLengthM,
      voltageDropV: voltageDropV,
      voltageDropPercent: voltageDropPercent,
      mvPerAperM: mvPerAperM,
      ampacityReference: ampacityReference,
      voltageDropReference: voltageDropReference,

      // Legacy compatibility
      reference: reference ??
          ampacityReference ??
          voltageDropReference,
    );
  }

  factory VoltageDropDesignResult.error(String message) {
    return VoltageDropDesignResult(
      isSuccess: false,
      message: message,
    );
  }
}