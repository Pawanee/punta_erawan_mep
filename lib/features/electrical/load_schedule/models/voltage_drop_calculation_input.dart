import '../../voltage_drop/enums/cable_arrangement.dart';
import '../../voltage_drop/enums/voltage_drop_installation_group.dart';

class VoltageDropCalculationInput {
  VoltageDropCalculationInput({
    required this.lengthOneWayM,
    required this.allowableVoltageDropPercent,
    required this.installationGroup,
    this.arrangement,
  }) {
    if (!lengthOneWayM.isFinite || lengthOneWayM <= 0) {
      throw ArgumentError.value(lengthOneWayM, 'lengthOneWayM');
    }
    if (!allowableVoltageDropPercent.isFinite ||
        allowableVoltageDropPercent <= 0 ||
        allowableVoltageDropPercent > 100) {
      throw ArgumentError.value(
        allowableVoltageDropPercent,
        'allowableVoltageDropPercent',
      );
    }
  }

  final double lengthOneWayM;
  final double allowableVoltageDropPercent;
  final VoltageDropInstallationGroup installationGroup;
  final CableArrangement? arrangement;

  Map<String, Object?> toJson() => {
    'lengthOneWayM': lengthOneWayM,
    'allowableVoltageDropPercent': allowableVoltageDropPercent,
    'installationGroup': installationGroup.name,
    if (arrangement != null) 'arrangement': arrangement!.name,
  };

  factory VoltageDropCalculationInput.fromJson(Map<String, Object?> json) =>
      VoltageDropCalculationInput(
        lengthOneWayM: (json['lengthOneWayM'] as num).toDouble(),
        allowableVoltageDropPercent:
            (json['allowableVoltageDropPercent'] as num).toDouble(),
        installationGroup: VoltageDropInstallationGroup.values.byName(
          json['installationGroup'] as String,
        ),
        arrangement: json['arrangement'] == null
            ? null
            : CableArrangement.values.byName(json['arrangement'] as String),
      );
}
