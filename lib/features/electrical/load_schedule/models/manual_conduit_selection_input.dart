import '../../cable_design/enums/core_type.dart';
import '../../cable_design/models/cable_routing_identity.dart';
import '../../voltage_drop/enums/cable_insulation.dart';
import '../enums/cable_selection_status.dart';
import '../enums/circuit_phase_configuration.dart';
import '../enums/grounding_conductor_selection_status.dart';
import 'cable_coordination_result.dart';
import 'conduit_selection_input.dart';
import 'grounding_conductor_selection_result.dart';

void _text(String value, String field) {
  if (value.trim().isEmpty) throw ArgumentError('$field must not be blank.');
}

void _positive(double value, String field) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError('$field must be finite and positive.');
  }
}

void _uniqueIds(List<String> ids, String field) {
  if (ids.isEmpty ||
      ids.toSet().length != ids.length ||
      ids.any((id) => id.trim().isEmpty || id != id.trim())) {
    throw ArgumentError('$field requires nonblank unique identifiers.');
  }
}

enum ManualConduitType { emt, imc, rsc, pvc, other }

/// User-supplied evidence, not a verified compliance certificate.
class ManualConduitSourceReference {
  ManualConduitSourceReference({
    required this.id,
    required this.manufacturer,
    required this.document,
    required this.revision,
    required this.page,
  }) {
    _uniqueIds([id], 'source id');
    _text(manufacturer, 'manufacturer');
    _text(document, 'document');
    _text(revision, 'revision');
    _text(page, 'page');
  }
  final String id;
  final String manufacturer;
  final String document;
  final String revision;
  final String page;
  Map<String, Object?> toJson() => {
    'id': id,
    'manufacturer': manufacturer,
    'document': document,
    'revision': revision,
    'page': page,
  };
  factory ManualConduitSourceReference.fromJson(Map<String, Object?> json) {
    conduitKeys(json, {'id', 'manufacturer', 'document', 'revision', 'page'});
    return ManualConduitSourceReference(
      id: json['id'] as String,
      manufacturer: json['manufacturer'] as String,
      document: json['document'] as String,
      revision: json['revision'] as String,
      page: json['page'] as String,
    );
  }
}

class ManualCableCore {
  ManualCableCore({required this.role, required this.sizeSqmm}) {
    _positive(sizeSqmm, 'core size');
  }
  final PhysicalConductorRole role;
  final double sizeSqmm;
  Map<String, Object?> toJson() => {'role': role.name, 'sizeSqmm': sizeSqmm};
  factory ManualCableCore.fromJson(Map<String, Object?> json) {
    conduitKeys(json, {'role', 'sizeSqmm'});
    return ManualCableCore(
      role: PhysicalConductorRole.values.byName(json['role'] as String),
      sizeSqmm: (json['sizeSqmm'] as num).toDouble(),
    );
  }
}

/// A whole physical cable is allocated once. Its cores cannot be split between
/// conduits. No outside diameter or fill area is inferred from core size.
class ManualPhysicalCable {
  ManualPhysicalCable({
    required this.id,
    required this.run,
    required this.identity,
    required this.coreType,
    required this.insulation,
    required List<ManualCableCore> cores,
  }) : cores = List.unmodifiable(cores) {
    _uniqueIds([id], 'cable id');
    if (run <= 0 ||
        cores.isEmpty ||
        cores.map((c) => c.role).toSet().length != cores.length ||
        (coreType == CoreType.singleCore && cores.length != 1) ||
        (coreType == CoreType.multiCore && cores.length < 2)) {
      throw ArgumentError(
        'Invalid run, duplicate core role or core construction.',
      );
    }
  }
  final String id;
  final int run;
  final CableRoutingIdentity identity;
  final CoreType coreType;
  final CableInsulation insulation;
  final List<ManualCableCore> cores;
  Map<String, Object?> toJson() => {
    'id': id,
    'run': run,
    'identity': identity.name,
    'coreType': coreType.name,
    'insulation': insulation.name,
    'cores': cores.map((c) => c.toJson()).toList(),
  };
  factory ManualPhysicalCable.fromJson(Map<String, Object?> json) {
    conduitKeys(json, {
      'id',
      'run',
      'identity',
      'coreType',
      'insulation',
      'cores',
    });
    return ManualPhysicalCable(
      id: json['id'] as String,
      run: json['run'] as int,
      identity: CableRoutingIdentity.values.byName(json['identity'] as String),
      coreType: CoreType.values.byName(json['coreType'] as String),
      insulation: CableInsulation.values.byName(json['insulation'] as String),
      cores: (json['cores'] as List)
          .map(
            (c) =>
                ManualCableCore.fromJson(Map<String, Object?>.from(c as Map)),
          )
          .toList(),
    );
  }
}

/// One physical conduit with an explicit specification and evidence links.
class ManualConduitAllocation {
  ManualConduitAllocation({
    required this.id,
    required this.type,
    required this.material,
    required this.standardSpecification,
    required this.nominalSizeMm,
    required List<String> cableIds,
    required List<String> sourceReferenceIds,
  }) : cableIds = List.unmodifiable(cableIds),
       sourceReferenceIds = List.unmodifiable(sourceReferenceIds) {
    _uniqueIds([id], 'conduit id');
    _text(material, 'material');
    _text(standardSpecification, 'standard/specification');
    _positive(nominalSizeMm, 'nominal conduit size');
    _uniqueIds(cableIds, 'allocated cables');
    _uniqueIds(sourceReferenceIds, 'conduit source references');
  }
  final String id;
  final ManualConduitType type;
  final String material;
  final String standardSpecification;
  final double nominalSizeMm;
  final List<String> cableIds;
  final List<String> sourceReferenceIds;
  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'material': material,
    'standardSpecification': standardSpecification,
    'nominalSizeMm': nominalSizeMm,
    'cableIds': cableIds,
    'sourceReferenceIds': sourceReferenceIds,
  };
  factory ManualConduitAllocation.fromJson(Map<String, Object?> json) {
    conduitKeys(json, {
      'id',
      'type',
      'material',
      'standardSpecification',
      'nominalSizeMm',
      'cableIds',
      'sourceReferenceIds',
    });
    return ManualConduitAllocation(
      id: json['id'] as String,
      type: ManualConduitType.values.byName(json['type'] as String),
      material: json['material'] as String,
      standardSpecification: json['standardSpecification'] as String,
      nominalSizeMm: (json['nominalSizeMm'] as num).toDouble(),
      cableIds: (json['cableIds'] as List).cast<String>(),
      sourceReferenceIds: (json['sourceReferenceIds'] as List).cast<String>(),
    );
  }
}

class ManualConduitRunMapping {
  ManualConduitRunMapping({
    required this.run,
    required this.conduitCount,
    required List<String> conduitIds,
  }) : conduitIds = List.unmodifiable(conduitIds) {
    _uniqueIds(conduitIds, 'run conduit identifiers');
    if (run <= 0 || conduitCount <= 0 || conduitCount != conduitIds.length) {
      throw ArgumentError(
        'Conduit count must match the physical conduits per run.',
      );
    }
  }
  final int run;
  final int conduitCount;
  final List<String> conduitIds;
  Map<String, Object?> toJson() => {
    'run': run,
    'conduitCount': conduitCount,
    'conduitIds': conduitIds,
  };
  factory ManualConduitRunMapping.fromJson(Map<String, Object?> json) {
    conduitKeys(json, {'run', 'conduitCount', 'conduitIds'});
    return ManualConduitRunMapping(
      run: json['run'] as int,
      conduitCount: json['conduitCount'] as int,
      conduitIds: (json['conduitIds'] as List).cast<String>(),
    );
  }
}

class ManualConduitSelectionInput {
  ManualConduitSelectionInput({
    required this.phaseConfiguration,
    required this.parallelRuns,
    required this.neutralPerRun,
    required this.groundingPerRun,
    required this.selectionReason,
    required this.selectedBy,
    this.checkedBy,
    required List<ManualConduitSourceReference> sourceReferences,
    required List<ManualPhysicalCable> cables,
    required List<ManualConduitAllocation> conduits,
    required List<ManualConduitRunMapping> runMappings,
  }) : sourceReferences = List.unmodifiable(sourceReferences),
       cables = List.unmodifiable(cables),
       conduits = List.unmodifiable(conduits),
       runMappings = List.unmodifiable(runMappings) {
    _text(selectionReason, 'selection reason');
    _text(selectedBy, 'selected by identifier');
    if (checkedBy != null) _text(checkedBy!, 'checked by identifier');
    if (parallelRuns <= 0) {
      throw ArgumentError('Positive parallel runs required.');
    }
    _uniqueIds(sourceReferences.map((s) => s.id).toList(), 'sources');
    _uniqueIds(cables.map((c) => c.id).toList(), 'cables');
    _uniqueIds(conduits.map((c) => c.id).toList(), 'conduits');
    final byId = {for (final cable in cables) cable.id: cable};
    final sourceIds = sourceReferences.map((s) => s.id).toSet();
    final assigned = <String>{};
    final expectedMapping = <int, Set<String>>{};
    for (final conduit in conduits) {
      if (conduit.sourceReferenceIds.any((id) => !sourceIds.contains(id))) {
        throw ArgumentError('Unknown conduit source reference.');
      }
      for (final id in conduit.cableIds) {
        final cable = byId[id];
        if (cable == null || !assigned.add(id)) {
          throw ArgumentError(
            'Unknown or duplicate physical cable allocation.',
          );
        }
        expectedMapping
            .putIfAbsent(cable.run, () => <String>{})
            .add(conduit.id);
      }
    }
    if (assigned.length != cables.length ||
        cables.any((c) => c.run > parallelRuns)) {
      throw ArgumentError('Missing cable allocation or out-of-range run.');
    }
    if (runMappings.length != parallelRuns ||
        runMappings.map((m) => m.run).toSet().length != parallelRuns) {
      throw ArgumentError('Missing or duplicate run mapping.');
    }
    for (final mapping in runMappings) {
      final expected = expectedMapping[mapping.run];
      if (expected == null ||
          expected.length != mapping.conduitCount ||
          mapping.conduitIds.any((id) => !expected.contains(id))) {
        throw ArgumentError(
          'Run mapping contradicts physical cable allocation.',
        );
      }
    }
    final requiredRoles = <PhysicalConductorRole>{
      PhysicalConductorRole.line1,
      if (phaseConfiguration == CircuitPhaseConfiguration.threePhase) ...[
        PhysicalConductorRole.line2,
        PhysicalConductorRole.line3,
      ],
      if (neutralPerRun) PhysicalConductorRole.neutral,
      if (groundingPerRun) PhysicalConductorRole.grounding,
    };
    for (var run = 1; run <= parallelRuns; run++) {
      final roles = cables
          .where((c) => c.run == run)
          .expand((c) => c.cores)
          .map((c) => c.role)
          .toList();
      if (roles.length != requiredRoles.length ||
          roles.toSet().length != requiredRoles.length ||
          roles.any((role) => !requiredRoles.contains(role))) {
        throw ArgumentError(
          'Missing, duplicate or unexpected physical conductor role.',
        );
      }
    }
  }
  final CircuitPhaseConfiguration phaseConfiguration;
  final int parallelRuns;
  final bool neutralPerRun;
  final bool groundingPerRun;
  final String selectionReason;
  final String selectedBy;
  final String? checkedBy;
  final List<ManualConduitSourceReference> sourceReferences;
  final List<ManualPhysicalCable> cables;
  final List<ManualConduitAllocation> conduits;
  final List<ManualConduitRunMapping> runMappings;

  String? snapshotIssue(
    CableCoordinationResult cable,
    GroundingConductorSelectionResult ground,
  ) {
    if (cable.status != CableSelectionStatus.coordinated ||
        ground.status != GroundingConductorSelectionStatus.selected) {
      return 'Manual selection requires CP4 coordinated cable and CP6 selected ground.';
    }
    if (parallelRuns != cable.runs ||
        cable.loadedConductors !=
            (phaseConfiguration == CircuitPhaseConfiguration.singlePhase
                ? 2
                : 3)) {
      return 'CP4 parallel runs or phase configuration mismatch.';
    }
    if (ground.ratedCurrentA != cable.breakerRatedCurrentInA ||
        (ground.phaseConductorSizeSqmm != null &&
            ground.phaseConductorSizeSqmm != cable.sizeSqmm)) {
      return 'CP4/CP6 snapshot mismatch.';
    }
    for (final physical in cables) {
      for (final core in physical.cores) {
        if (core.role == PhysicalConductorRole.grounding) {
          if (core.sizeSqmm != ground.groundingConductorSizeSqmm) {
            return 'Physical grounding size must match CP6.';
          }
        } else if (core.sizeSqmm != cable.sizeSqmm ||
            physical.identity != cable.identity ||
            physical.insulation != cable.insulation ||
            physical.coreType != cable.coreType) {
          return 'Physical phase/neutral cable must match CP4.';
        }
      }
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'phaseConfiguration': phaseConfiguration.name,
    'parallelRuns': parallelRuns,
    'neutralPerRun': neutralPerRun,
    'groundingPerRun': groundingPerRun,
    'selectionReason': selectionReason,
    'selectedBy': selectedBy,
    if (checkedBy != null) 'checkedBy': checkedBy,
    'sourceReferences': sourceReferences.map((s) => s.toJson()).toList(),
    'cables': cables.map((c) => c.toJson()).toList(),
    'conduits': conduits.map((c) => c.toJson()).toList(),
    'runMappings': runMappings.map((m) => m.toJson()).toList(),
  };
  factory ManualConduitSelectionInput.fromJson(Map<String, Object?> json) {
    conduitKeys(json, {
      'phaseConfiguration',
      'parallelRuns',
      'neutralPerRun',
      'groundingPerRun',
      'selectionReason',
      'selectedBy',
      'checkedBy',
      'sourceReferences',
      'cables',
      'conduits',
      'runMappings',
    });
    return ManualConduitSelectionInput(
      phaseConfiguration: CircuitPhaseConfiguration.values.byName(
        json['phaseConfiguration'] as String,
      ),
      parallelRuns: json['parallelRuns'] as int,
      neutralPerRun: json['neutralPerRun'] as bool,
      groundingPerRun: json['groundingPerRun'] as bool,
      selectionReason: json['selectionReason'] as String,
      selectedBy: json['selectedBy'] as String,
      checkedBy: json['checkedBy'] as String?,
      sourceReferences: (json['sourceReferences'] as List)
          .map(
            (s) => ManualConduitSourceReference.fromJson(
              Map<String, Object?>.from(s as Map),
            ),
          )
          .toList(),
      cables: (json['cables'] as List)
          .map(
            (c) => ManualPhysicalCable.fromJson(
              Map<String, Object?>.from(c as Map),
            ),
          )
          .toList(),
      conduits: (json['conduits'] as List)
          .map(
            (c) => ManualConduitAllocation.fromJson(
              Map<String, Object?>.from(c as Map),
            ),
          )
          .toList(),
      runMappings: (json['runMappings'] as List)
          .map(
            (m) => ManualConduitRunMapping.fromJson(
              Map<String, Object?>.from(m as Map),
            ),
          )
          .toList(),
    );
  }
}
