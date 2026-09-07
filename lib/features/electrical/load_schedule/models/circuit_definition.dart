import '../enums/circuit_status.dart';
import '../enums/phase_assignment.dart';
import '../enums/phase_assignment_mode.dart';
import 'load_input.dart';

class CircuitDefinition {
  CircuitDefinition({
    required this.circuitNo,
    required this.description,
    required this.status,
    required this.phaseAssignmentMode,
    this.loadInput,
    this.phaseAssignment,
    this.manualSpareCircuitBreaker,
  }) {
    if (circuitNo <= 0) {
      throw ArgumentError.value(circuitNo, 'circuitNo', 'Must be positive.');
    }
    if (status == CircuitStatus.active && loadInput == null) {
      throw ArgumentError('ACTIVE circuits require a LoadInput.');
    }
    if (status != CircuitStatus.active && loadInput != null) {
      throw ArgumentError('SPARE and SPACE circuits cannot contain a load.');
    }
    if (status == CircuitStatus.space && manualSpareCircuitBreaker != null) {
      throw ArgumentError('SPACE circuits cannot contain equipment data.');
    }
    if (status != CircuitStatus.spare && manualSpareCircuitBreaker != null) {
      throw ArgumentError(
        'Reserved circuit-breaker metadata is allowed only for SPARE circuits.',
      );
    }
    if (phaseAssignmentMode == PhaseAssignmentMode.manual &&
        phaseAssignment == null) {
      throw ArgumentError('Manual phase assignment requires R, S, T, or RST.');
    }
    if (phaseAssignmentMode == PhaseAssignmentMode.automatic &&
        phaseAssignment != null) {
      throw ArgumentError(
        'Automatic phase assignment cannot contain a manual phase.',
      );
    }
  }

  final int circuitNo;
  final String description;
  final CircuitStatus status;
  final LoadInput? loadInput;
  final PhaseAssignmentMode phaseAssignmentMode;
  final PhaseAssignment? phaseAssignment;

  /// Manual metadata only. CP1 does not size or validate circuit breakers.
  final String? manualSpareCircuitBreaker;

  Map<String, Object?> toJson() => {
    'circuitNo': circuitNo,
    'description': description,
    'status': status.name,
    'phaseAssignmentMode': phaseAssignmentMode.name,
    if (loadInput != null) 'loadInput': loadInput!.toJson(),
    if (phaseAssignment != null) 'phaseAssignment': phaseAssignment!.name,
    if (manualSpareCircuitBreaker != null)
      'manualSpareCircuitBreaker': manualSpareCircuitBreaker,
  };

  factory CircuitDefinition.fromJson(Map<String, Object?> json) =>
      CircuitDefinition(
        circuitNo: json['circuitNo'] as int,
        description: json['description'] as String,
        status: CircuitStatus.values.byName(json['status'] as String),
        loadInput: json['loadInput'] == null
            ? null
            : LoadInput.fromJson(
                Map<String, Object?>.from(json['loadInput'] as Map),
              ),
        phaseAssignmentMode: PhaseAssignmentMode.values.byName(
          json['phaseAssignmentMode'] as String,
        ),
        phaseAssignment: json['phaseAssignment'] == null
            ? null
            : PhaseAssignment.values.byName(json['phaseAssignment'] as String),
        manualSpareCircuitBreaker: json['manualSpareCircuitBreaker'] as String?,
      );
}
