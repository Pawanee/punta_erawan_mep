import '../enums/cable_selection_status.dart';
import '../enums/grounding_conductor_selection_status.dart';
import '../repositories/table_c1_repository.dart';
import 'cable_coordination_result.dart';
import 'conduit_selection_input.dart';
import 'grounding_conductor_selection_result.dart';
import 'manual_conduit_selection_input.dart';

enum ConduitSelectionStatus {
  notCalculated,
  selected,
  manualSelected,
  insufficient,
  invalid,
  unsupported,
}

enum ConduitSelectionMethod { automaticTableC1, manualEngineeringSelection }

bool conduitJsonEqual(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.keys.every(
          (key) =>
              right.containsKey(key) && conduitJsonEqual(left[key], right[key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        List.generate(
          left.length,
          (i) => conduitJsonEqual(left[i], right[i]),
        ).every((same) => same);
  }
  return left == right;
}

class ConduitRunSelection {
  ConduitRunSelection._(this.conduitId, this.run, this.selection);
  final String conduitId;
  final int run;
  final TableC1Selection selection;
  int get nominalSizeMm => selection.column.nominalMm;
  int get requestedCount => selection.requestedCount;
  int get publishedCapacity => selection.capacity;
  Map<String, Object?> toJson() => {
    'conduitId': conduitId,
    'run': run,
    'tableId': TableC1Repository.tableId,
    'tableVersion': TableC1Repository.version,
    'conductorRow': selection.row.id,
    'conductorSizeSqmm': selection.row.conductorSizeSqmm,
    'requestedCount': requestedCount,
    'publishedCapacity': publishedCapacity,
    'conduitColumn': selection.column.id,
    'nominalSizeMm': nominalSizeMm,
    'nominalSizeInch': selection.column.inchLabel,
  };
}

class ConduitSelectionResult {
  ConduitSelectionResult._(
    this.status,
    this.reason,
    this.input,
    this.cableSnapshot,
    this.groundSnapshot,
    List<ConduitRunSelection> selections, {
    this.manualInput,
  }) : selections = List.unmodifiable(selections) {
    if (status != ConduitSelectionStatus.selected &&
        status != ConduitSelectionStatus.manualSelected &&
        status != ConduitSelectionStatus.notCalculated &&
        (reason == null || reason!.trim().isEmpty)) {
      throw ArgumentError('Unresolved conduit selection requires a reason.');
    }
  }
  factory ConduitSelectionResult.notCalculated({String? reason}) =>
      ConduitSelectionResult._(
        ConduitSelectionStatus.notCalculated,
        reason,
        null,
        null,
        null,
        [],
      );
  factory ConduitSelectionResult.insufficient({required String reason}) =>
      ConduitSelectionResult._(
        ConduitSelectionStatus.insufficient,
        reason,
        null,
        null,
        null,
        [],
      );
  factory ConduitSelectionResult.invalid({required String reason}) =>
      ConduitSelectionResult._(
        ConduitSelectionStatus.invalid,
        reason,
        null,
        null,
        null,
        [],
      );
  factory ConduitSelectionResult.unsupported({required String reason}) =>
      ConduitSelectionResult._(
        ConduitSelectionStatus.unsupported,
        reason,
        null,
        null,
        null,
        [],
      );

  /// Explicit engineering action only; automatic selection never calls this.
  factory ConduitSelectionResult.manualSelected({
    required ManualConduitSelectionInput input,
    required CableCoordinationResult cable,
    required GroundingConductorSelectionResult ground,
  }) {
    final mismatch = input.snapshotIssue(cable, ground);
    if (mismatch != null) throw ArgumentError(mismatch);
    return ConduitSelectionResult._(
      ConduitSelectionStatus.manualSelected,
      null,
      null,
      cable,
      ground,
      [],
      manualInput: input,
    );
  }

  /// Derives every published fact rather than accepting caller-authored cells.
  factory ConduitSelectionResult.selected({
    required ConduitSelectionInput input,
    required CableCoordinationResult cable,
    required GroundingConductorSelectionResult ground,
  }) {
    if (input.unsupportedReason != null) {
      throw ArgumentError(input.unsupportedReason);
    }
    final mismatch = snapshotIssue(input, cable, ground);
    if (mismatch != null) throw ArgumentError(mismatch);
    final selections = <ConduitRunSelection>[];
    for (final conduit in input.conduits) {
      final cell = const TableC1Repository().select(
        conduit.conductors.first.sizeSqmm,
        conduit.conductors.length,
      );
      if (cell == null) {
        throw ArgumentError('No published C1 capacity/exact row.');
      }
      selections.add(
        ConduitRunSelection._(conduit.id, conduit.runs.single, cell),
      );
    }
    return ConduitSelectionResult._(
      ConduitSelectionStatus.selected,
      null,
      input,
      cable,
      ground,
      selections,
    );
  }

  static String? snapshotIssue(
    ConduitSelectionInput input,
    CableCoordinationResult cable,
    GroundingConductorSelectionResult ground,
  ) {
    if (cable.status != CableSelectionStatus.coordinated ||
        ground.status != GroundingConductorSelectionStatus.selected) {
      return 'CP4 coordinated cable and CP6 selected grounding are required.';
    }
    if (input.parallelRuns != cable.runs) return 'CP4 run snapshot mismatch.';
    if (ground.phaseConductorSizeSqmm != null &&
        ground.phaseConductorSizeSqmm != cable.sizeSqmm) {
      return 'CP6 phase snapshot mismatch.';
    }
    if (ground.ratedCurrentA != cable.breakerRatedCurrentInA) {
      return 'CP4/CP6 breaker snapshot mismatch.';
    }
    for (final conduit in input.conduits) {
      for (final wire in conduit.conductors) {
        if (wire.role == PhysicalConductorRole.grounding) {
          if (wire.sizeSqmm != ground.groundingConductorSizeSqmm) {
            return 'CP6 grounding size snapshot mismatch.';
          }
        } else if (wire.sizeSqmm != cable.sizeSqmm ||
            wire.identity != cable.identity ||
            wire.coreType != cable.coreType ||
            wire.insulation != cable.insulation) {
          return 'CP4 physical conductor snapshot mismatch.';
        }
      }
    }
    return null;
  }

  final ConduitSelectionStatus status;
  final String? reason;
  final ConduitSelectionInput? input;
  final CableCoordinationResult? cableSnapshot;
  final GroundingConductorSelectionResult? groundSnapshot;
  final List<ConduitRunSelection> selections;
  final ManualConduitSelectionInput? manualInput;
  int get conduitCount => manualInput?.conduits.length ?? selections.length;
  ConduitSelectionMethod? get selectionMethod => switch (status) {
    ConduitSelectionStatus.selected => ConduitSelectionMethod.automaticTableC1,
    ConduitSelectionStatus.manualSelected =>
      ConduitSelectionMethod.manualEngineeringSelection,
    _ => null,
  };
  static const manualVerificationScope =
      'User-supplied engineering selection; conduit fill and standards compliance are not verified.';

  Map<String, Object?> toJson() => {
    'status': status.name,
    if (reason != null) 'reason': reason,
    if (selectionMethod != null) 'selectionMethod': selectionMethod!.name,
    if (status == ConduitSelectionStatus.manualSelected) ...{
      'label': 'Manual engineering conduit selection',
      'verificationScope': manualVerificationScope,
      'manualInput': manualInput!.toJson(),
      'cableSnapshot': cableSnapshot!.toJson(),
      'groundSnapshot': groundSnapshot!.toJson(),
      'conduitCount': conduitCount,
    },
    if (status == ConduitSelectionStatus.selected) ...{
      'label': TableC1Repository.resultLabel,
      'materialScope': TableC1Repository.materialScope,
      'sourceSha256': TableC1Repository.sourceSha256,
      'input': input!.toJson(),
      'cableSnapshot': cableSnapshot!.toJson(),
      'groundSnapshot': groundSnapshot!.toJson(),
      'conduitCount': conduitCount,
      'selections': selections.map((s) => s.toJson()).toList(),
    },
  };
  factory ConduitSelectionResult.fromJson(Map<String, Object?> json) {
    final status = ConduitSelectionStatus.values.byName(
      json['status'] as String,
    );
    final ConduitSelectionResult result;
    if (status == ConduitSelectionStatus.selected) {
      result = ConduitSelectionResult.selected(
        input: ConduitSelectionInput.fromJson(
          Map<String, Object?>.from(json['input'] as Map),
        ),
        cable: CableCoordinationResult.fromJson(
          Map<String, Object?>.from(json['cableSnapshot'] as Map),
        ),
        ground: GroundingConductorSelectionResult.fromJson(
          Map<String, Object?>.from(json['groundSnapshot'] as Map),
        ),
      );
    } else if (status == ConduitSelectionStatus.manualSelected) {
      result = ConduitSelectionResult.manualSelected(
        input: ManualConduitSelectionInput.fromJson(
          Map<String, Object?>.from(json['manualInput'] as Map),
        ),
        cable: CableCoordinationResult.fromJson(
          Map<String, Object?>.from(json['cableSnapshot'] as Map),
        ),
        ground: GroundingConductorSelectionResult.fromJson(
          Map<String, Object?>.from(json['groundSnapshot'] as Map),
        ),
      );
    } else {
      final reason = json['reason'] as String?;
      result = switch (status) {
        ConduitSelectionStatus.notCalculated =>
          ConduitSelectionResult.notCalculated(reason: reason),
        ConduitSelectionStatus.insufficient =>
          ConduitSelectionResult.insufficient(reason: reason!),
        ConduitSelectionStatus.invalid => ConduitSelectionResult.invalid(
          reason: reason!,
        ),
        ConduitSelectionStatus.unsupported =>
          ConduitSelectionResult.unsupported(reason: reason!),
        ConduitSelectionStatus.selected => throw StateError('unreachable'),
        ConduitSelectionStatus.manualSelected => throw StateError(
          'unreachable',
        ),
      };
    }
    final canonical = result.toJson();
    // CP7A persisted payloads predate the method discriminator. Only that
    // known automatic legacy shape is accepted; manual payloads require it.
    if (status == ConduitSelectionStatus.selected &&
        !json.containsKey('selectionMethod')) {
      canonical.remove('selectionMethod');
    }
    if (!conduitJsonEqual(json, canonical)) {
      throw ArgumentError('Contradictory or unknown conduit JSON payload.');
    }
    return result;
  }
}
