import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/load_schedule/load_schedule.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_arrangement.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_core_type.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_table_entry.dart';
import 'package:mep_project/features/electrical/voltage_drop/repositories/voltage_drop_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('typed voltage-drop input/result', () {
    test('input JSON round-trip preserves explicit design inputs', () {
      final input = VoltageDropCalculationInput(
        lengthOneWayM: 50,
        allowableVoltageDropPercent: 3,
        installationGroup: VoltageDropInstallationGroup.group3,
        arrangement: CableArrangement.touching,
      );
      expect(
        VoltageDropCalculationInput.fromJson(deepJson(input.toJson())).toJson(),
        input.toJson(),
      );
    });

    test('input rejects NaN, Infinity, zero, negative and >100 percent', () {
      for (final length in [double.nan, double.infinity, 0.0, -1.0]) {
        expect(
          () => voltageInput(length: length),
          throwsArgumentError,
          reason: 'length=$length',
        );
      }
      for (final limit in [double.nan, double.infinity, 0.0, -1.0, 100.0001]) {
        expect(
          () => voltageInput(limit: limit),
          throwsArgumentError,
          reason: 'limit=$limit',
        );
      }
    });

    test('calculated result round-trips and malformed JSON fails closed', () {
      final result = calculatedVoltageDrop();
      expect(
        VoltageDropCalculationResult.fromJson(
          deepJson(result.toJson()),
        ).toJson(),
        result.toJson(),
      );

      final wrongFormula = deepJson(result.toJson())..['voltageDropV'] = 99;
      expect(
        () => VoltageDropCalculationResult.fromJson(wrongFormula),
        throwsArgumentError,
      );
      final wrongCurrent = deepJson(result.toJson())..['currentPerRunA'] = 11;
      expect(
        () => VoltageDropCalculationResult.fromJson(wrongCurrent),
        throwsArgumentError,
      );
      final missingSource = deepJson(result.toJson())
        ..['sourceReferences'] = [];
      expect(
        () => VoltageDropCalculationResult.fromJson(missingSource),
        throwsArgumentError,
      );
      final unresolvedWithValue = VoltageDropCalculationResult.invalid(
        reason: 'bad input',
      ).toJson()..['sizeSqmm'] = 2.5;
      expect(
        () => VoltageDropCalculationResult.fromJson(unresolvedWithValue),
        throwsArgumentError,
      );
    });
  });

  group('LoadScheduleVoltageDropCalculator', () {
    late LoadScheduleVoltageDropCalculator calculator;

    setUp(() {
      calculator = LoadScheduleVoltageDropCalculator(
        repository: _FakeVoltageDropRepository(),
      );
    });

    test(
      'single-phase uses Ib/runs, one-way length and line-neutral voltage',
      () async {
        final result = await calculator.calculate(
          circuit: activeCircuit(),
          calculation: activeCalculation(runs: 2),
          electricalSystem: electricalSystem(),
          input: voltageInput(),
        );

        expect(result.status, VoltageDropCalculationStatus.calculated);
        expect(result.tableId, '9.1');
        expect(result.columnId, 'singlePhaseGroup1_2_5');
        expect(result.rowId, 'sizeSqmm:2.5');
        expect(result.currentPerRunA, closeTo(5, 1e-12));
        expect(result.voltageUsedV, 230);
        expect(result.voltageBasis, VoltageBasis.lineToNeutral);
        expect(result.voltageDropV, closeTo(0.45, 1e-12));
        expect(result.voltageDropPercent, closeTo(0.45 / 230 * 100, 1e-12));
        expect(result.sourceReferences.single.tableId, '9.1');
        expect(result.sourceReferences.single.rowId, 'sizeSqmm:2.5');
        expect(
          result.sourceReferences.single.columnId,
          'singlePhaseGroup1_2_5',
        );
      },
    );

    test('three-phase uses total-load Ib/runs and line-line voltage', () async {
      final result = await calculator.calculate(
        circuit: activeCircuit(threePhase: true),
        calculation: activeCalculation(threePhase: true, runs: 2),
        electricalSystem: electricalSystem(),
        input: voltageInput(),
      );

      expect(result.status, VoltageDropCalculationStatus.calculated);
      expect(result.phase!.name, 'threePhase');
      expect(result.voltageBasis, VoltageBasis.lineToLine);
      expect(result.voltageUsedV, 400);
      expect(result.currentPerRunA, closeTo(5, 1e-12));
      expect(result.voltageDropV, closeTo(0.375, 1e-12));
    });

    test('routes PVC/XLPE and single/multi core to Tables 9.1-9.4', () async {
      for (final fixture in <(CableInsulation, CoreType, String)>[
        (CableInsulation.pvc, CoreType.singleCore, '9.1'),
        (CableInsulation.pvc, CoreType.multiCore, '9.2'),
        (CableInsulation.xlpe, CoreType.singleCore, '9.3'),
        (CableInsulation.xlpe, CoreType.multiCore, '9.4'),
      ]) {
        final result = await calculator.calculate(
          circuit: activeCircuit(),
          calculation: activeCalculation(
            insulation: fixture.$1,
            coreType: fixture.$2,
          ),
          electricalSystem: electricalSystem(),
          input: voltageInput(),
        );
        expect(result.tableId, fixture.$3);
      }
    });

    test(
      'over-limit result remains calculated with explicit limit flag',
      () async {
        final result = await calculator.calculate(
          circuit: activeCircuit(),
          calculation: activeCalculation(),
          electricalSystem: electricalSystem(),
          input: voltageInput(length: 1000, limit: 1),
        );
        expect(result.status, VoltageDropCalculationStatus.calculated);
        expect(result.isWithinLimit, isFalse);
      },
    );

    test('overflow returns typed invalid without throwing', () async {
      final result = await calculator.calculate(
        circuit: activeCircuit(),
        calculation: activeCalculation(),
        electricalSystem: electricalSystem(),
        input: voltageInput(length: 1e308),
      );
      expect(result.status, VoltageDropCalculationStatus.invalid);
      expect(result.reason, contains('overflowed'));
    });

    test('missing coordinated cable fails closed', () async {
      final result = await calculator.calculate(
        circuit: activeCircuit(),
        calculation: activeCalculation(coordinated: false),
        electricalSystem: electricalSystem(),
        input: voltageInput(),
      );
      expect(result.status, VoltageDropCalculationStatus.insufficient);
      expect(result.toJson().containsKey('voltageDropV'), isFalse);
    });

    test(
      'SPARE and SPACE return notCalculated with no engineering values',
      () async {
        for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
          final result = await calculator.calculate(
            circuit: nonActiveCircuit(status),
            calculation: nonActiveCalculation(status),
            electricalSystem: electricalSystem(),
            input: voltageInput(),
          );
          expect(result.status, VoltageDropCalculationStatus.notCalculated);
          expect(result.toJson().containsKey('sizeSqmm'), isFalse);
        }
      },
    );

    test('missing or contradictory correction context fails closed', () async {
      final arrangementMissing = await calculator.calculate(
        circuit: activeCircuit(),
        calculation: activeCalculation(group: 6),
        electricalSystem: electricalSystem(),
        input: VoltageDropCalculationInput(
          lengthOneWayM: 50,
          allowableVoltageDropPercent: 3,
          installationGroup: VoltageDropInstallationGroup.group6,
        ),
      );
      expect(
        arrangementMissing.status,
        VoltageDropCalculationStatus.insufficient,
      );

      final wrongGroup = await calculator.calculate(
        circuit: activeCircuit(),
        calculation: activeCalculation(),
        electricalSystem: electricalSystem(),
        input: VoltageDropCalculationInput(
          lengthOneWayM: 50,
          allowableVoltageDropPercent: 3,
          installationGroup: VoltageDropInstallationGroup.group5,
        ),
      );
      expect(wrongGroup.status, VoltageDropCalculationStatus.invalid);
    });
  });

  group('CircuitCalculationResult voltage-drop aggregate invariants', () {
    test('accepts matching calculated result and JSON round-trip', () {
      final aggregate = activeCalculation(voltageDrop: calculatedVoltageDrop());
      expect(
        CircuitCalculationResult.fromJson(
          deepJson(aggregate.toJson()),
        ).toJson(),
        aggregate.toJson(),
      );
    });

    test('rejects mismatched CP2/CP4 facts in constructor and JSON', () {
      expect(
        () => activeCalculation(
          voltageDrop: calculatedVoltageDrop(ib: 11, currentPerRun: 11),
        ),
        throwsArgumentError,
      );
      final json = deepJson(
        activeCalculation(voltageDrop: calculatedVoltageDrop()).toJson(),
      );
      (json['voltageDrop'] as Map)['sizeSqmm'] = 4.0;
      expect(
        () => CircuitCalculationResult.fromJson(json),
        throwsArgumentError,
      );
    });

    test(
      'SPARE/SPACE require voltage drop notCalculated at both boundaries',
      () {
        for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
          expect(
            () => nonActiveCalculation(
              status,
              voltageDrop: VoltageDropCalculationResult.invalid(reason: 'bad'),
            ),
            throwsArgumentError,
          );
          final json = deepJson(nonActiveCalculation(status).toJson());
          json['voltageDrop'] = VoltageDropCalculationResult.invalid(
            reason: 'bad',
          ).toJson();
          expect(
            () => CircuitCalculationResult.fromJson(json),
            throwsArgumentError,
          );
        }
      },
    );
  });
}

class _FakeVoltageDropRepository extends VoltageDropRepository {
  @override
  Future<List<VoltageDropTableEntry>> loadTable({
    required CableInsulation insulation,
    required VoltageDropCoreType coreType,
  }) async {
    final table = switch ((insulation, coreType)) {
      (CableInsulation.pvc, VoltageDropCoreType.singleCore) => '9.1',
      (CableInsulation.pvc, VoltageDropCoreType.multiCore) => '9.2',
      (CableInsulation.xlpe, VoltageDropCoreType.singleCore) => '9.3',
      (CableInsulation.xlpe, VoltageDropCoreType.multiCore) => '9.4',
    };
    return [
      VoltageDropTableEntry(
        table: table,
        insulation: insulation,
        coreType: coreType,
        temperatureC: insulation == CableInsulation.pvc ? 70 : 90,
        sizeSqmm: 2.5,
        singlePhaseGroup1_2_5: 1.8,
        threePhaseGroup1_2_5: 1.5,
        singlePhaseTouching: 1.9,
        singlePhaseSpaced: 1.7,
        threePhaseTrefoil: 1.6,
        threePhaseFlat: 1.4,
        threePhaseSpaced: 1.3,
        singlePhaseAll: 1.8,
        threePhaseAll: 1.5,
      ),
    ];
  }
}

PanelElectricalSystem electricalSystem() => PanelElectricalSystem(
  phaseSystem: PanelPhaseSystem.threePhase,
  lineToNeutralVoltageV: 230,
  lineToLineVoltageV: 400,
  frequencyHz: 50,
);

VoltageDropCalculationInput voltageInput({
  double length = 50,
  double limit = 3,
}) => VoltageDropCalculationInput(
  lengthOneWayM: length,
  allowableVoltageDropPercent: limit,
  installationGroup: VoltageDropInstallationGroup.group2,
);

CircuitDefinition activeCircuit({bool threePhase = false}) => CircuitDefinition(
  circuitNo: 1,
  description: 'Load',
  status: CircuitStatus.active,
  phaseConfiguration: threePhase
      ? CircuitPhaseConfiguration.threePhase
      : CircuitPhaseConfiguration.singlePhase,
  phaseAssignmentMode: PhaseAssignmentMode.manual,
  phaseAssignment: threePhase ? PhaseAssignment.rst : PhaseAssignment.r,
  loadInput: LoadInput.directCurrentA(10),
);

CircuitDefinition nonActiveCircuit(CircuitStatus status) => CircuitDefinition(
  circuitNo: status == CircuitStatus.spare ? 2 : 3,
  description: status.name,
  status: status,
  phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
  phaseAssignmentMode: PhaseAssignmentMode.automatic,
);

CircuitCalculationResult activeCalculation({
  bool threePhase = false,
  bool coordinated = true,
  double ib = 10,
  double breakerA = 16,
  double iz = 20,
  int runs = 1,
  int group = 2,
  CableInsulation insulation = CableInsulation.pvc,
  CoreType coreType = CoreType.singleCore,
  VoltageDropCalculationResult? voltageDrop,
}) => CircuitCalculationResult(
  circuitNo: 1,
  circuitStatus: CircuitStatus.active,
  phaseConfiguration: threePhase
      ? CircuitPhaseConfiguration.threePhase
      : CircuitPhaseConfiguration.singlePhase,
  validationStatus: CircuitValidationStatus.valid,
  assignedPhase: threePhase ? PhaseAssignment.rst : PhaseAssignment.r,
  current: CurrentCalculationResult.calculated(
    designCurrentA: ib,
    apparentPowerVa: threePhase ? math.sqrt(3) * 400 * ib : 230 * ib,
    voltageBasis: threePhase
        ? VoltageBasis.lineToLine
        : VoltageBasis.lineToNeutral,
    voltageUsedV: threePhase ? 400 : 230,
    formulaId: threePhase
        ? CurrentFormulaId.directCurrentThreePhase
        : CurrentFormulaId.directCurrentSinglePhase,
    sourceReferences: [source()],
  ),
  cable: coordinated
      ? CableCoordinationResult.coordinated(
          identity: insulation == CableInsulation.pvc
              ? CableRoutingIdentity.nyy
              : CableRoutingIdentity.iec605021,
          insulation: insulation,
          conductorTemperatureClass: insulation == CableInsulation.pvc
              ? ConductorTemperatureClass.pvc70
              : ConductorTemperatureClass.xlpeEpr90,
          coreType: coreType,
          loadedConductors: threePhase ? 3 : 2,
          sizeSqmm: 2.5,
          runs: runs,
          baseAmpacityPerRunA: iz / runs,
          correctedAmpacityPerRunA: iz / runs,
          totalCorrectedCapacityIzA: iz,
          designCurrentIbA: ib,
          breakerRatedCurrentInA: breakerA,
          tableId: insulation == CableInsulation.pvc
              ? (group == 5 || group == 6 ? '5-23' : '5-20')
              : (group == 5 || group == 6 ? '5-29' : '5-27'),
          installationGroupNumber: group,
          sourceReferences: [source()],
        )
      : CableCoordinationResult.insufficient(reason: 'Cable input incomplete.'),
  voltageDrop: voltageDrop ?? VoltageDropCalculationResult.notCalculated(),
  circuitBreaker: CircuitBreakerSelectionResult.selected(
    breakerType: BreakerType.mcb,
    ratedCurrentA: breakerA,
    poleConfiguration: threePhase
        ? BreakerPoleConfiguration.threeP
        : BreakerPoleConfiguration.oneP,
    selectionMode: BreakerSelectionMode.automatic,
    designCurrentIbA: ib,
    currentMarginA: breakerA - ib,
    sourceReferences: [source()],
    catalogVersion: CircuitBreakerCatalog.version,
    cableCoordinated: coordinated,
  ),
  ground: const PendingEngineeringResult.notCalculated(),
  conduit: const PendingEngineeringResult.notCalculated(),
);

CircuitCalculationResult nonActiveCalculation(
  CircuitStatus status, {
  VoltageDropCalculationResult? voltageDrop,
}) => CircuitCalculationResult(
  circuitNo: status == CircuitStatus.spare ? 2 : 3,
  circuitStatus: status,
  phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
  validationStatus: CircuitValidationStatus.valid,
  current: CurrentCalculationResult.notCalculated(),
  cable: CableCoordinationResult.notCalculated(),
  voltageDrop: voltageDrop ?? VoltageDropCalculationResult.notCalculated(),
  circuitBreaker: CircuitBreakerSelectionResult.notCalculated(),
  ground: const PendingEngineeringResult.notCalculated(),
  conduit: const PendingEngineeringResult.notCalculated(),
);

VoltageDropCalculationResult calculatedVoltageDrop({
  double ib = 10,
  double currentPerRun = 10,
}) {
  const mv = 1.8;
  const length = 50.0;
  const voltage = 230.0;
  final dropV = mv * currentPerRun * length / 1000;
  final percent = dropV / voltage * 100;
  return VoltageDropCalculationResult.calculated(
    identity: CableRoutingIdentity.nyy,
    insulation: CableInsulation.pvc,
    coreType: VoltageDropCoreType.singleCore,
    phase: VoltagePhase.singlePhase,
    sizeSqmm: 2.5,
    runs: 1,
    designCurrentIbA: ib,
    currentPerRunA: currentPerRun,
    lengthOneWayM: length,
    voltageBasis: VoltageBasis.lineToNeutral,
    voltageUsedV: voltage,
    allowableVoltageDropPercent: 3,
    installationGroup: VoltageDropInstallationGroup.group2,
    tableId: '9.1',
    rowId: 'sizeSqmm:2.5',
    columnId: 'singlePhaseGroup1_2_5',
    mvPerAperM: mv,
    voltageDropV: dropV,
    voltageDropPercent: percent,
    isWithinLimit: percent <= 3,
    sourceReferences: [
      CalculationSourceReference(
        sourceId: 'voltage-drop-table-9.1',
        label: 'Voltage drop Table 9.1',
        tableId: '9.1',
        rowId: 'sizeSqmm:2.5',
        columnId: 'singlePhaseGroup1_2_5',
        sourceVersion: 'voltage-drop-tables-v1',
      ),
    ],
  );
}

CalculationSourceReference source() =>
    CalculationSourceReference(sourceId: 'test-source', label: 'Test source');

Map<String, Object?> deepJson(Map<String, Object?> value) =>
    Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
