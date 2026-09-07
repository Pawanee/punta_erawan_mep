import '../enums/circuit_phase_configuration.dart';
import '../enums/panel_phase_system.dart';
import 'circuit_definition.dart';
import 'panel_electrical_system.dart';

class PanelDefinition {
  PanelDefinition({
    required this.panelId,
    required this.panelNo,
    required this.electricalSystem,
    required List<CircuitDefinition> circuits,
    this.projectName,
    this.location,
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
    if (electricalSystem.phaseSystem == PanelPhaseSystem.singlePhase &&
        circuits.any(
          (circuit) =>
              circuit.phaseConfiguration ==
              CircuitPhaseConfiguration.threePhase,
        )) {
      throw ArgumentError(
        'A single-phase panel cannot contain a three-phase circuit.',
      );
    }
  }

  final String panelId;
  final String panelNo;
  final PanelElectricalSystem electricalSystem;
  final String? projectName;
  final String? location;
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
    'electricalSystem': electricalSystem.toJson(),
    if (projectName != null) 'projectName': projectName,
    if (location != null) 'location': location,
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
        electricalSystem: PanelElectricalSystem.fromJson(
          Map<String, Object?>.from(json['electricalSystem'] as Map),
        ),
        projectName: json['projectName'] as String?,
        location: json['location'] as String?,
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
