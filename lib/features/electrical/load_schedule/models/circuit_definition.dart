import '../enums/circuit_status.dart';
import '../enums/circuit_phase_configuration.dart';
import '../enums/phase_assignment.dart';
import '../enums/phase_assignment_mode.dart';
import 'load_input.dart';

class CircuitDefinition {
  CircuitDefinition({
    required this.circuitNo,
    required this.description,
    required this.status,
    required this.phaseConfiguration,
    required this.phaseAssignmentMode,
    this.loadInput,
    this.phaseAssignment,
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
    _validatePhaseAssignment();
  }

  final int circuitNo;
  final String description;
  final CircuitStatus status;
  final CircuitPhaseConfiguration phaseConfiguration;
  final LoadInput? loadInput;
  final PhaseAssignmentMode phaseAssignmentMode;
  final PhaseAssignment? phaseAssignment;

  void _validatePhaseAssignment() {
    if (phaseConfiguration == CircuitPhaseConfiguration.threePhase) {
      if (phaseAssignment != PhaseAssignment.rst) {
        throw ArgumentError('Three-phase circuits require RST assignment.');
      }
      return;
    }
    if (phaseAssignment == PhaseAssignment.rst) {
      throw ArgumentError('Single-phase circuits can use only R, S, or T.');
    }
    if (phaseAssignmentMode == PhaseAssignmentMode.manual &&
        phaseAssignment == null) {
      throw ArgumentError(
        'Manual single-phase assignment requires R, S, or T.',
      );
    }
    if (phaseAssignmentMode == PhaseAssignmentMode.automatic &&
        phaseAssignment != null) {
      throw ArgumentError(
        'Automatic single-phase assignment must not have an assigned phase.',
      );
    }
  }

  Map<String, Object?> toJson() => {
    'circuitNo': circuitNo,
    'description': description,
    'status': status.name,
    'phaseConfiguration': phaseConfiguration.name,
    'phaseAssignmentMode': phaseAssignmentMode.name,
    if (loadInput != null) 'loadInput': loadInput!.toJson(),
    if (phaseAssignment != null) 'phaseAssignment': phaseAssignment!.name,
  };

  factory CircuitDefinition.fromJson(Map<String, Object?> json) =>
      CircuitDefinition(
        circuitNo: json['circuitNo'] as int,
        description: json['description'] as String,
        status: CircuitStatus.values.byName(json['status'] as String),
        phaseConfiguration: CircuitPhaseConfiguration.values.byName(
          json['phaseConfiguration'] as String,
        ),
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
      );
}
