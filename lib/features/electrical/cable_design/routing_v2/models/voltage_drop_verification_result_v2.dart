import '../enums/voltage_drop_verification_status_v2.dart';

class VoltageDropVerificationResultV2 {
  const VoltageDropVerificationResultV2({
    required this.status,
    required this.reason,
    this.tableId,
    this.mvPerAperM,
    this.voltageDropV,
    this.voltageDropPercent,
    this.allowableVoltageDropPercent,
    this.marginPercent,
    this.sourceReferences = const [],
  });
  final VoltageDropVerificationStatusV2 status;
  final String? reason;
  final String? tableId;
  final double? mvPerAperM;
  final double? voltageDropV;
  final double? voltageDropPercent;
  final double? allowableVoltageDropPercent;
  final double? marginPercent;
  final List<String> sourceReferences;
}
