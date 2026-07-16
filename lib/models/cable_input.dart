class CableInput {
  final double loadCurrent;

  final String voltage;

  final String phase;

  final String cableType;

  final String installationMethod;

  final String ambientTemperature;

  final String grouping;

  final double voltageDrop;

  const CableInput({
    required this.loadCurrent,
    required this.voltage,
    required this.phase,
    required this.cableType,
    required this.installationMethod,
    required this.ambientTemperature,
    required this.grouping,
    required this.voltageDrop,
  });
}