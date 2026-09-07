import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/load_schedule/load_schedule.dart';

void main() {
  Map<String, Object?> roundTrip(Map<String, Object?> json) =>
      Map<String, Object?>.from(jsonDecode(jsonEncode(json)) as Map);

  final electricalSystem = PanelElectricalSystem(
    phaseSystem: PanelPhaseSystem.threePhase,
    lineToNeutralVoltageV: 230,
    lineToLineVoltageV: 400,
    frequencyHz: 50,
  );
  final activeManual = CircuitDefinition(
    circuitNo: 1,
    description: 'Lighting',
    status: CircuitStatus.active,
    phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
    loadInput: LoadInput.directVa(1200),
    phaseAssignmentMode: PhaseAssignmentMode.manual,
    phaseAssignment: PhaseAssignment.r,
  );
  final activeAutomatic = CircuitDefinition(
    circuitNo: 2,
    description: 'Socket outlets',
    status: CircuitStatus.active,
    phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
    loadInput: LoadInput.quantityTimesWatts(
      quantity: 10,
      wattsPerUnit: 180,
      powerFactor: 0.9,
    ),
    phaseAssignmentMode: PhaseAssignmentMode.automatic,
  );
  final activeThreePhase = CircuitDefinition(
    circuitNo: 3,
    description: 'Three-phase load',
    status: CircuitStatus.active,
    phaseConfiguration: CircuitPhaseConfiguration.threePhase,
    loadInput: LoadInput.directCurrentA(10),
    phaseAssignmentMode: PhaseAssignmentMode.automatic,
    phaseAssignment: PhaseAssignment.rst,
  );
  final spare = CircuitDefinition(
    circuitNo: 4,
    description: 'Spare',
    status: CircuitStatus.spare,
    phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
    phaseAssignmentMode: PhaseAssignmentMode.automatic,
  );
  final space = CircuitDefinition(
    circuitNo: 5,
    description: 'Space',
    status: CircuitStatus.space,
    phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
    phaseAssignmentMode: PhaseAssignmentMode.automatic,
  );

  final panel = PanelDefinition(
    panelId: 'panel-1',
    panelNo: 'LP-1',
    electricalSystem: electricalSystem,
    projectName: 'Project',
    location: 'Floor 1',
    enclosure: 'NEMA 1',
    mounting: 'Surface',
    door: 'Hinge',
    circuitCapacity: 6,
    mainCircuitBreaker: '100 A, 3P',
    feeder: '4x25,Gx10 IEC-01',
    demandFactor: 0.8,
    circuits: [activeManual, activeAutomatic, activeThreePhase, spare, space],
  );

  CalculationStepResult unresolved([String? reason]) => CalculationStepResult(
    status: reason == null
        ? CalculationStatus.notCalculated
        : CalculationStatus.insufficient,
    reason: reason,
  );

  CircuitCalculationResult result({
    required int circuitNo,
    required CircuitStatus status,
    required CircuitPhaseConfiguration configuration,
    PhaseAssignment? phase,
  }) => CircuitCalculationResult(
    circuitNo: circuitNo,
    circuitStatus: status,
    phaseConfiguration: configuration,
    validationStatus: CircuitValidationStatus.valid,
    assignedPhase: phase,
    current: status == CircuitStatus.active
        ? CurrentCalculationResult.calculated(
            designCurrentA:
                configuration == CircuitPhaseConfiguration.singlePhase
                ? 1200 / 230
                : 1200 / (math.sqrt(3) * 400),
            apparentPowerVa: 1200,
            voltageBasis: configuration == CircuitPhaseConfiguration.singlePhase
                ? VoltageBasis.lineToNeutral
                : VoltageBasis.lineToLine,
            voltageUsedV: configuration == CircuitPhaseConfiguration.singlePhase
                ? 230
                : 400,
            formulaId: configuration == CircuitPhaseConfiguration.singlePhase
                ? CurrentFormulaId.directVaSinglePhase
                : CurrentFormulaId.directVaThreePhase,
            sourceReferences: const [
              CalculationSourceReference(
                sourceId: 'current-formula',
                label: 'CP2 current formula',
              ),
            ],
          )
        : CurrentCalculationResult.notCalculated(),
    cable: unresolved(),
    voltageDrop: unresolved('Circuit length is not supplied.'),
    circuitBreaker: CircuitBreakerSelectionResult.notCalculated(
      reason: 'CB selection has not been requested.',
    ),
    ground: const PendingEngineeringResult.notCalculated(
      reason: 'Ground rules are not approved in CP1.',
    ),
    conduit: const PendingEngineeringResult.notCalculated(
      reason: 'Conduit rules are not approved in CP1.',
    ),
  );

  final totals = PanelCalculatedTotals(
    connectedVaR: 1200,
    connectedVaS: 2000,
    connectedVaT: 0,
    totalConnectedVa: 3200,
  );
  final snapshot = PanelCalculationSnapshot(
    snapshotId: 'snapshot-1-r1',
    panelDefinition: panel,
    revision: 1,
    schemaVersion: 'load-schedule-v1-cp2-current-v1',
    engineVersion: 'd24d015',
    calculatedAt: DateTime.utc(2026, 9, 7),
    circuitResults: [
      result(
        circuitNo: 1,
        status: CircuitStatus.active,
        configuration: CircuitPhaseConfiguration.singlePhase,
        phase: PhaseAssignment.r,
      ),
      result(
        circuitNo: 2,
        status: CircuitStatus.active,
        configuration: CircuitPhaseConfiguration.singlePhase,
        phase: PhaseAssignment.s,
      ),
      result(
        circuitNo: 3,
        status: CircuitStatus.active,
        configuration: CircuitPhaseConfiguration.threePhase,
        phase: PhaseAssignment.rst,
      ),
      result(
        circuitNo: 4,
        status: CircuitStatus.spare,
        configuration: CircuitPhaseConfiguration.singlePhase,
      ),
      result(
        circuitNo: 5,
        status: CircuitStatus.space,
        configuration: CircuitPhaseConfiguration.singlePhase,
      ),
    ],
    calculatedTotals: totals,
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
      expect(
        LoadInput.fromJson(roundTrip(input.toJson())).toJson(),
        input.toJson(),
      );
    }
  });

  test('typed panel electrical system round-trips without defaults', () {
    expect(
      PanelElectricalSystem.fromJson(
        roundTrip(electricalSystem.toJson()),
      ).toJson(),
      electricalSystem.toJson(),
    );
    for (final missingKey in [
      'phaseSystem',
      'lineToNeutralVoltageV',
      'lineToLineVoltageV',
      'frequencyHz',
    ]) {
      final json = Map<String, Object?>.from(electricalSystem.toJson())
        ..remove(missingKey);
      expect(() => PanelElectricalSystem.fromJson(json), throwsA(anything));
    }
  });

  test('all aggregate and typed export contracts round-trip through JSON', () {
    expect(
      PanelDefinition.fromJson(roundTrip(panel.toJson())).toJson(),
      panel.toJson(),
    );
    expect(
      PanelCalculationSnapshot.fromJson(roundTrip(snapshot.toJson())).toJson(),
      snapshot.toJson(),
    );
    final projection = LoadScheduleExportProjection(
      snapshotId: snapshot.snapshotId,
      header: LoadScheduleExportHeader(
        panelId: panel.panelId,
        panelNo: panel.panelNo,
        electricalSystem: electricalSystem,
        projectName: panel.projectName,
        location: panel.location,
      ),
      rows: [
        LoadScheduleExportRow(
          circuitNo: 1,
          description: 'Lighting',
          status: CircuitStatus.active,
          phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
          assignedPhase: PhaseAssignment.r,
          loadInput: LoadInput.directVa(1200),
        ),
      ],
      summary: LoadScheduleExportSummary(calculatedTotals: totals),
    );
    expect(
      LoadScheduleExportProjection.fromJson(
        roundTrip(projection.toJson()),
      ).toJson(),
      projection.toJson(),
    );
  });

  test('ACTIVE, SPARE, and SPACE invariants fail closed', () {
    expect(
      () => CircuitDefinition(
        circuitNo: 1,
        description: 'Missing load',
        status: CircuitStatus.active,
        phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
        phaseAssignmentMode: PhaseAssignmentMode.automatic,
      ),
      throwsArgumentError,
    );
    for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
      expect(
        () => CircuitDefinition(
          circuitNo: 2,
          description: 'Non-active with load',
          status: status,
          phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
          loadInput: LoadInput.directVa(1000),
          phaseAssignmentMode: PhaseAssignmentMode.automatic,
        ),
        throwsArgumentError,
      );
    }
    expect(spare.toJson().containsKey('manualSpareCircuitBreaker'), isFalse);
  });

  test('single-phase manual and automatic assignments are constrained', () {
    expect(activeManual.phaseAssignment, PhaseAssignment.r);
    expect(activeAutomatic.phaseAssignment, isNull);
    expect(
      () => CircuitDefinition(
        circuitNo: 6,
        description: 'Manual missing phase',
        status: CircuitStatus.active,
        phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
        loadInput: LoadInput.directCurrentA(10),
        phaseAssignmentMode: PhaseAssignmentMode.manual,
      ),
      throwsArgumentError,
    );
    expect(
      () => CircuitDefinition(
        circuitNo: 7,
        description: 'Automatic assigned phase',
        status: CircuitStatus.active,
        phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
        loadInput: LoadInput.directCurrentA(10),
        phaseAssignmentMode: PhaseAssignmentMode.automatic,
        phaseAssignment: PhaseAssignment.t,
      ),
      throwsArgumentError,
    );
  });

  test('three-phase circuits and results remain RST', () {
    expect(activeThreePhase.phaseAssignment, PhaseAssignment.rst);
    expect(
      () => CircuitDefinition(
        circuitNo: 8,
        description: 'Invalid three-phase assignment',
        status: CircuitStatus.active,
        phaseConfiguration: CircuitPhaseConfiguration.threePhase,
        loadInput: LoadInput.directCurrentA(10),
        phaseAssignmentMode: PhaseAssignmentMode.manual,
        phaseAssignment: PhaseAssignment.r,
      ),
      throwsArgumentError,
    );
    expect(
      () => result(
        circuitNo: 8,
        status: CircuitStatus.active,
        configuration: CircuitPhaseConfiguration.threePhase,
        phase: PhaseAssignment.s,
      ),
      throwsArgumentError,
    );
    expect(
      () => CircuitDefinition(
        circuitNo: 9,
        description: 'Single-phase RST',
        status: CircuitStatus.active,
        phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
        loadInput: LoadInput.directVa(1000),
        phaseAssignmentMode: PhaseAssignmentMode.manual,
        phaseAssignment: PhaseAssignment.rst,
      ),
      throwsArgumentError,
    );
  });

  test('snapshot is immutable, revisioned, and uses typed totals', () {
    expect(snapshot.revision, 1);
    expect(snapshot.calculatedTotals, isA<PanelCalculatedTotals>());
    expect(
      () => snapshot.circuitResults.add(
        result(
          circuitNo: 6,
          status: CircuitStatus.active,
          configuration: CircuitPhaseConfiguration.singlePhase,
          phase: PhaseAssignment.t,
        ),
      ),
      throwsUnsupportedError,
    );
    expect(() => panel.circuits.clear(), throwsUnsupportedError);
  });

  test('PanelDefinition has typed system and no calculated totals', () {
    final json = panel.toJson();
    expect(json['electricalSystem'], isA<Map<String, Object?>>());
    expect(json.containsKey('systemVoltageV'), isFalse);
    expect(json.containsKey('frequencyHz'), isFalse);
    expect(json.containsKey('calculatedTotals'), isFalse);
    expect(json.containsKey('totalConnectedVa'), isFalse);
  });

  test('single-phase panel rejects a three-phase circuit', () {
    expect(
      () => PanelDefinition(
        panelId: 'single-phase-panel',
        panelNo: 'LP-1PH',
        electricalSystem: PanelElectricalSystem(
          phaseSystem: PanelPhaseSystem.singlePhase,
          lineToNeutralVoltageV: 230,
          lineToLineVoltageV: 230,
          frequencyHz: 50,
        ),
        circuits: [activeThreePhase],
      ),
      throwsArgumentError,
    );
  });

  test('panel totals reject a mismatched phase sum', () {
    expect(
      () => PanelCalculatedTotals(
        connectedVaR: 100,
        connectedVaS: 200,
        connectedVaT: 300,
        totalConnectedVa: 601,
      ),
      throwsArgumentError,
    );
    expect(
      PanelCalculatedTotals(
        connectedVaR: 0.1,
        connectedVaS: 0.2,
        connectedVaT: 0.3,
        totalConnectedVa: 0.6000000000000001,
      ).totalConnectedVa,
      closeTo(0.6, PanelCalculatedTotals.aggregateToleranceVa),
    );
  });

  test('panel totals reject demand load above connected load', () {
    expect(
      () => PanelCalculatedTotals(
        connectedVaR: 100,
        connectedVaS: 200,
        connectedVaT: 300,
        totalConnectedVa: 600,
        demandLoadVa: 601,
      ),
      throwsArgumentError,
    );
  });

  test('calculation step has no generic engineering payload', () {
    final step = CalculationStepResult(
      status: CalculationStatus.calculated,
      sourceReferences: const [
        CalculationSourceReference(sourceId: 'engine', label: 'Engine result'),
      ],
    );
    expect(step.toJson().containsKey('values'), isFalse);
    expect(step.toJson()['sourceReferences'], isNotEmpty);
  });

  test('invalid or missing engineering inputs fail closed', () {
    expect(() => LoadInput.directVa(0), throwsArgumentError);
    expect(
      () => PanelElectricalSystem(
        phaseSystem: PanelPhaseSystem.singlePhase,
        lineToNeutralVoltageV: 0,
        lineToLineVoltageV: 400,
        frequencyHz: 50,
      ),
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
      () => PanelCalculatedTotals(
        connectedVaR: -1,
        connectedVaS: 0,
        connectedVaT: 0,
        totalConnectedVa: 0,
      ),
      throwsArgumentError,
    );
  });
}
