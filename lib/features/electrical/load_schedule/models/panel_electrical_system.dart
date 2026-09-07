import '../enums/panel_phase_system.dart';

class PanelElectricalSystem {
  PanelElectricalSystem({
    required this.phaseSystem,
    required this.lineToNeutralVoltageV,
    required this.lineToLineVoltageV,
    required this.frequencyHz,
  }) {
    if (lineToNeutralVoltageV <= 0) {
      throw ArgumentError.value(
        lineToNeutralVoltageV,
        'lineToNeutralVoltageV',
        'Must be positive.',
      );
    }
    if (lineToLineVoltageV <= 0) {
      throw ArgumentError.value(
        lineToLineVoltageV,
        'lineToLineVoltageV',
        'Must be positive.',
      );
    }
    if (frequencyHz <= 0) {
      throw ArgumentError.value(
        frequencyHz,
        'frequencyHz',
        'Must be positive.',
      );
    }
  }

  final PanelPhaseSystem phaseSystem;
  final double lineToNeutralVoltageV;
  final double lineToLineVoltageV;
  final double frequencyHz;

  Map<String, Object?> toJson() => {
    'phaseSystem': phaseSystem.name,
    'lineToNeutralVoltageV': lineToNeutralVoltageV,
    'lineToLineVoltageV': lineToLineVoltageV,
    'frequencyHz': frequencyHz,
  };

  factory PanelElectricalSystem.fromJson(
    Map<String, Object?> json,
  ) => PanelElectricalSystem(
    phaseSystem: PanelPhaseSystem.values.byName(json['phaseSystem'] as String),
    lineToNeutralVoltageV: (json['lineToNeutralVoltageV'] as num).toDouble(),
    lineToLineVoltageV: (json['lineToLineVoltageV'] as num).toDouble(),
    frequencyHz: (json['frequencyHz'] as num).toDouble(),
  );
}
