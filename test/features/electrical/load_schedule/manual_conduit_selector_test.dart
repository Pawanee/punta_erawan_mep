import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/load_schedule/load_schedule.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'conduit_selector_test.dart' as cp7a;

void main() {
  test(
    'explicit mixed-size manual selection records evidence without C1 or fill claims',
    () {
      final value = manualInput();
      final result = manualSelect(value);
      expect(result.status, ConduitSelectionStatus.manualSelected);
      expect(
        result.selectionMethod,
        ConduitSelectionMethod.manualEngineeringSelection,
      );
      expect(result.input, isNull);
      expect(result.selections, isEmpty);
      expect(result.conduitCount, 1);
      expect(result.manualInput!.selectedBy, 'engineer-001');
      expect(result.manualInput!.checkedBy, 'checker-002');
      final json = result.toJson();
      expect(json['selectionMethod'], 'manualEngineeringSelection');
      expect(json['verificationScope'], contains('not verified'));
      for (final key in [
        'sourceSha256',
        'selections',
        'tableId',
        'tableVersion',
        'fillFactor',
        'conduitArea',
        'outsideDiameterMm',
        'insideDiameterMm',
      ]) {
        expect(json.containsKey(key), isFalse);
      }
      final allocation = value.conduits.single;
      expect(allocation.type, ManualConduitType.emt);
      expect(allocation.material, 'Engineer-entered steel');
      expect(allocation.standardSpecification, 'Project specification M-01');
      expect(allocation.nominalSizeMm, 25);
      expect(allocation.sourceReferenceIds, ['source-1']);
      expect(value.sourceReferences.single.manufacturer, 'Test manufacturer');
      expect(
        value.sourceReferences.single.document,
        'Engineering selection record',
      );
      expect(value.sourceReferences.single.revision, 'R1');
      expect(value.sourceReferences.single.page, '12');
    },
  );
  test(
    'manual input and result round-trip, key ordering independent, immutable lists',
    () {
      final value = manualInput();
      expect(
        ManualConduitSelectionInput.fromJson(deep(value.toJson())).toJson(),
        value.toJson(),
      );
      final result = manualSelect(value);
      expect(
        ConduitSelectionResult.fromJson(deep(result.toJson())).toJson(),
        result.toJson(),
      );
      final reordered = Map<String, Object?>.fromEntries(
        result.toJson().entries.toList().reversed,
      );
      expect(
        ConduitSelectionResult.fromJson(reordered).toJson(),
        result.toJson(),
      );
      expect(() => value.cables.clear(), throwsUnsupportedError);
      expect(() => value.cables.first.cores.clear(), throwsUnsupportedError);
      expect(() => value.conduits.clear(), throwsUnsupportedError);
      expect(
        () => value.conduits.first.cableIds.clear(),
        throwsUnsupportedError,
      );
      expect(() => value.runMappings.clear(), throwsUnsupportedError);
      expect(() => value.sourceReferences.clear(), throwsUnsupportedError);
    },
  );
  test(
    'multiple conduits per run and shared conduit are explicit allocations',
    () {
      final split = manualInput(split: true);
      expect(manualSelect(split).conduitCount, 2);
      expect(split.runMappings.single.conduitCount, 2);
      final shared = manualInput(runs: 2, shared: true);
      final result = manualSelect(shared, cable: manualCable(runs: 2));
      expect(result.status, ConduitSelectionStatus.manualSelected);
      expect(result.conduitCount, 1); // One shared physical conduit, not two.
      expect(result.manualInput!.runMappings.map((m) => m.conduitCount), [
        1,
        1,
      ]);
      expect(result.manualInput!.cables.length, 6);
    },
  );
  test('NYY multi-core allocates the whole cable exactly once', () {
    final value = manualInput(multi: true);
    final result = manualSelect(value, cable: manualCable(multi: true));
    expect(result.status, ConduitSelectionStatus.manualSelected);
    expect(value.cables.length, 1);
    expect(value.cables.single.cores.length, 3);
    expect(value.conduits.single.cableIds, ['cable-1']);
    expect(
      ConduitSelectionResult.fromJson(deep(result.toJson())).toJson(),
      result.toJson(),
    );
  });
  test('XLPE and three-phase manual input validate against matching CP4', () {
    final xlpe = manualInput(xlpe: true);
    expect(
      manualSelect(xlpe, cable: manualCable(xlpe: true)).status,
      ConduitSelectionStatus.manualSelected,
    );
    final three = manualInput(three: true);
    expect(
      manualSelect(
        three,
        cable: manualCable(three: true),
        phase: CircuitPhaseConfiguration.threePhase,
      ).status,
      ConduitSelectionStatus.manualSelected,
    );
    expect(three.cables.length, 5);
  });
  test('no automatic fallback: unsupported CP7A stays unsupported', () {
    final autoJson = cp7a.input(size: 4).toJson();
    ((autoJson['conduits'] as List).first as Map)['conductors'][2]['sizeSqmm'] =
        2.5;
    final automatic = const ConduitSelector().select(
      circuitStatus: CircuitStatus.active,
      cable: manualCable(),
      ground: cp7a.ground(),
      input: ConduitSelectionInput.fromJson(autoJson),
    );
    expect(automatic.status, ConduitSelectionStatus.unsupported);
    expect(automatic.manualInput, isNull);
    expect(automatic.selectionMethod, isNull);
    expect(
      manualSelect(manualInput()).status,
      ConduitSelectionStatus.manualSelected,
    );
  });
  test(
    'CP7A results remain automatic and old persisted JSON remains readable',
    () {
      final automatic = cp7a.select(cp7a.input());
      expect(
        automatic.selectionMethod,
        ConduitSelectionMethod.automaticTableC1,
      );
      expect(automatic.toJson()['selectionMethod'], 'automaticTableC1');
      expect(automatic.selections.single.nominalSizeMm, 15);
      expect(automatic.selections.single.requestedCount, 3);
      expect(automatic.selections.single.publishedCapacity, 5);
      final legacy = automatic.toJson()..remove('selectionMethod');
      expect(
        ConduitSelectionResult.fromJson(legacy).toJson(),
        automatic.toJson(),
      );
      expect(automatic.manualInput, isNull);
    },
  );
  final invalidInputs = <String, void Function(Map<String, Object?>)>{
    'missing reason': (j) => j.remove('selectionReason'),
    'blank reason': (j) => j['selectionReason'] = ' ',
    'missing source': (j) => j['sourceReferences'] = [],
    'missing source field': (j) => source(j).remove('document'),
    'blank manufacturer': (j) => source(j)['manufacturer'] = '',
    'blank document': (j) => source(j)['document'] = '',
    'blank revision': (j) => source(j)['revision'] = '',
    'blank page': (j) => source(j)['page'] = '',
    'missing specification': (j) =>
        allocation(j).remove('standardSpecification'),
    'blank specification': (j) => allocation(j)['standardSpecification'] = ' ',
    'blank material': (j) => allocation(j)['material'] = '',
    'unknown type': (j) => allocation(j)['type'] = 'unknown',
    'missing selector identity': (j) => j.remove('selectedBy'),
    'blank selector identity': (j) => j['selectedBy'] = '',
    'blank checker identity': (j) => j['checkedBy'] = ' ',
    'unknown source link': (j) =>
        allocation(j)['sourceReferenceIds'] = ['absent'],
    'duplicate source': (j) => (j['sourceReferences'] as List).add(source(j)),
    'missing physical cable': (j) => (j['cables'] as List).removeLast(),
    'missing allocation': (j) =>
        (allocation(j)['cableIds'] as List).removeLast(),
    'duplicate allocation': (j) =>
        (allocation(j)['cableIds'] as List).add('line1-1'),
    'unknown physical cable': (j) =>
        (allocation(j)['cableIds'] as List)[0] = 'missing',
    'duplicate physical cable': (j) => (j['cables'] as List).add(physical(j)),
    'duplicate core role': (j) => core(j, 1)['role'] = 'line1',
    'wrong run': (j) => physical(j)['run'] = 2,
    'missing run': (j) => j['parallelRuns'] = 2,
    'wrong mapping run': (j) => mapping(j)['run'] = 2,
    'wrong mapping conduit': (j) => mapping(j)['conduitIds'] = ['missing'],
    'wrong mapping count': (j) => mapping(j)['conduitCount'] = 2,
    'duplicate run mapping': (j) => (j['runMappings'] as List).add(mapping(j)),
    'unexpected neutral': (j) => j['neutralPerRun'] = false,
    'missing three-phase roles': (j) => j['phaseConfiguration'] = 'threePhase',
    'unknown role': (j) => core(j)['role'] = 'unknown',
    'unknown core type': (j) => physical(j)['coreType'] = 'unknown',
    'unknown identity': (j) => physical(j)['identity'] = 'unknown',
    'unknown insulation': (j) => physical(j)['insulation'] = 'unknown',
    'multi-core without cores': (j) => physical(j)['coreType'] = 'multiCore',
    'C1 field in manual': (j) => j['tableId'] = 'C1',
    'OD field in physical cable': (j) => physical(j)['outsideDiameterMm'] = 5,
    'fill factor field': (j) => allocation(j)['fillFactor'] = 0.4,
    'inside diameter field': (j) => allocation(j)['insideDiameterMm'] = 20,
    'source unknown field': (j) => source(j)['verified'] = true,
    'core unknown field': (j) => core(j)['extra'] = null,
    'mapping unknown field': (j) => mapping(j)['extra'] = null,
  };
  for (final entry in invalidInputs.entries) {
    test('manual input rejects ${entry.key}', () {
      final json = deep(manualInput().toJson());
      entry.value(json);
      expect(
        () => ManualConduitSelectionInput.fromJson(json),
        throwsA(anything),
      );
    });
  }
  test(
    'numeric boundaries reject NaN Infinity zero negative and fractional counts',
    () {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
        0.0,
        -1.0,
      ]) {
        final json = deep(manualInput().toJson());
        allocation(json)['nominalSizeMm'] = value;
        expect(
          () => ManualConduitSelectionInput.fromJson(json),
          throwsA(anything),
        );
        expect(
          () => ManualConduitAllocation(
            id: 'c',
            type: ManualConduitType.emt,
            material: 'steel',
            standardSpecification: 'spec',
            nominalSizeMm: value,
            cableIds: ['wire'],
            sourceReferenceIds: ['s'],
          ),
          throwsArgumentError,
        );
        expect(
          () => ManualCableCore(
            role: PhysicalConductorRole.line1,
            sizeSqmm: value,
          ),
          throwsArgumentError,
        );
        final badCore = deep(manualInput().toJson());
        core(badCore)['sizeSqmm'] = value;
        expect(
          () => ManualConduitSelectionInput.fromJson(badCore),
          throwsA(anything),
        );
      }
      for (final value in [double.nan, double.infinity, 0, -1, 1.5]) {
        for (final mutate in <void Function(Map<String, Object?>)>[
          (j) => j['parallelRuns'] = value,
          (j) => physical(j)['run'] = value,
          (j) => mapping(j)['run'] = value,
          (j) => mapping(j)['conduitCount'] = value,
        ]) {
          final json = deep(manualInput().toJson());
          mutate(json);
          expect(
            () => ManualConduitSelectionInput.fromJson(json),
            throwsA(anything),
          );
        }
      }
    },
  );
  test(
    'constructor invariants match JSON boundary for missing evidence and allocation',
    () {
      expect(
        () => ManualConduitSourceReference(
          id: 's',
          manufacturer: 'maker',
          document: '',
          revision: 'r',
          page: '1',
        ),
        throwsArgumentError,
      );
      expect(
        () => ManualConduitAllocation(
          id: 'c',
          type: ManualConduitType.emt,
          material: 'steel',
          standardSpecification: '',
          nominalSizeMm: 25,
          cableIds: ['wire'],
          sourceReferenceIds: ['s'],
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            ManualConduitRunMapping(run: 1, conduitCount: 2, conduitIds: ['c']),
        throwsArgumentError,
      );
      final original = manualInput();
      ManualConduitSelectionInput build({
        String reason = 'reason',
        List<ManualConduitSourceReference>? sources,
        List<ManualPhysicalCable>? cables,
        List<ManualConduitAllocation>? conduits,
      }) => ManualConduitSelectionInput(
        phaseConfiguration: original.phaseConfiguration,
        parallelRuns: 1,
        neutralPerRun: true,
        groundingPerRun: true,
        selectionReason: reason,
        selectedBy: 'engineer',
        sourceReferences: sources ?? original.sourceReferences,
        cables: cables ?? original.cables,
        conduits: conduits ?? original.conduits,
        runMappings: original.runMappings,
      );
      expect(() => build(reason: ''), throwsArgumentError);
      expect(() => build(sources: []), throwsArgumentError);
      expect(
        () => build(cables: original.cables.take(2).toList()),
        throwsArgumentError,
      );
      expect(
        () => build(
          conduits: [original.conduits.single, original.conduits.single],
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'manual selector distinguishes missing data, snapshots and phase mismatch',
    () {
      expect(
        const ManualConduitSelector()
            .select(
              circuitStatus: CircuitStatus.active,
              phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
              cable: manualCable(),
              ground: cp7a.ground(),
            )
            .status,
        ConduitSelectionStatus.insufficient,
      );
      expect(
        manualSelect(
          manualInput(),
          cable: CableCoordinationResult.notCalculated(),
        ).status,
        ConduitSelectionStatus.insufficient,
      );
      expect(
        manualSelect(
          manualInput(),
          ground: GroundingConductorSelectionResult.notCalculated(),
        ).status,
        ConduitSelectionStatus.insufficient,
      );
      expect(
        manualSelect(
          manualInput(),
          phase: CircuitPhaseConfiguration.threePhase,
        ).status,
        ConduitSelectionStatus.invalid,
      );
      for (final snapshot in [
        manualCable(runs: 2),
        cp7a.cable(size: 6),
        manualCable(multi: true),
        manualCable(xlpe: true),
      ]) {
        expect(
          manualSelect(manualInput(), cable: snapshot).status,
          ConduitSelectionStatus.invalid,
        );
        expect(
          () => ConduitSelectionResult.manualSelected(
            input: manualInput(),
            cable: snapshot,
            ground: cp7a.ground(),
          ),
          throwsArgumentError,
        );
      }
      for (final ground in [
        cp7a.ground(rating: 40),
        cp7a.ground(phaseSize: 6),
      ]) {
        expect(
          manualSelect(manualInput(), ground: ground).status,
          ConduitSelectionStatus.invalid,
        );
        expect(
          () => ConduitSelectionResult.manualSelected(
            input: manualInput(),
            cable: manualCable(),
            ground: ground,
          ),
          throwsArgumentError,
        );
      }
      final wrongGround = deep(manualInput().toJson());
      core(wrongGround, 2)['sizeSqmm'] = 4;
      expect(
        manualSelect(ManualConduitSelectionInput.fromJson(wrongGround)).status,
        ConduitSelectionStatus.invalid,
      );
    },
  );
  test('manual and automatic payloads cannot be mixed or relabelled', () {
    final manual = manualSelect(manualInput()).toJson();
    final automatic = cp7a.select(cp7a.input()).toJson();
    for (final mutate in <void Function(Map<String, Object?>)>[
      (j) => j['selectionMethod'] = 'automaticTableC1',
      (j) => j.remove('selectionMethod'),
      (j) => j['status'] = 'selected',
      (j) => j['selections'] = automatic['selections'],
      (j) => j['input'] = automatic['input'],
      (j) => j['sourceSha256'] = TableC1Repository.sourceSha256,
      (j) => j['label'] = TableC1Repository.resultLabel,
      (j) => j['verificationScope'] = 'Standards compliant',
      (j) => j['conduitCount'] = 2,
      (j) => j['reason'] = 'C1 selection',
      (j) => j['manualInput'] = null,
      (j) => (j['cableSnapshot'] as Map)['sizeSqmm'] = 6,
      (j) => (j['groundSnapshot'] as Map)['extra'] = true,
    ]) {
      final json = deep(manual);
      mutate(json);
      expect(() => ConduitSelectionResult.fromJson(json), throwsA(anything));
    }
    for (final mutate in <void Function(Map<String, Object?>)>[
      (j) => j['manualInput'] = manual['manualInput'],
      (j) => j['selectionMethod'] = 'manualEngineeringSelection',
      (j) => j['status'] = 'manualSelected',
    ]) {
      final json = deep(automatic);
      mutate(json);
      expect(() => ConduitSelectionResult.fromJson(json), throwsA(anything));
    }
    final unresolved = ConduitSelectionResult.notCalculated().toJson()
      ..['manualInput'] = manual['manualInput'];
    expect(
      () => ConduitSelectionResult.fromJson(unresolved),
      throwsArgumentError,
    );
  });
  test(
    'aggregate validates manual CP4 CP6 and phase on constructors and JSON',
    () {
      final result = manualSelect(manualInput());
      final aggregate = cp7a.active(result, cableOverride: manualCable());
      expect(
        CircuitCalculationResult.fromJson(deep(aggregate.toJson())).toJson(),
        aggregate.toJson(),
      );
      expect(
        () => cp7a.active(result, cableOverride: cp7a.cable(size: 6)),
        throwsArgumentError,
      );
      expect(
        () => cp7a.active(
          result,
          cableOverride: manualCable(),
          groundOverride: cp7a.ground(phaseSize: 4),
        ),
        throwsArgumentError,
      );
      for (final field in ['cable', 'ground']) {
        final json = deep(aggregate.toJson());
        json[field] = field == 'cable'
            ? cp7a.cable(size: 6).toJson()
            : cp7a.ground(phaseSize: 4).toJson();
        expect(
          () => CircuitCalculationResult.fromJson(json),
          throwsArgumentError,
        );
      }
      final three = manualSelect(
        manualInput(three: true),
        cable: manualCable(three: true),
        phase: CircuitPhaseConfiguration.threePhase,
      );
      expect(
        () => cp7a.active(three, cableOverride: manualCable()),
        throwsArgumentError,
      );
    },
  );
  test(
    'SPARE and SPACE remain notCalculated; contradictory manual payload rejected',
    () {
      for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
        final selected = const ManualConduitSelector().select(
          circuitStatus: status,
          phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
          input: manualInput(),
          cable: manualCable(),
          ground: cp7a.ground(),
        );
        expect(selected.status, ConduitSelectionStatus.notCalculated);
        expect(selected.manualInput, isNull);
        final manual = manualSelect(manualInput());
        expect(() => cp7a.inactive(status, manual), throwsArgumentError);
        final json = cp7a.inactive(status, selected).toJson()
          ..['conduit'] = manual.toJson();
        expect(
          () => CircuitCalculationResult.fromJson(json),
          throwsArgumentError,
        );
      }
    },
  );
}

Map<String, Object?> deep(Map<String, Object?> j) =>
    Map<String, Object?>.from(jsonDecode(jsonEncode(j)) as Map);
Map<dynamic, dynamic> allocation(Map<String, Object?> j) =>
    (j['conduits'] as List).first as Map;
Map<dynamic, dynamic> source(Map<String, Object?> j) =>
    (j['sourceReferences'] as List).first as Map;
Map<dynamic, dynamic> physical(Map<String, Object?> j, [int i = 0]) =>
    (j['cables'] as List)[i] as Map;
Map<dynamic, dynamic> core(Map<String, Object?> j, [int i = 0]) =>
    (physical(j, i)['cores'] as List).first as Map;
Map<dynamic, dynamic> mapping(Map<String, Object?> j) =>
    (j['runMappings'] as List).first as Map;

ManualConduitSelectionInput manualInput({
  int runs = 1,
  bool multi = false,
  bool xlpe = false,
  bool three = false,
  bool split = false,
  bool shared = false,
}) {
  final cables = <ManualPhysicalCable>[];
  for (var run = 1; run <= runs; run++) {
    final cores = [
      for (final role in [
        PhysicalConductorRole.line1,
        if (three) ...[
          PhysicalConductorRole.line2,
          PhysicalConductorRole.line3,
        ],
        PhysicalConductorRole.neutral,
        PhysicalConductorRole.grounding,
      ])
        ManualCableCore(
          role: role,
          sizeSqmm: role == PhysicalConductorRole.grounding ? 2.5 : 4,
        ),
    ];
    if (multi) {
      cables.add(
        ManualPhysicalCable(
          id: 'cable-$run',
          run: run,
          identity: CableRoutingIdentity.nyy,
          coreType: CoreType.multiCore,
          insulation: CableInsulation.pvc,
          cores: cores,
        ),
      );
    } else {
      for (final core in cores) {
        cables.add(
          ManualPhysicalCable(
            id: '${core.role.name}-$run',
            run: run,
            identity: xlpe
                ? CableRoutingIdentity.iec605021
                : CableRoutingIdentity.iec01,
            coreType: CoreType.singleCore,
            insulation: xlpe ? CableInsulation.xlpe : CableInsulation.pvc,
            cores: [core],
          ),
        );
      }
    }
  }
  ManualConduitAllocation conduit(String id, List<String> ids) =>
      ManualConduitAllocation(
        id: id,
        type: ManualConduitType.emt,
        material: 'Engineer-entered steel',
        standardSpecification: 'Project specification M-01',
        nominalSizeMm: 25,
        cableIds: ids,
        sourceReferenceIds: ['source-1'],
      );
  final conduits = <ManualConduitAllocation>[];
  if (shared) {
    conduits.add(conduit('shared', cables.map((c) => c.id).toList()));
  } else {
    for (var r = 1; r <= runs; r++) {
      final ids = cables.where((c) => c.run == r).map((c) => c.id).toList();
      if (split) {
        conduits.add(conduit('main-$r', ids.take(ids.length - 1).toList()));
        conduits.add(conduit('pe-$r', [ids.last]));
      } else {
        conduits.add(conduit('c$r', ids));
      }
    }
  }
  return ManualConduitSelectionInput(
    phaseConfiguration: three
        ? CircuitPhaseConfiguration.threePhase
        : CircuitPhaseConfiguration.singlePhase,
    parallelRuns: runs,
    neutralPerRun: true,
    groundingPerRun: true,
    selectionReason: 'Engineer specified routing for mixed-size cable set.',
    selectedBy: 'engineer-001',
    checkedBy: 'checker-002',
    sourceReferences: [
      ManualConduitSourceReference(
        id: 'source-1',
        manufacturer: 'Test manufacturer',
        document: 'Engineering selection record',
        revision: 'R1',
        page: '12',
      ),
    ],
    cables: cables,
    conduits: conduits,
    runMappings: [
      for (var r = 1; r <= runs; r++)
        ManualConduitRunMapping(
          run: r,
          conduitCount: split ? 2 : 1,
          conduitIds: shared
              ? ['shared']
              : split
              ? ['main-$r', 'pe-$r']
              : ['c$r'],
        ),
    ],
  );
}

CableCoordinationResult manualCable({
  int runs = 1,
  bool multi = false,
  bool xlpe = false,
  bool three = false,
}) {
  final j = cp7a.cable(runs: runs, size: 4, three: three).toJson();
  if (multi) {
    j['identity'] = 'nyy';
    j['coreType'] = 'multiCore';
  }
  if (xlpe) {
    j['identity'] = 'iec605021';
    j['insulation'] = 'xlpe';
    j['conductorTemperatureClass'] = 'xlpeEpr90';
    j['tableId'] = '5-27';
  }
  return CableCoordinationResult.fromJson(j);
}

ConduitSelectionResult manualSelect(
  ManualConduitSelectionInput input, {
  CableCoordinationResult? cable,
  GroundingConductorSelectionResult? ground,
  CircuitPhaseConfiguration phase = CircuitPhaseConfiguration.singlePhase,
}) => const ManualConduitSelector().select(
  circuitStatus: CircuitStatus.active,
  phaseConfiguration: phase,
  cable: cable ?? manualCable(),
  ground: ground ?? cp7a.ground(),
  input: input,
);
