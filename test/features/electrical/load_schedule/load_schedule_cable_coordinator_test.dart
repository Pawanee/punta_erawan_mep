import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/voltage_drop_verification_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_candidate_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_design_result_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_selected_candidate_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_request_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/resolved_correction_application_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/active_ampacity_orchestrator_v2.dart';
import 'package:mep_project/features/electrical/load_schedule/load_schedule.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('input JSON preserves explicit routing facts', () {
    final input = cableInput();
    final copy = CableCoordinationInput.fromJson(
      Map<String, Object?>.from(jsonDecode(jsonEncode(input.toJson())) as Map),
    );

    expect(copy.identity, CableRoutingIdentity.iec01);
    expect(copy.coreType, CoreType.singleCore);
    expect(copy.ambientTemperatureC, 40);
    expect(copy.groupedCircuitCount, 1);
    expect(copy.environments, {
      InstallationEnvironment.surfaceMountedWallOrCeiling,
    });
  });

  test(
    'uses breaker In as selection threshold and coordinates Ib <= In <= Iz',
    () async {
      final stub = _AmpacityStub(resolvedDesign());
      final outcome = await LoadScheduleCableCoordinator(ampacity: stub)
          .coordinate(
            circuit: activeCircuit(),
            current: calculatedCurrent(),
            circuitBreaker: selectedBreaker(),
          );

      expect(stub.lastRequest!.loadCurrent, 16);
      expect(stub.lastRequest!.routingMode, CableDesignRoutingMode.routingV2);
      expect(outcome.cable.status, CableSelectionStatus.coordinated);
      expect(outcome.cable.designCurrentIbA, 10);
      expect(outcome.cable.breakerRatedCurrentInA, 16);
      expect(outcome.cable.totalCorrectedCapacityIzA, 20);
      expect(
        outcome.circuitBreaker.cableCoordinationStatus,
        CableCoordinationStatus.coordinated,
      );
    },
  );

  test('coordinated result JSON round-trips and enforces total Iz', () {
    final result = coordinatedCable();
    final copy = CableCoordinationResult.fromJson(
      Map<String, Object?>.from(jsonDecode(jsonEncode(result.toJson())) as Map),
    );
    expect(copy.toJson(), result.toJson());

    final malformed = deepJson(result.toJson());
    malformed['totalCorrectedCapacityIzA'] = 19.0;
    expect(
      () => CableCoordinationResult.fromJson(malformed),
      throwsArgumentError,
    );
  });

  test('coordinated breaker JSON preserves coordination status', () {
    final result = selectedBreaker().markCableCoordinated();
    final copy = CircuitBreakerSelectionResult.fromJson(
      deepJson(result.toJson()),
    );
    expect(copy.cableCoordinationStatus, CableCoordinationStatus.coordinated);
  });

  test('coordinated result rejects In greater than Iz', () {
    expect(
      () => CableCoordinationResult.coordinated(
        identity: CableRoutingIdentity.iec01,
        insulation: CableInsulation.pvc,
        conductorTemperatureClass: ConductorTemperatureClass.pvc70,
        coreType: CoreType.singleCore,
        loadedConductors: 2,
        sizeSqmm: 2.5,
        runs: 1,
        baseAmpacityPerRunA: 20,
        correctedAmpacityPerRunA: 20,
        totalCorrectedCapacityIzA: 20,
        designCurrentIbA: 10,
        breakerRatedCurrentInA: 25,
        tableId: '5-20',
        installationGroupNumber: 2,
        sourceReferences: [source()],
      ),
      throwsArgumentError,
    );
  });

  test('unapproved table is rejected at result boundary', () {
    final json = deepJson(coordinatedCable().toJson());
    json['tableId'] = '5-21';
    expect(() => CableCoordinationResult.fromJson(json), throwsArgumentError);
  });

  test('table identity, insulation and installation group cannot conflict', () {
    for (final mutation in <void Function(Map<String, Object?>)>[
      (json) => json['identity'] = CableRoutingIdentity.iec605021.name,
      (json) => json['insulation'] = CableInsulation.xlpe.name,
      (json) => json['installationGroupNumber'] = 5,
    ]) {
      final json = deepJson(coordinatedCable().toJson());
      mutation(json);
      expect(() => CableCoordinationResult.fromJson(json), throwsArgumentError);
    }
  });

  test('recorded correction factors must reproduce corrected ampacity', () {
    final json = deepJson(coordinatedCable().toJson());
    json['temperatureFactor'] = 0.8;
    expect(() => CableCoordinationResult.fromJson(json), throwsArgumentError);
  });

  test(
    'missing routing input fails closed and leaves breaker pending',
    () async {
      final breaker = selectedBreaker();
      final outcome =
          await LoadScheduleCableCoordinator(
            ampacity: _AmpacityStub(resolvedDesign()),
          ).coordinate(
            circuit: activeCircuit(includeCableInput: false),
            current: calculatedCurrent(),
            circuitBreaker: breaker,
          );

      expect(outcome.cable.status, CableSelectionStatus.insufficient);
      expect(
        outcome.circuitBreaker.cableCoordinationStatus,
        CableCoordinationStatus.pendingCableSelection,
      );
    },
  );

  test('breaker Ib mismatch fails before ampacity routing', () async {
    final stub = _AmpacityStub(resolvedDesign());
    final mismatchedBreaker = CircuitBreakerSelectionResult.selected(
      breakerType: BreakerType.mcb,
      ratedCurrentA: 16,
      poleConfiguration: BreakerPoleConfiguration.oneP,
      selectionMode: BreakerSelectionMode.automatic,
      sourceReferences: [source()],
      catalogVersion: CircuitBreakerCatalog.version,
      designCurrentIbA: 9,
      currentMarginA: 7,
    );
    final outcome = await LoadScheduleCableCoordinator(ampacity: stub)
        .coordinate(
          circuit: activeCircuit(),
          current: calculatedCurrent(),
          circuitBreaker: mismatchedBreaker,
        );
    expect(outcome.cable.status, CableSelectionStatus.invalid);
    expect(stub.lastRequest, isNull);
  });

  test('breaker pole mismatch fails before ampacity routing', () async {
    final stub = _AmpacityStub(resolvedDesign());
    final wrongPole = CircuitBreakerSelectionResult.selected(
      breakerType: BreakerType.mcb,
      ratedCurrentA: 16,
      poleConfiguration: BreakerPoleConfiguration.threeP,
      selectionMode: BreakerSelectionMode.automatic,
      sourceReferences: [source()],
      catalogVersion: CircuitBreakerCatalog.version,
      designCurrentIbA: 10,
      currentMarginA: 6,
    );
    final outcome = await LoadScheduleCableCoordinator(ampacity: stub)
        .coordinate(
          circuit: activeCircuit(),
          current: calculatedCurrent(),
          circuitBreaker: wrongPole,
        );
    expect(outcome.cable.status, CableSelectionStatus.invalid);
    expect(stub.lastRequest, isNull);
  });

  test('routing correction failure remains typed and fail closed', () async {
    final outcome =
        await LoadScheduleCableCoordinator(
          ampacity: _AmpacityStub(
            const AmpacityDesignResultV2(
              status: AmpacityRoutingStatus.insufficient,
              selected: null,
              reason: 'Required correction context is unresolved.',
              voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
            ),
          ),
        ).coordinate(
          circuit: activeCircuit(),
          current: calculatedCurrent(),
          circuitBreaker: selectedBreaker(),
        );

    expect(outcome.cable.status, CableSelectionStatus.insufficient);
    expect(outcome.cable.reason, contains('correction context'));
  });

  test('SPARE does not invoke ampacity routing', () async {
    final stub = _AmpacityStub(resolvedDesign());
    final outcome = await LoadScheduleCableCoordinator(ampacity: stub)
        .coordinate(
          circuit: spareCircuit(),
          current: CurrentCalculationResult.notCalculated(),
          circuitBreaker: spareBreaker(),
        );
    expect(outcome.cable.status, CableSelectionStatus.notCalculated);
    expect(stub.lastRequest, isNull);
  });

  test('aggregate requires coordinated cable and breaker together', () {
    expect(
      () => CircuitCalculationResult(
        circuitNo: 1,
        circuitStatus: CircuitStatus.active,
        phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
        validationStatus: CircuitValidationStatus.valid,
        assignedPhase: PhaseAssignment.r,
        current: calculatedCurrent(),
        cable: coordinatedCable(),
        voltageDrop: VoltageDropCalculationResult.notCalculated(),
        circuitBreaker: selectedBreaker(),
        ground: const PendingEngineeringResult.notCalculated(),
        conduit: const PendingEngineeringResult.notCalculated(),
      ),
      throwsArgumentError,
    );
  });

  test('SPARE and SPACE require cable status notCalculated', () {
    for (final invalid in <(CircuitStatus, CableCoordinationResult)>[
      (
        CircuitStatus.spare,
        CableCoordinationResult.insufficient(reason: 'Missing routing input.'),
      ),
      (
        CircuitStatus.space,
        CableCoordinationResult.invalid(reason: 'Invalid routing input.'),
      ),
      (CircuitStatus.spare, coordinatedCable()),
      (CircuitStatus.space, coordinatedCable()),
    ]) {
      expect(
        () => nonActiveCalculationResult(status: invalid.$1, cable: invalid.$2),
        throwsArgumentError,
      );
    }
  });

  test('SPARE and SPACE notCalculated cable results round-trip', () {
    for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
      final result = nonActiveCalculationResult(
        status: status,
        cable: CableCoordinationResult.notCalculated(
          reason: '${status.name.toUpperCase()} has no load cable.',
        ),
      );
      final copy = CircuitCalculationResult.fromJson(deepJson(result.toJson()));

      expect(copy.circuitStatus, status);
      expect(copy.cable.status, CableSelectionStatus.notCalculated);
    }
  });

  test('aggregate JSON rejects non-active contradictory cable status', () {
    for (final invalid in <(CircuitStatus, CableCoordinationResult)>[
      (
        CircuitStatus.spare,
        CableCoordinationResult.insufficient(reason: 'Missing routing input.'),
      ),
      (
        CircuitStatus.space,
        CableCoordinationResult.invalid(reason: 'Invalid routing input.'),
      ),
      (CircuitStatus.spare, coordinatedCable()),
      (CircuitStatus.space, coordinatedCable()),
    ]) {
      final json = deepJson(
        nonActiveCalculationResult(
          status: invalid.$1,
          cable: CableCoordinationResult.notCalculated(),
        ).toJson(),
      );
      json['cable'] = invalid.$2.toJson();

      expect(
        () => CircuitCalculationResult.fromJson(json),
        throwsArgumentError,
      );
    }
  });
}

class _AmpacityStub extends ActiveAmpacityOrchestratorV2 {
  _AmpacityStub(this.result);

  final AmpacityDesignResultV2 result;
  CableDesignRequestV2? lastRequest;

  @override
  Future<AmpacityDesignResultV2> prepare(CableDesignRequestV2 request) async {
    lastRequest = request;
    return result;
  }
}

AmpacityDesignResultV2 resolvedDesign() {
  final candidate = AmpacityCandidateV2(
    sizeSqmm: 2.5,
    baseAmpacity: 20,
    sourceTableId: '5-20',
    sourceTableDisplayName: 'Table 5-20',
    sourceColumnId: null,
    installationGroupNumber: 2,
    loadedConductors: 2,
    coreType: CoreType.singleCore,
    insulation: CableInsulation.pvc,
    conductorTemperatureClass: ConductorTemperatureClass.pvc70,
    applicableCableIdentities: const {CableRoutingIdentity.iec01},
    sourceReferences: const ['Table 5-20'],
  );
  return AmpacityDesignResultV2(
    status: AmpacityRoutingStatus.resolved,
    selected: AmpacitySelectedCandidateV2(
      candidate: candidate,
      runs: 1,
      currentPerRun: 16,
      groupingFactor: null,
      temperatureFactor: null,
      correctedAmpacityPerRun: 20,
      groupingApplication: const ResolvedCorrectionApplicationV2.notRequired(
        'One circuit.',
        'Table 5-20',
      ),
      temperatureApplication: const ResolvedCorrectionApplicationV2.notRequired(
        'Reference ambient.',
        'Table 5-20',
      ),
    ),
    reason: 'Ampacity resolved; voltage drop not verified.',
    voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
    candidates: [candidate],
  );
}

CableCoordinationInput cableInput() => CableCoordinationInput(
  identity: CableRoutingIdentity.iec01,
  coreType: CoreType.singleCore,
  ambientTemperatureC: 40,
  environments: const {InstallationEnvironment.surfaceMountedWallOrCeiling},
  supports: const {InstallationSupport.wiringEnclosure},
  groupedCircuitCount: 1,
  hasOuterSheath: false,
  cableShape: CableShape.round,
  insulation: CableInsulation.pvc,
  conductorTemperatureClass: ConductorTemperatureClass.pvc70,
);

CircuitDefinition activeCircuit({bool includeCableInput = true}) =>
    CircuitDefinition(
      circuitNo: 1,
      description: 'Lighting',
      status: CircuitStatus.active,
      phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
      phaseAssignmentMode: PhaseAssignmentMode.manual,
      phaseAssignment: PhaseAssignment.r,
      loadInput: LoadInput.directCurrentA(10),
      cableCoordinationInput: includeCableInput ? cableInput() : null,
    );

CircuitDefinition spareCircuit() => CircuitDefinition(
  circuitNo: 2,
  description: 'Spare',
  status: CircuitStatus.spare,
  phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
  phaseAssignmentMode: PhaseAssignmentMode.manual,
  phaseAssignment: PhaseAssignment.r,
);

CurrentCalculationResult calculatedCurrent() =>
    CurrentCalculationResult.calculated(
      designCurrentA: 10,
      apparentPowerVa: 2300,
      voltageBasis: VoltageBasis.lineToNeutral,
      voltageUsedV: 230,
      formulaId: CurrentFormulaId.directCurrentSinglePhase,
      sourceReferences: [source()],
    );

CircuitBreakerSelectionResult selectedBreaker() =>
    CircuitBreakerSelectionResult.selected(
      breakerType: BreakerType.mcb,
      ratedCurrentA: 16,
      poleConfiguration: BreakerPoleConfiguration.oneP,
      selectionMode: BreakerSelectionMode.automatic,
      sourceReferences: [source()],
      catalogVersion: CircuitBreakerCatalog.version,
      designCurrentIbA: 10,
      currentMarginA: 6,
    );

CircuitBreakerSelectionResult spareBreaker() =>
    CircuitBreakerSelectionResult.selected(
      breakerType: BreakerType.mcb,
      ratedCurrentA: 16,
      poleConfiguration: BreakerPoleConfiguration.oneP,
      selectionMode: BreakerSelectionMode.manual,
      sourceReferences: [source()],
      catalogVersion: CircuitBreakerCatalog.version,
      manualOverrideReason: 'Reserved circuit',
    );

CircuitCalculationResult nonActiveCalculationResult({
  required CircuitStatus status,
  required CableCoordinationResult cable,
}) => CircuitCalculationResult(
  circuitNo: status == CircuitStatus.spare ? 2 : 3,
  circuitStatus: status,
  phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
  validationStatus: CircuitValidationStatus.valid,
  assignedPhase: status == CircuitStatus.spare ? PhaseAssignment.r : null,
  current: CurrentCalculationResult.notCalculated(),
  cable: cable,
  voltageDrop: VoltageDropCalculationResult.notCalculated(),
  circuitBreaker: status == CircuitStatus.spare
      ? spareBreaker()
      : CircuitBreakerSelectionResult.notCalculated(),
  ground: const PendingEngineeringResult.notCalculated(),
  conduit: const PendingEngineeringResult.notCalculated(),
);

CableCoordinationResult coordinatedCable() =>
    CableCoordinationResult.coordinated(
      identity: CableRoutingIdentity.iec01,
      insulation: CableInsulation.pvc,
      conductorTemperatureClass: ConductorTemperatureClass.pvc70,
      coreType: CoreType.singleCore,
      loadedConductors: 2,
      sizeSqmm: 2.5,
      runs: 1,
      baseAmpacityPerRunA: 20,
      correctedAmpacityPerRunA: 20,
      totalCorrectedCapacityIzA: 20,
      designCurrentIbA: 10,
      breakerRatedCurrentInA: 16,
      tableId: '5-20',
      installationGroupNumber: 2,
      sourceReferences: [source()],
    );

CalculationSourceReference source() =>
    CalculationSourceReference(sourceId: 'test-source', label: 'Test source');

Map<String, Object?> deepJson(Map<String, Object?> value) =>
    Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
