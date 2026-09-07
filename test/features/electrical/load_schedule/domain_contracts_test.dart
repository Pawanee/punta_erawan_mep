import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/load_schedule/load_schedule.dart';

void main() {
  Map<String, Object?> roundTrip(Map<String, Object?> json) =>
      Map<String, Object?>.from(jsonDecode(jsonEncode(json)) as Map);

  final activeManual = CircuitDefinition(
    circuitNo: 1,
    description: 'Lighting',
    status: CircuitStatus.active,
    loadInput: LoadInput.directVa(1200),
    phaseAssignmentMode: PhaseAssignmentMode.manual,
    phaseAssignment: PhaseAssignment.r,
  );
  final activeAutomatic = CircuitDefinition(
    circuitNo: 2,
    description: 'Socket outlets',
    status: CircuitStatus.active,
    loadInput: LoadInput.quantityTimesWatts(
      quantity: 10,
      wattsPerUnit: 180,
      powerFactor: 0.9,
    ),
    phaseAssignmentMode: PhaseAssignmentMode.automatic,
  );
  final spare = CircuitDefinition(
    circuitNo: 3,
    description: 'Spare',
    status: CircuitStatus.spare,
    phaseAssignmentMode: PhaseAssignmentMode.manual,
    phaseAssignment: PhaseAssignment.s,
    manualSpareCircuitBreaker: '20 A, 1P',
  );
  final space = CircuitDefinition(
    circuitNo: 4,
    description: 'Space',
    status: CircuitStatus.space,
    phaseAssignmentMode: PhaseAssignmentMode.automatic,
  );

  final panel = PanelDefinition(
    panelId: 'panel-1',
    panelNo: 'LP-1',
    projectName: 'Project',
    location: 'Floor 1',
    systemVoltageV: 415,
    frequencyHz: 50,
    enclosure: 'NEMA 1',
    mounting: 'Surface',
    door: 'Hinge',
    circuitCapacity: 6,
    mainCircuitBreaker: '100 A, 3P',
    feeder: '4x25,Gx10 IEC-01',
    demandFactor: 0.8,
    circuits: [activeManual, activeAutomatic, spare, space],
  );

  CalculationStepResult unresolved([String? reason]) => CalculationStepResult(
    status: reason == null
        ? CalculationStatus.notCalculated
        : CalculationStatus.insufficient,
    reason: reason,
  );

  CircuitCalculationResult activeResult(int circuitNo, PhaseAssignment phase) =>
      CircuitCalculationResult(
        circuitNo: circuitNo,
        circuitStatus: CircuitStatus.active,
        validationStatus: CircuitValidationStatus.valid,
        assignedPhase: phase,
        current: CalculationStepResult(
          status: CalculationStatus.calculated,
          values: const {'currentA': 5.0},
        ),
        cable: CalculationStepResult(
          status: CalculationStatus.calculated,
          values: const {'sizeSqmm': 2.5},
          sourceReferences: const [
            CalculationSourceReference(
              sourceId: 'ampacity-5-20',
              label: 'Table 5-20',
              tableId: '5-20',
              sourceVersion: 'fixture-v1',
            ),
          ],
        ),
        voltageDrop: unresolved('Circuit length is not supplied.'),
        circuitBreaker: const PendingEngineeringResult.notCalculated(
          reason: 'CB rules are not approved in CP1.',
        ),
        ground: const PendingEngineeringResult.notCalculated(
          reason: 'Ground rules are not approved in CP1.',
        ),
        conduit: const PendingEngineeringResult.notCalculated(
          reason: 'Conduit rules are not approved in CP1.',
        ),
      );

  CircuitCalculationResult emptyResult(int circuitNo, CircuitStatus status) =>
      CircuitCalculationResult(
        circuitNo: circuitNo,
        circuitStatus: status,
        validationStatus: CircuitValidationStatus.valid,
        current: unresolved(),
        cable: unresolved(),
        voltageDrop: unresolved(),
        circuitBreaker: const PendingEngineeringResult.notCalculated(),
        ground: const PendingEngineeringResult.notCalculated(),
        conduit: const PendingEngineeringResult.notCalculated(),
      );

  final snapshot = PanelCalculationSnapshot(
    snapshotId: 'snapshot-1-r1',
    panelDefinition: panel,
    revision: 1,
    schemaVersion: 'load-schedule-v1-cp1',
    engineVersion: 'd24d015',
    calculatedAt: DateTime.utc(2026, 9, 7),
    circuitResults: [
      activeResult(1, PhaseAssignment.r),
      activeResult(2, PhaseAssignment.s),
      emptyResult(3, CircuitStatus.spare),
      emptyResult(4, CircuitStatus.space),
    ],
    calculatedTotals: const {
      'connectedVaR': 1200,
      'connectedVaS': 2000,
      'connectedVaT': 0,
      'totalConnectedVa': 3200,
    },
  );

  test('LoadInput supports and round-trips exactly three approved forms', () {
    final inputs = [
      LoadInput.directVa(1500),
      LoadInput.directCurrentA(12.5),
      LoadInput.quantityTimesWatts(
        quantity: 8,
        wattsPerUnit: 40,
        powerFactor: 0.85,
      ),
    ];

    for (final input in inputs) {
      final restored = LoadInput.fromJson(roundTrip(input.toJson()));
      expect(restored.toJson(), input.toJson());
    }
  });

  test('all domain contracts round-trip through JSON', () {
    final panelRestored = PanelDefinition.fromJson(roundTrip(panel.toJson()));
    expect(panelRestored.toJson(), panel.toJson());

    final snapshotRestored = PanelCalculationSnapshot.fromJson(
      roundTrip(snapshot.toJson()),
    );
    expect(snapshotRestored.toJson(), snapshot.toJson());

    final projection = LoadScheduleExportProjection(
      snapshotId: snapshot.snapshotId,
      panelHeader: const {'panelNo': 'LP-1', 'voltageV': 415},
      columns: const ['circuitNo', 'phaseR', 'description'],
      rows: const [
        {'circuitNo': 1, 'phaseR': 1200, 'description': 'Lighting'},
      ],
      summary: const {'totalConnectedVa': 3200},
    );
    final projectionRestored = LoadScheduleExportProjection.fromJson(
      roundTrip(projection.toJson()),
    );
    expect(projectionRestored.toJson(), projection.toJson());
  });

  test('ACTIVE, SPARE, and SPACE invariants fail closed', () {
    expect(
      () => CircuitDefinition(
        circuitNo: 1,
        description: 'Missing load',
        status: CircuitStatus.active,
        phaseAssignmentMode: PhaseAssignmentMode.automatic,
      ),
      throwsArgumentError,
    );
    expect(
      () => CircuitDefinition(
        circuitNo: 2,
        description: 'Spare with load',
        status: CircuitStatus.spare,
        loadInput: LoadInput.directVa(1000),
        phaseAssignmentMode: PhaseAssignmentMode.automatic,
      ),
      throwsArgumentError,
    );
    expect(
      () => CircuitDefinition(
        circuitNo: 3,
        description: 'Space with equipment',
        status: CircuitStatus.space,
        phaseAssignmentMode: PhaseAssignmentMode.automatic,
        manualSpareCircuitBreaker: '20 A',
      ),
      throwsArgumentError,
    );
  });

  test('manual and automatic phase assignment are explicit', () {
    expect(activeManual.phaseAssignment, PhaseAssignment.r);
    expect(activeAutomatic.phaseAssignment, isNull);
    expect(
      () => CircuitDefinition(
        circuitNo: 5,
        description: 'Manual missing phase',
        status: CircuitStatus.active,
        loadInput: LoadInput.directCurrentA(10),
        phaseAssignmentMode: PhaseAssignmentMode.manual,
      ),
      throwsArgumentError,
    );
    expect(
      () => CircuitDefinition(
        circuitNo: 6,
        description: 'Automatic with phase',
        status: CircuitStatus.active,
        loadInput: LoadInput.directCurrentA(10),
        phaseAssignmentMode: PhaseAssignmentMode.automatic,
        phaseAssignment: PhaseAssignment.t,
      ),
      throwsArgumentError,
    );
  });

  test('odd and even circuit numbers coexist without hierarchy', () {
    expect(panel.circuits.map((circuit) => circuit.circuitNo), [1, 2, 3, 4]);
    expect(panel.toJson().containsKey('parentPanelId'), isFalse);
    expect(panel.toJson().containsKey('childPanels'), isFalse);
  });

  test('snapshot is immutable and revisioned', () {
    expect(snapshot.revision, 1);
    expect(
      () => snapshot.circuitResults.add(activeResult(5, PhaseAssignment.t)),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.calculatedTotals['totalConnectedVa'] = 0,
      throwsUnsupportedError,
    );
    expect(() => panel.circuits.clear(), throwsUnsupportedError);
  });

  test('PanelDefinition contains no calculated totals', () {
    final json = panel.toJson();
    expect(json.containsKey('calculatedTotals'), isFalse);
    expect(json.containsKey('connectedVaR'), isFalse);
    expect(json.containsKey('totalConnectedVa'), isFalse);
    expect(json.containsKey('demandLoadVa'), isFalse);
  });

  test('invalid or missing engineering inputs fail closed', () {
    expect(() => LoadInput.directVa(0), throwsArgumentError);
    expect(() => LoadInput.directCurrentA(-1), throwsArgumentError);
    expect(
      () => LoadInput.quantityTimesWatts(
        quantity: 1,
        wattsPerUnit: 100,
        powerFactor: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => CalculationStepResult(status: CalculationStatus.calculated),
      throwsArgumentError,
    );
    expect(
      () => CalculationStepResult(status: CalculationStatus.insufficient),
      throwsArgumentError,
    );
    expect(
      () => PendingEngineeringResult.insufficient(reason: ''),
      throwsArgumentError,
    );
    expect(
      () => PendingEngineeringResult.fromJson(const {'status': 'calculated'}),
      throwsA(anything),
    );
  });
}
