/// ============================================================================
/// VOLTAGE DROP RESULT
///
/// ผลการคำนวณจากค่าที่อ่านได้จาก Table 9.1 - 9.4
/// ============================================================================

class VoltageDropResult {
  const VoltageDropResult({
    required this.isSuccess,
    required this.message,
    this.table,
    this.temperatureC,
    this.sizeSqmm,
    this.mvPerAperM,
    this.currentA,
    this.lengthM,
    this.systemVoltage,
    this.voltageDropV,
    this.voltageDropPercent,
    this.isWithinLimit,
  });

  final bool isSuccess;
  final String message;

  final String? table;
  final int? temperatureC;
  final double? sizeSqmm;
  final double? mvPerAperM;

  final double? currentA;
  final double? lengthM;
  final double? systemVoltage;

  final double? voltageDropV;
  final double? voltageDropPercent;

  final bool? isWithinLimit;

  factory VoltageDropResult.success({
    required String table,
    required int temperatureC,
    required double sizeSqmm,
    required double mvPerAperM,
    required double currentA,
    required double lengthM,
    required double systemVoltage,
    required double voltageDropV,
    required double voltageDropPercent,
    required bool isWithinLimit,
  }) {
    return VoltageDropResult(
      isSuccess: true,
      message: 'Voltage drop calculated successfully.',
      table: table,
      temperatureC: temperatureC,
      sizeSqmm: sizeSqmm,
      mvPerAperM: mvPerAperM,
      currentA: currentA,
      lengthM: lengthM,
      systemVoltage: systemVoltage,
      voltageDropV: voltageDropV,
      voltageDropPercent: voltageDropPercent,
      isWithinLimit: isWithinLimit,
    );
  }

  factory VoltageDropResult.error(String message) {
    return VoltageDropResult(
      isSuccess: false,
      message: message,
    );
  }
}
