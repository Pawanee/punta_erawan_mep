import '../../cable_design/enums/core_type.dart';
import '../../cable_design/models/cable_routing_identity.dart';
import '../../voltage_drop/enums/cable_insulation.dart';
import '../enums/circuit_phase_configuration.dart';

enum PhysicalConductorRole { line1, line2, line3, neutral, grounding }

void conduitKeys(Map<String, Object?> json, Set<String> keys) {
  if (json.keys.any((key) => !keys.contains(key))) {
    throw ArgumentError('Unknown conduit JSON field.');
  }
}

/// One physical insulated wire, never an ampacity loaded-conductor count.
class PhysicalConductor {
  PhysicalConductor({
    required this.id,
    required this.run,
    required this.role,
    required this.identity,
    required this.coreType,
    required this.insulation,
    required this.sizeSqmm,
  }) {
    if (id.trim().isEmpty ||
        id != id.trim() ||
        run <= 0 ||
        !sizeSqmm.isFinite ||
        sizeSqmm <= 0) {
      throw ArgumentError('Invalid physical conductor identity, run or size.');
    }
  }
  final String id;
  final int run;
  final PhysicalConductorRole role;
  final CableRoutingIdentity identity;
  final CoreType coreType;
  final CableInsulation insulation;
  final double sizeSqmm;
  Map<String, Object?> toJson() => {
    'id': id,
    'run': run,
    'role': role.name,
    'identity': identity.name,
    'coreType': coreType.name,
    'insulation': insulation.name,
    'sizeSqmm': sizeSqmm,
  };
  factory PhysicalConductor.fromJson(Map<String, Object?> json) {
    conduitKeys(json, {
      'id',
      'run',
      'role',
      'identity',
      'coreType',
      'insulation',
      'sizeSqmm',
    });
    return PhysicalConductor(
      id: json['id'] as String,
      run: json['run'] as int,
      role: PhysicalConductorRole.values.byName(json['role'] as String),
      identity: CableRoutingIdentity.values.byName(json['identity'] as String),
      coreType: CoreType.values.byName(json['coreType'] as String),
      insulation: CableInsulation.values.byName(json['insulation'] as String),
      sizeSqmm: (json['sizeSqmm'] as num).toDouble(),
    );
  }
}

class PhysicalConduit {
  PhysicalConduit({
    required this.id,
    required this.shared,
    required List<int> runs,
    required List<PhysicalConductor> conductors,
  }) : runs = List.unmodifiable(runs),
       conductors = List.unmodifiable(conductors) {
    if (id.trim().isEmpty ||
        id != id.trim() ||
        runs.isEmpty ||
        runs.any((r) => r <= 0) ||
        runs.toSet().length != runs.length ||
        conductors.isEmpty) {
      throw ArgumentError('Conduit requires unique runs and physical wires.');
    }
  }
  final String id;
  final bool shared;
  final List<int> runs;
  final List<PhysicalConductor> conductors;
  Map<String, Object?> toJson() => {
    'id': id,
    'shared': shared,
    'runs': runs,
    'conductors': conductors.map((c) => c.toJson()).toList(),
  };
  factory PhysicalConduit.fromJson(Map<String, Object?> json) {
    conduitKeys(json, {'id', 'shared', 'runs', 'conductors'});
    return PhysicalConduit(
      id: json['id'] as String,
      shared: json['shared'] as bool,
      runs: (json['runs'] as List).cast<int>(),
      conductors: (json['conductors'] as List)
          .map(
            (c) =>
                PhysicalConductor.fromJson(Map<String, Object?>.from(c as Map)),
          )
          .toList(),
    );
  }
}

/// The installation declaration explicitly states whether N and PE are routed
/// in each run. Their absence is never inferred from loadedConductors.
class ConduitSelectionInput {
  ConduitSelectionInput({
    required this.phaseConfiguration,
    required this.parallelRuns,
    required this.neutralPerRun,
    required this.groundingPerRun,
    required List<PhysicalConduit> conduits,
  }) : conduits = List.unmodifiable(conduits) {
    if (parallelRuns <= 0 || conduits.isEmpty) {
      throw ArgumentError(
        'Positive runs and an explicit conduit list required.',
      );
    }
    final conduitIds = <String>{};
    final wireIds = <String>{};
    final declaredRuns = <int>{};
    for (final conduit in conduits) {
      if (!conduitIds.add(conduit.id)) {
        throw ArgumentError('Duplicate conduit.');
      }
      for (final run in conduit.runs) {
        if (run > parallelRuns || !declaredRuns.add(run)) {
          throw ArgumentError('Duplicate or out-of-range run.');
        }
      }
      for (final wire in conduit.conductors) {
        if (!wireIds.add(wire.id) || !conduit.runs.contains(wire.run)) {
          throw ArgumentError(
            'Duplicate wire or contradictory run assignment.',
          );
        }
      }
      for (final run in conduit.runs) {
        final expected = <PhysicalConductorRole>{
          PhysicalConductorRole.line1,
          if (phaseConfiguration == CircuitPhaseConfiguration.threePhase) ...[
            PhysicalConductorRole.line2,
            PhysicalConductorRole.line3,
          ],
          if (neutralPerRun) PhysicalConductorRole.neutral,
          if (groundingPerRun) PhysicalConductorRole.grounding,
        };
        final wires = conduit.conductors.where((c) => c.run == run).toList();
        if (wires.length != expected.length ||
            wires.map((c) => c.role).toSet().length != expected.length ||
            wires.any((c) => !expected.contains(c.role))) {
          throw ArgumentError(
            'Missing, duplicate or unexpected conductor role.',
          );
        }
      }
    }
    if (declaredRuns.length != parallelRuns) {
      throw ArgumentError('Missing run.');
    }
  }
  final CircuitPhaseConfiguration phaseConfiguration;
  final int parallelRuns;
  final bool neutralPerRun;
  final bool groundingPerRun;
  final List<PhysicalConduit> conduits;
  String? get unsupportedReason {
    for (final conduit in conduits) {
      if (conduit.shared || conduit.runs.length != 1) {
        return 'Shared/multiple-run conduit is unsupported.';
      }
      final size = conduit.conductors.first.sizeSqmm;
      for (final wire in conduit.conductors) {
        if (wire.identity != CableRoutingIdentity.iec01 ||
            wire.coreType != CoreType.singleCore ||
            wire.insulation != CableInsulation.pvc) {
          return 'Only single-core PVC IEC 01 is supported.';
        }
        if (wire.sizeSqmm != size) return 'Mixed-size conduit is unsupported.';
      }
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'phaseConfiguration': phaseConfiguration.name,
    'parallelRuns': parallelRuns,
    'neutralPerRun': neutralPerRun,
    'groundingPerRun': groundingPerRun,
    'conduits': conduits.map((c) => c.toJson()).toList(),
  };
  factory ConduitSelectionInput.fromJson(Map<String, Object?> json) {
    conduitKeys(json, {
      'phaseConfiguration',
      'parallelRuns',
      'neutralPerRun',
      'groundingPerRun',
      'conduits',
    });
    return ConduitSelectionInput(
      phaseConfiguration: CircuitPhaseConfiguration.values.byName(
        json['phaseConfiguration'] as String,
      ),
      parallelRuns: json['parallelRuns'] as int,
      neutralPerRun: json['neutralPerRun'] as bool,
      groundingPerRun: json['groundingPerRun'] as bool,
      conduits: (json['conduits'] as List)
          .map(
            (c) =>
                PhysicalConduit.fromJson(Map<String, Object?>.from(c as Map)),
          )
          .toList(),
    );
  }
}
