import '../enums/cable_selection_status.dart';
import '../enums/circuit_status.dart';
import '../enums/grounding_conductor_selection_status.dart';
import '../models/cable_coordination_result.dart';
import '../models/conduit_selection_input.dart';
import '../models/conduit_selection_result.dart';
import '../models/grounding_conductor_selection_result.dart';
import '../repositories/table_c1_repository.dart';

class ConduitSelector {
  const ConduitSelector();
  ConduitSelectionResult select({
    required CircuitStatus circuitStatus,
    required CableCoordinationResult cable,
    required GroundingConductorSelectionResult ground,
    ConduitSelectionInput? input,
  }) {
    if (circuitStatus != CircuitStatus.active) {
      return ConduitSelectionResult.notCalculated(
        reason: 'SPARE/SPACE do not select conduit.',
      );
    }
    if (input == null) {
      return ConduitSelectionResult.insufficient(
        reason: 'Explicit physical conductor list required.',
      );
    }
    final unsupported = input.unsupportedReason;
    if (unsupported != null) {
      return ConduitSelectionResult.unsupported(reason: unsupported);
    }
    for (final conduit in input.conduits) {
      if (const TableC1Repository().select(
            conduit.conductors.first.sizeSqmm,
            conduit.conductors.length,
          ) ==
          null) {
        return ConduitSelectionResult.unsupported(
          reason: 'No exact C1 row/published capacity.',
        );
      }
    }
    if (cable.status != CableSelectionStatus.coordinated ||
        ground.status != GroundingConductorSelectionStatus.selected) {
      return ConduitSelectionResult.insufficient(
        reason: 'CP4/CP6 results required.',
      );
    }
    final mismatch = ConduitSelectionResult.snapshotIssue(input, cable, ground);
    if (mismatch != null) {
      return ConduitSelectionResult.invalid(reason: mismatch);
    }
    return ConduitSelectionResult.selected(
      input: input,
      cable: cable,
      ground: ground,
    );
  }
}
