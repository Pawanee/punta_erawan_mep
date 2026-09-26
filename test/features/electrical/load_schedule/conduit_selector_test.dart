import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/load_schedule/load_schedule.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'load_schedule_cable_coordinator_test.dart' as cp4;

// Independently frozen source golden: approved C1, printed page 259.
// -1 = printed dash; -2 = empty cell. No capacities are inferred.
const sizes = <double>[
  1.5,
  2.5,
  4,
  6,
  10,
  16,
  25,
  35,
  50,
  70,
  95,
  120,
  150,
  185,
  240,
  300,
  400,
];
const columns = [15, 20, 25, 32, 40, 50, 65, 80, 90, 100, 125, 150];
const golden = <List<int>>[
  [8, 14, 22, 37, -1, -1, -1, -1, -1, -1, -1, -1],
  [5, 10, 15, 25, -2, -1, -1, -1, -1, -1, -1, -1],
  [4, 7, 11, 19, 30, -1, -1, -1, -1, -1, -1, -1],
  [3, 5, 9, 15, 23, 37, -1, -1, -1, -1, -1, -1],
  [1, 3, 5, 9, 14, 22, -2, -1, -1, -1, -1, -1],
  [1, 2, 4, 6, 10, 16, 27, 42, -1, -1, -1, -1],
  [1, 2, 2, 4, 6, 10, 17, 27, 34, -1, -1, -1],
  [1, 1, 2, 3, 5, 8, 14, 21, 27, 33, -2, -2],
  [-1, 1, 1, 1, 3, 6, 10, 15, 19, 24, 38, -2],
  [-1, -1, 1, 1, 3, 4, 7, 12, 15, 18, 29, 42],
  [-1, -1, 1, 1, 1, 3, 5, 8, 11, 13, 21, 30],
  [-1, -1, -1, 1, 1, 2, 4, 7, 9, 11, 17, 25],
  [-1, -1, -1, 1, 1, 1, 3, 5, 7, 9, 14, 20],
  [-1, -1, -1, 1, 1, 1, 3, 4, 6, 7, 11, 16],
  [-1, -1, -1, -1, 1, 1, 1, 3, 4, 5, 8, 12],
  [-1, -1, -1, -1, -1, 1, 1, 2, 3, 4, 7, 10],
  [-1, -1, -1, -1, -1, 1, 1, 1, 2, 3, 5, 8],
];

void main() {
  const repository = TableC1Repository();
  test('source metadata, all 204 cells, units and immutable repository', () {
    expect(TableC1Repository.tableId, 'C1');
    expect(TableC1Repository.version, 'table-c1-v1');
    expect(
      TableC1Repository.title,
      'ตารางที่ C1 จำนวนสายไฟฟ้าขนาดเดียวกันในท่อร้อยสาย สำหรับสายไฟฟ้าตาม มอก. 11-2553 รหัสชนิด 60227 IEC 01',
    );
    expect(
      TableC1Repository.documentTitle,
      'คู่มือการติดตั้งระบบไฟฟ้าอย่างมืออาชีพ',
    );
    expect(TableC1Repository.page, 259);
    expect(TableC1Repository.cableStandard, 'มอก. 11-2553');
    expect(TableC1Repository.cableCode, '60227 IEC 01');
    expect(
      TableC1Repository.source,
      'มาตรฐานการติดตั้งทางไฟฟ้าสำหรับประเทศไทย พ.ศ.2564 ภาคผนวก ฎ',
    );
    expect(
      TableC1Repository.sourceSha256,
      '52ac8423e4a8541e3e2a2fb3d7cb008b4d716d8cd72953f7c6805a616f118558',
    );
    expect(TableC1Repository.rows.length, 17);
    expect(TableC1Repository.columns.map((c) => c.nominalMm), columns);
    expect(TableC1Repository.columns.map((c) => c.inchLabel), [
      '1/2',
      '3/4',
      '1',
      '1 1/4',
      '1 1/2',
      '2',
      '2 1/2',
      '3',
      '3 1/2',
      '4',
      '5',
      '6',
    ]);
    var cells = 0;
    for (var r = 0; r < sizes.length; r++) {
      final row = TableC1Repository.rows[r];
      expect(row.conductorSizeSqmm, sizes[r]);
      expect(row.cells.length, 12);
      for (var c = 0; c < 12; c++) {
        final expected = golden[r][c];
        expect(
          row.cells[c].status,
          expected > 0
              ? TableC1CellStatus.publishedCapacity
              : expected == -1
              ? TableC1CellStatus.dash
              : TableC1CellStatus.blank,
        );
        expect(row.cells[c].capacity, expected > 0 ? expected : null);
        cells++;
      }
    }
    expect(cells, 204);
    expect(() => TableC1Repository.rows.clear(), throwsUnsupportedError);
    expect(
      () => TableC1Repository.rows.first.cells.clear(),
      throwsUnsupportedError,
    );
    expect(() => TableC1Repository.columns.clear(), throwsUnsupportedError);
  });
  for (var r = 0; r < sizes.length; r++) {
    test('all numeric boundaries and capacity+1 at ${sizes[r]}', () {
      for (final capacity in golden[r].where((n) => n > 0)) {
        for (final count in [capacity, capacity + 1]) {
          final expectedColumn = golden[r].indexWhere((n) => n >= count);
          final actual = repository.select(sizes[r], count);
          if (expectedColumn < 0) {
            expect(actual, isNull);
          } else {
            expect(actual!.column.nominalMm, columns[expectedColumn]);
            expect(actual.capacity, golden[r][expectedColumn]);
            expect(actual.requestedCount, count);
          }
        }
      }
    });
    test('no dash/blank extrapolation at ${sizes[r]}', () {
      for (var count = 1; count <= 50; count++) {
        final actual = repository.select(sizes[r], count);
        final expectedColumn = golden[r].indexWhere((n) => n >= count);
        expect(
          actual?.column.nominalMm,
          expectedColumn < 0 ? null : columns[expectedColumn],
        );
      }
      expect(repository.select(sizes[r], 100), isNull);
    });
  }
  test('missing and between-size rows are never rounded', () {
    for (final size in [0.5, 2.0, 2.500001, 500.0]) {
      expect(repository.select(size, 1), isNull);
    }
    for (final size in [0.0, -1.0, double.nan, double.infinity]) {
      expect(() => repository.select(size, 1), throwsArgumentError);
    }
    expect(() => repository.select(2.5, 0), throwsArgumentError);
  });
  test('physical L N PE count is three, not CP4 loadedConductors two', () {
    final result = select(input());
    expect(result.status, ConduitSelectionStatus.selected);
    expect(result.selections.single.requestedCount, 3);
    expect(result.selections.single.nominalSizeMm, 15);
    expect(result.selections.single.publishedCapacity, 5);
    expect(result.toJson()['label'], 'Table C1 nominal conduit size');
    expect(result.toJson()['materialScope'], contains('not certified'));
  });
  test('explicit neutral and ground presence control physical count', () {
    for (final n in [false, true]) {
      for (final pe in [false, true]) {
        final result = select(input(neutral: n, grounding: pe));
        expect(
          result.selections.single.requestedCount,
          1 + (n ? 1 : 0) + (pe ? 1 : 0),
        );
      }
    }
  });
  test('three phases plus neutral and ground count five', () {
    final result = select(input(three: true), cable: cable(three: true));
    expect(result.status, ConduitSelectionStatus.selected);
    expect(result.selections.single.requestedCount, 5);
  });
  test(
    'one conduit per parallel run without multiplying count per conduit',
    () {
      final result = select(input(runs: 3), cable: cable(runs: 3));
      expect(result.status, ConduitSelectionStatus.selected);
      expect(result.conduitCount, 3);
      expect(result.selections.map((s) => s.requestedCount), [3, 3, 3]);
      expect(result.selections.map((s) => s.run), [1, 2, 3]);
    },
  );
  test('shared and multiple runs in one conduit unsupported', () {
    for (final value in [input(shared: true), input(runs: 2, combined: true)]) {
      expect(select(value).status, ConduitSelectionStatus.unsupported);
      expect(
        () => ConduitSelectionResult.selected(
          input: value,
          cable: cable(),
          ground: ground(),
        ),
        throwsArgumentError,
      );
    }
  });
  test(
    'mixed sizes, missing row, every non IEC01 identity and multicore unsupported',
    () {
      final mixed = input().toJson();
      wireJson(mixed, 2)['sizeSqmm'] = 4;
      expect(
        select(ConduitSelectionInput.fromJson(mixed)).status,
        ConduitSelectionStatus.unsupported,
      );
      expect(select(input(size: 2)).status, ConduitSelectionStatus.unsupported);
      for (final identity in CableRoutingIdentity.values.where(
        (id) => id != CableRoutingIdentity.iec01,
      )) {
        expect(
          select(input(identity: identity)).status,
          ConduitSelectionStatus.unsupported,
        );
      }
      expect(
        select(input(core: CoreType.multiCore)).status,
        ConduitSelectionStatus.unsupported,
      );
      expect(
        select(input(insulation: CableInsulation.xlpe)).status,
        ConduitSelectionStatus.unsupported,
      );
    },
  );
  test(
    'missing, duplicate wires/roles/conduits and missing runs fail at input',
    () {
      final mutations = <void Function(Map<String, Object?>)>[
        (j) => wiresJson(j).removeLast(),
        (j) => wireJson(j, 1)['id'] = wireJson(j, 0)['id'],
        (j) => wireJson(j, 1)['role'] = 'line1',
        (j) => wireJson(j, 0)['run'] = 2,
        (j) => j['parallelRuns'] = 2,
        (j) => j['conduits'] = [],
        (j) => (j['conduits'] as List).add((j['conduits'] as List).first),
        (j) => j['neutralPerRun'] = false,
        (j) => j['groundingPerRun'] = false,
        (j) => j['phaseConfiguration'] = 'threePhase',
      ];
      for (final mutate in mutations) {
        final json = deep(input().toJson());
        mutate(json);
        expect(() => ConduitSelectionInput.fromJson(json), throwsA(anything));
      }
      final original = input();
      expect(
        () => ConduitSelectionInput(
          phaseConfiguration: original.phaseConfiguration,
          parallelRuns: 1,
          neutralPerRun: true,
          groundingPerRun: true,
          conduits: [
            PhysicalConduit(
              id: 'c1',
              shared: false,
              runs: [1],
              conductors: original.conduits.single.conductors.take(2).toList(),
            ),
          ],
        ),
        throwsArgumentError,
      );
    },
  );
  test('strict input enums, numeric values and unknown keys', () {
    for (final mutation in <void Function(Map<String, Object?>)>[
      (j) => wireJson(j, 0)['coreType'] = 'unknown',
      (j) => wireJson(j, 0)['role'] = 'unknown',
      (j) => wireJson(j, 0)['identity'] = 'unknown',
      (j) => wireJson(j, 0)['sizeSqmm'] = double.nan,
      (j) => wireJson(j, 0)['sizeSqmm'] = double.infinity,
      (j) => wireJson(j, 0)['sizeSqmm'] = 0,
      (j) => wireJson(j, 0)['sizeSqmm'] = -1,
      (j) => wireJson(j, 0)['run'] = 1.5,
      (j) => j['parallelRuns'] = 0,
      (j) => j['loadedConductors'] = 3,
      (j) => j.remove('neutralPerRun'),
    ]) {
      final json = deep(input().toJson());
      mutation(json);
      expect(() => ConduitSelectionInput.fromJson(json), throwsA(anything));
    }
  });
  test('selector ACTIVE missing input and snapshots fail closed', () {
    expect(
      const ConduitSelector()
          .select(
            circuitStatus: CircuitStatus.active,
            cable: cable(),
            ground: ground(),
          )
          .status,
      ConduitSelectionStatus.insufficient,
    );
    expect(
      select(input(), cable: CableCoordinationResult.notCalculated()).status,
      ConduitSelectionStatus.insufficient,
    );
    expect(
      select(
        input(),
        grounding: GroundingConductorSelectionResult.notCalculated(),
      ).status,
      ConduitSelectionStatus.insufficient,
    );
  });
  test(
    'CP4 run/size and CP6 grounding/phase snapshot mismatches fail closed',
    () {
      expect(
        select(input(), cable: cable(runs: 2)).status,
        ConduitSelectionStatus.invalid,
      );
      expect(
        select(input(), cable: cable(size: 4)).status,
        ConduitSelectionStatus.invalid,
      );
      expect(
        select(input(), grounding: ground(rating: 40)).status,
        ConduitSelectionStatus.invalid,
      );
      expect(
        select(input(), grounding: ground(phaseSize: 4)).status,
        ConduitSelectionStatus.invalid,
      );
      for (final snapshot in [cable(runs: 2), cable(size: 4)]) {
        expect(
          () => ConduitSelectionResult.selected(
            input: input(),
            cable: snapshot,
            ground: ground(),
          ),
          throwsArgumentError,
        );
      }
    },
  );
  test(
    'SPARE/SPACE selector ignores engineering input and remains notCalculated',
    () {
      for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
        expect(
          const ConduitSelector()
              .select(
                circuitStatus: status,
                input: input(),
                cable: cable(),
                ground: ground(),
              )
              .status,
          ConduitSelectionStatus.notCalculated,
        );
      }
    },
  );
  test('input and result JSON round trips preserve traceability', () {
    final value = input(runs: 2);
    expect(
      ConduitSelectionInput.fromJson(deep(value.toJson())).toJson(),
      value.toJson(),
    );
    final result = select(value, cable: cable(runs: 2));
    final copy = ConduitSelectionResult.fromJson(deep(result.toJson()));
    expect(copy.toJson(), result.toJson());
    for (final selection in copy.selections) {
      final json = selection.toJson();
      expect(json['tableId'], 'C1');
      expect(json['tableVersion'], 'table-c1-v1');
      expect(json['conductorRow'], 'conductorSqmm:2.5');
      expect(json['conduitColumn'], 'nominalMm:15');
      expect(json['requestedCount'], 3);
      expect(json['publishedCapacity'], 5);
    }
    expect(() => copy.selections.clear(), throwsUnsupportedError);
    expect(() => value.conduits.clear(), throwsUnsupportedError);
    final reversed = Map<String, Object?>.fromEntries(
      result.toJson().entries.toList().reversed,
    );
    expect(ConduitSelectionResult.fromJson(reversed).toJson(), result.toJson());
  });
  test(
    'contradictory selected JSON rejects altered cell, count, metadata and input',
    () {
      for (final mutate in <void Function(Map<String, Object?>)>[
        (j) => selectedJson(j)['requestedCount'] = 2,
        (j) => selectedJson(j)['publishedCapacity'] = 10,
        (j) => selectedJson(j)['nominalSizeMm'] = 20,
        (j) => selectedJson(j)['conduitColumn'] = 'nominalMm:20',
        (j) => selectedJson(j)['conductorRow'] = 'conductorSqmm:4.0',
        (j) => selectedJson(j)['tableVersion'] = 'wrong',
        (j) => selectedJson(j)['tableId'] = 'wrong',
        (j) => selectedJson(j)['run'] = 2,
        (j) => j['conduitCount'] = 2,
        (j) => j['materialScope'] = 'EMT approved',
        (j) => j['label'] = 'EMT size',
        (j) => j['sourceSha256'] = 'wrong',
        (j) => j['reason'] = 'contradiction',
        (j) => j['extra'] = true,
        (j) => (j['input'] as Map)['parallelRuns'] = 2,
        (j) => (j['cableSnapshot'] as Map)['sizeSqmm'] = 4,
      ]) {
        final json = deep(select(input()).toJson());
        mutate(json);
        expect(() => ConduitSelectionResult.fromJson(json), throwsA(anything));
      }
    },
  );
  test(
    'unresolved JSON requires reasons and forbids selected fields even null',
    () {
      for (final value in [
        ConduitSelectionResult.notCalculated(),
        ConduitSelectionResult.insufficient(reason: 'missing'),
        ConduitSelectionResult.invalid(reason: 'invalid'),
        ConduitSelectionResult.unsupported(reason: 'unsupported'),
      ]) {
        expect(
          ConduitSelectionResult.fromJson(value.toJson()).toJson(),
          value.toJson(),
        );
        final json = value.toJson()..['selections'] = null;
        expect(
          () => ConduitSelectionResult.fromJson(json),
          throwsArgumentError,
        );
      }
      for (final status in ['insufficient', 'invalid', 'unsupported']) {
        for (final reason in [null, '', ' ']) {
          expect(
            () => ConduitSelectionResult.fromJson({
              'status': status,
              'reason': reason,
            }),
            throwsA(anything),
          );
        }
      }
      expect(
        () => ConduitSelectionResult.invalid(reason: ''),
        throwsArgumentError,
      );
    },
  );
  test(
    'aggregate selected roundtrip and CP4 CP6 phase constructor/JSON parity',
    () {
      final result = select(input());
      final aggregate = active(result);
      expect(
        CircuitCalculationResult.fromJson(deep(aggregate.toJson())).toJson(),
        aggregate.toJson(),
      );
      expect(
        () => active(result, cableOverride: cable(size: 4)),
        throwsArgumentError,
      );
      expect(
        () => active(result, groundOverride: ground(phaseSize: 2.5)),
        throwsArgumentError,
      );
      final three = select(input(three: true), cable: cable(three: true));
      expect(() => active(three), throwsArgumentError);
      for (final field in ['cable', 'ground']) {
        final json = deep(aggregate.toJson());
        json[field] = field == 'cable'
            ? cable(size: 4).toJson()
            : ground(phaseSize: 2.5).toJson();
        expect(
          () => CircuitCalculationResult.fromJson(json),
          throwsArgumentError,
        );
      }
    },
  );
  test(
    'SPARE SPACE aggregate rejects any unresolved or selected conduit other than notCalculated',
    () {
      for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
        final valid = inactive(status, ConduitSelectionResult.notCalculated());
        expect(
          CircuitCalculationResult.fromJson(deep(valid.toJson())).toJson(),
          valid.toJson(),
        );
        for (final conduit in [
          select(input()),
          ConduitSelectionResult.insufficient(reason: 'missing'),
          ConduitSelectionResult.invalid(reason: 'bad'),
          ConduitSelectionResult.unsupported(reason: 'out'),
        ]) {
          expect(() => inactive(status, conduit), throwsArgumentError);
          final json = deep(valid.toJson())..['conduit'] = conduit.toJson();
          expect(
            () => CircuitCalculationResult.fromJson(json),
            throwsArgumentError,
          );
        }
      }
    },
  );
}

Map<String, Object?> deep(Map<String, Object?> json) =>
    Map<String, Object?>.from(jsonDecode(jsonEncode(json)) as Map);
List<dynamic> wiresJson(Map<String, Object?> j) =>
    ((j['conduits'] as List).first as Map)['conductors'] as List;
Map<dynamic, dynamic> wireJson(Map<String, Object?> j, int index) =>
    wiresJson(j)[index] as Map;
Map<dynamic, dynamic> selectedJson(Map<String, Object?> j) =>
    (j['selections'] as List).first as Map;

ConduitSelectionInput input({
  int runs = 1,
  bool neutral = true,
  bool grounding = true,
  bool three = false,
  bool shared = false,
  bool combined = false,
  double size = 2.5,
  CableRoutingIdentity identity = CableRoutingIdentity.iec01,
  CoreType core = CoreType.singleCore,
  CableInsulation insulation = CableInsulation.pvc,
}) {
  List<PhysicalConductor> wires(int run) => [
    for (final role in [
      PhysicalConductorRole.line1,
      if (three) ...[PhysicalConductorRole.line2, PhysicalConductorRole.line3],
      if (neutral) PhysicalConductorRole.neutral,
      if (grounding) PhysicalConductorRole.grounding,
    ])
      PhysicalConductor(
        id: '$run-${role.name}',
        run: run,
        role: role,
        identity: identity,
        coreType: core,
        insulation: insulation,
        sizeSqmm: size,
      ),
  ];
  return ConduitSelectionInput(
    phaseConfiguration: three
        ? CircuitPhaseConfiguration.threePhase
        : CircuitPhaseConfiguration.singlePhase,
    parallelRuns: runs,
    neutralPerRun: neutral,
    groundingPerRun: grounding,
    conduits: combined
        ? [
            PhysicalConduit(
              id: 'all',
              shared: shared,
              runs: List.generate(runs, (i) => i + 1),
              conductors: [for (var r = 1; r <= runs; r++) ...wires(r)],
            ),
          ]
        : [
            for (var r = 1; r <= runs; r++)
              PhysicalConduit(
                id: 'c$r',
                shared: shared,
                runs: [r],
                conductors: wires(r),
              ),
          ],
  );
}

CableCoordinationResult cable({
  int runs = 1,
  double size = 2.5,
  bool three = false,
}) {
  final json = cp4.coordinatedCable().toJson();
  json['runs'] = runs;
  json['sizeSqmm'] = size;
  json['loadedConductors'] = three ? 3 : 2;
  json['totalCorrectedCapacityIzA'] = 20.0 * runs;
  return CableCoordinationResult.fromJson(json);
}

GroundingConductorSelectionResult ground({
  double rating = 16,
  double? phaseSize,
}) => GroundingConductorSelectionResult.selected(
  basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
  ratedCurrentA: rating,
  protectiveDeviceValueA: rating,
  selectedTableThresholdA: rating <= 20 ? 20 : 40,
  groundingConductorSizeSqmm: rating <= 20 ? 2.5 : 4,
  phaseConductorSizeSqmm: phaseSize,
  sourceReferences: [
    CalculationSourceReference(
      sourceId: 'table-4-2-page-113',
      label: 'Ground',
      tableId: '4-2',
      rowId: rating <= 20
          ? 'protectiveDeviceThresholdA:20.0'
          : 'protectiveDeviceThresholdA:40.0',
      sourceVersion: 'table-4-2-v1',
    ),
  ],
);
ConduitSelectionResult select(
  ConduitSelectionInput value, {
  CableCoordinationResult? cable,
  GroundingConductorSelectionResult? grounding,
}) => const ConduitSelector().select(
  circuitStatus: CircuitStatus.active,
  input: value,
  cable: cable ?? cp4.coordinatedCable(),
  ground: grounding ?? ground(),
);
CircuitCalculationResult active(
  ConduitSelectionResult conduit, {
  CableCoordinationResult? cableOverride,
  GroundingConductorSelectionResult? groundOverride,
}) {
  final breakerJson = cp4.selectedBreaker().toJson()
    ..['cableCoordinationStatus'] = 'coordinated';
  return CircuitCalculationResult(
    circuitNo: 1,
    circuitStatus: CircuitStatus.active,
    phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
    validationStatus: CircuitValidationStatus.valid,
    assignedPhase: PhaseAssignment.r,
    current: cp4.calculatedCurrent(),
    cable: cableOverride ?? cable(),
    circuitBreaker: CircuitBreakerSelectionResult.fromJson(breakerJson),
    ground: groundOverride ?? ground(),
    voltageDrop: VoltageDropCalculationResult.notCalculated(),
    conduit: conduit,
  );
}

CircuitCalculationResult inactive(
  CircuitStatus status,
  ConduitSelectionResult conduit,
) => CircuitCalculationResult(
  circuitNo: 2,
  circuitStatus: status,
  phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
  validationStatus: CircuitValidationStatus.valid,
  assignedPhase: status == CircuitStatus.spare ? PhaseAssignment.r : null,
  current: CurrentCalculationResult.notCalculated(),
  cable: CableCoordinationResult.notCalculated(),
  circuitBreaker: CircuitBreakerSelectionResult.notCalculated(),
  ground: GroundingConductorSelectionResult.notCalculated(),
  voltageDrop: VoltageDropCalculationResult.notCalculated(),
  conduit: conduit,
);
