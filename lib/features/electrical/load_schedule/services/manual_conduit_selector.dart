import '../enums/cable_selection_status.dart';
import '../enums/circuit_phase_configuration.dart';
import '../enums/circuit_status.dart';
import '../enums/grounding_conductor_selection_status.dart';
import '../models/cable_coordination_result.dart';
import '../models/conduit_selection_result.dart';
import '../models/grounding_conductor_selection_result.dart';
import '../models/manual_conduit_selection_input.dart';

/// Deliberate manual entry point. Never invoked as an automatic fallback.
class ManualConduitSelector {
  const ManualConduitSelector();
  ConduitSelectionResult select({
    required CircuitStatus circuitStatus,
    required CircuitPhaseConfiguration phaseConfiguration,
    required CableCoordinationResult cable,
    required GroundingConductorSelectionResult ground,
    ManualConduitSelectionInput? input,
  }) {
    if (circuitStatus != CircuitStatus.active) {
      return ConduitSelectionResult.notCalculated(
        reason: 'SPARE/SPACE do not select conduit.',
      );
    }
    if (input == null ||
        cable.status != CableSelectionStatus.coordinated ||
        ground.status != GroundingConductorSelectionStatus.selected) {
      return ConduitSelectionResult.insufficient(
        reason: 'Explicit manual input and CP4/CP6 snapshots required.',
      );
    }
    if (input.phaseConfiguration != phaseConfiguration) {
      return ConduitSelectionResult.invalid(
        reason: 'Manual phase configuration differs from circuit.',
      );
    }
    final mismatch = input.snapshotIssue(cable, ground);
    if (mismatch != null) {
      return ConduitSelectionResult.invalid(reason: mismatch);
    }
    return ConduitSelectionResult.manualSelected(
      input: input,
      cable: cable,
      ground: ground,
    );
  }
}
