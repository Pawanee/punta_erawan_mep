import 'circuit_definition.dart';

class PanelDefinition {
  PanelDefinition({
    required this.panelId,
    required this.panelNo,
    required List<CircuitDefinition> circuits,
    this.projectName,
    this.location,
    this.systemVoltageV,
    this.frequencyHz,
    this.enclosure,
    this.mounting,
    this.door,
    this.circuitCapacity,
    this.mainCircuitBreaker,
    this.feeder,
    this.demandFactor,
  }) : circuits = List.unmodifiable(circuits) {
    if (panelId.trim().isEmpty || panelNo.trim().isEmpty) {
      throw ArgumentError('panelId and panelNo are required.');
    }
    if (systemVoltageV != null && systemVoltageV! <= 0) {
      throw ArgumentError.value(systemVoltageV, 'systemVoltageV');
    }
    if (frequencyHz != null && frequencyHz! <= 0) {
      throw ArgumentError.value(frequencyHz, 'frequencyHz');
    }
    if (circuitCapacity != null && circuitCapacity! <= 0) {
      throw ArgumentError.value(circuitCapacity, 'circuitCapacity');
    }
    if (demandFactor != null && (demandFactor! <= 0 || demandFactor! > 1)) {
      throw ArgumentError.value(demandFactor, 'demandFactor');
    }
    final numbers = circuits.map((circuit) => circuit.circuitNo).toSet();
    if (numbers.length != circuits.length) {
      throw ArgumentError('Circuit numbers must be unique within a panel.');
    }
  }

  final String panelId;
  final String panelNo;
  final String? projectName;
  final String? location;
  final double? systemVoltageV;
  final double? frequencyHz;
  final String? enclosure;
  final String? mounting;
  final String? door;
  final int? circuitCapacity;

  /// Manual metadata only. No sizing is performed in CP1.
  final String? mainCircuitBreaker;
  final String? feeder;
  final double? demandFactor;
  final List<CircuitDefinition> circuits;

  Map<String, Object?> toJson() => {
    'panelId': panelId,
    'panelNo': panelNo,
    if (projectName != null) 'projectName': projectName,
    if (location != null) 'location': location,
    if (systemVoltageV != null) 'systemVoltageV': systemVoltageV,
    if (frequencyHz != null) 'frequencyHz': frequencyHz,
    if (enclosure != null) 'enclosure': enclosure,
    if (mounting != null) 'mounting': mounting,
    if (door != null) 'door': door,
    if (circuitCapacity != null) 'circuitCapacity': circuitCapacity,
    if (mainCircuitBreaker != null) 'mainCircuitBreaker': mainCircuitBreaker,
    if (feeder != null) 'feeder': feeder,
    if (demandFactor != null) 'demandFactor': demandFactor,
    'circuits': circuits.map((circuit) => circuit.toJson()).toList(),
  };

  factory PanelDefinition.fromJson(Map<String, Object?> json) =>
      PanelDefinition(
        panelId: json['panelId'] as String,
        panelNo: json['panelNo'] as String,
        projectName: json['projectName'] as String?,
        location: json['location'] as String?,
        systemVoltageV: (json['systemVoltageV'] as num?)?.toDouble(),
        frequencyHz: (json['frequencyHz'] as num?)?.toDouble(),
        enclosure: json['enclosure'] as String?,
        mounting: json['mounting'] as String?,
        door: json['door'] as String?,
        circuitCapacity: json['circuitCapacity'] as int?,
        mainCircuitBreaker: json['mainCircuitBreaker'] as String?,
        feeder: json['feeder'] as String?,
        demandFactor: (json['demandFactor'] as num?)?.toDouble(),
        circuits: (json['circuits'] as List)
            .map(
              (item) => CircuitDefinition.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
      );
}
