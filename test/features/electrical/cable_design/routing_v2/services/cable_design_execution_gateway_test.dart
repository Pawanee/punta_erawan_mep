import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_design_request.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/models/supplemental_cable_properties_input.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_request.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/combined_cable_design_result_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_execution_gateway.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/combined_cable_design_orchestrator_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/voltage_drop_continuation_context_v2.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_cable_selection_request.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_design_result.dart';
import 'package:mep_project/features/electrical/voltage_drop/services/voltage_drop_design_engine.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/combined_cable_design_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/voltage_drop_verification_status_v2.dart';

class _LegacySpy extends VoltageDropDesignEngine {
  VoltageDropCableSelectionRequest? received;
  @override
  Future<VoltageDropDesignResult> design(
    VoltageDropCableSelectionRequest request,
  ) async {
    received = request;
    return VoltageDropDesignResult.error('legacy');
  }
}

class _RoutingV2Spy extends CombinedCableDesignOrchestratorV2 {
  bool invoked = false;

  @override
  Future<CombinedCableDesignResultV2> design(
    CableDesignRequest request, {
    VoltageDropContinuationContextV2? voltageDropContext,
  }) async {
    invoked = true;
    throw StateError('Routing v2 must not be invoked.');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  VoltageDropCableSelectionRequest make() => VoltageDropCableSelectionRequest(
    cableRequest: const CableDesignRequest(
      loadCurrent: 1,
      phaseSystem: PhaseSystem.singlePhase,
      cableType: CableType.iec01,
      installationMethod: InstallationMethod.group1,
      loadedConductors: 2,
      coreType: CoreType.singleCore,
    ),
    insulation: CableInsulation.pvc,
    phase: VoltagePhase.singlePhase,
    lengthM: 1,
    systemVoltage: 230,
    allowableVoltageDropPercent: 3,
    installationGroup: VoltageDropInstallationGroup.group1,
  );
  test('valid legacy execution delegates the supplied request', () async {
    final spy = _LegacySpy();
    final request = make();
    final result = await CableDesignExecutionGateway(legacy: spy).execute(
      CableDesignExecutionRequest(
        routingMode: CableDesignRoutingMode.legacy,
        legacyRequest: request,
      ),
    );
    expect(spy.received, same(request));
    expect(result.legacyResult, isNotNull);
    expect(result.routingV2Result, isNull);
  });
  test('legacy mode ignores populated V2 inputs', () async {
    final spy = _LegacySpy();
    final r =
        await CableDesignExecutionGateway(
          legacy: spy,
          routingV2: CombinedCableDesignOrchestratorV2(),
        ).execute(
          CableDesignExecutionRequest(
            routingMode: CableDesignRoutingMode.legacy,
            legacyRequest: make(),
            routingV2CableRequest: const CableDesignRequest(
              loadCurrent: 1,
              phaseSystem: PhaseSystem.singlePhase,
              cableType: CableType.iec01,
              installationMethod: InstallationMethod.group1,
              loadedConductors: 2,
              coreType: CoreType.singleCore,
            ),
            routingV2VoltageDropContext:
                const VoltageDropContinuationContextV2(),
          ),
        );
    expect(spy.received, isNotNull);
    expect(r.legacyResult, isNotNull);
    expect(r.routingV2Result, isNull);
  });
  test('legacy request fields pass through unchanged', () async {
    final spy = _LegacySpy();
    final q = make();
    await CableDesignExecutionGateway(legacy: spy).execute(
      CableDesignExecutionRequest(
        routingMode: CableDesignRoutingMode.legacy,
        legacyRequest: q,
      ),
    );
    expect(spy.received, same(q));
    expect(q.systemVoltage, 230);
    expect(q.lengthM, 1);
    expect(q.insulation, CableInsulation.pvc);
  });
  test('routing v2 dispatch ignores supplied legacy request', () async {
    final spy = _LegacySpy();
    final result = await CableDesignExecutionGateway(legacy: spy).execute(
      CableDesignExecutionRequest(
        routingMode: CableDesignRoutingMode.routingV2,
        legacyRequest: make(),
        routingV2CableRequest: const CableDesignRequest(
          loadCurrent: 10,
          phaseSystem: PhaseSystem.singlePhase,
          cableType: CableType.iec01,
          installationMethod: InstallationMethod.group1,
          loadedConductors: 2,
          coreType: CoreType.multiCore,
          routingMode: CableDesignRoutingMode.routingV2,
          routingCableIdentity: CableRoutingIdentity.vaf,
          engineeringInstallation: EngineeringInstallationInput(
            environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
            supports: {InstallationSupport.surfaceMount},
          ),
        ),
      ),
    );
    expect(result.routingV2Result, isNotNull);
    expect(result.legacyResult, isNull);
    expect(spy.received, isNull);
  });
  test('routing v2 VAF Group 3 retains Table 5-21 C1 traceability', () async {
    final spy = _LegacySpy();
    final result = await CableDesignExecutionGateway(legacy: spy).execute(
      CableDesignExecutionRequest(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: const CableDesignRequest(
          loadCurrent: 10,
          phaseSystem: PhaseSystem.singlePhase,
          cableType: CableType.iec01,
          installationMethod: InstallationMethod.group1,
          loadedConductors: 2,
          coreType: CoreType.multiCore,
          ambientTemperature: 40,
          routingMode: CableDesignRoutingMode.routingV2,
          routingCableIdentity: CableRoutingIdentity.vaf,
          engineeringInstallation: EngineeringInstallationInput(
            environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
            supports: {InstallationSupport.surfaceMount},
          ),
        ),
      ),
    );
    final ampacity = result.routingV2Result!.ampacityResult;
    expect(result.legacyResult, isNull);
    expect(
      ampacity.routingResult!.context!.installationResolution.reference!.group,
      3,
    );
    expect(ampacity.selected!.candidate.sourceTableId, '5-21');
    expect(ampacity.selected!.candidate.sourceColumnId, 'C1');
    expect(ampacity.selected!.candidate, isNotNull);
    expect(spy.received, isNull);
  });
  test('routing v2 without VD context remains not verified', () async {
    final spy = _LegacySpy();
    final result = await CableDesignExecutionGateway(legacy: spy).execute(
      CableDesignExecutionRequest(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: const CableDesignRequest(
          loadCurrent: 10,
          phaseSystem: PhaseSystem.singlePhase,
          cableType: CableType.iec01,
          installationMethod: InstallationMethod.group1,
          loadedConductors: 2,
          coreType: CoreType.multiCore,
          ambientTemperature: 40,
          routingMode: CableDesignRoutingMode.routingV2,
          routingCableIdentity: CableRoutingIdentity.vaf,
          engineeringInstallation: EngineeringInstallationInput(
            environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
            supports: {InstallationSupport.surfaceMount},
          ),
        ),
      ),
    );
    expect(result.legacyResult, isNull);
    expect(
      result.routingV2Result!.status,
      CombinedCableDesignStatusV2.voltageDropNotVerified,
    );
    expect(result.routingV2Result!.ampacityResult.status, isNotNull);
    expect(result.routingV2Result!.ampacityResult.selected, isNotNull);
    expect(
      result.routingV2Result!.voltageDropResult.status,
      VoltageDropVerificationStatusV2.notVerified,
    );
    expect(spy.received, isNull);
  });
  test('routing v2 VAF round preserves ampacity noMatch', () async {
    final spy = _LegacySpy();
    final result = await CableDesignExecutionGateway(legacy: spy).execute(
      CableDesignExecutionRequest(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: const CableDesignRequest(
          loadCurrent: 10,
          phaseSystem: PhaseSystem.singlePhase,
          cableType: CableType.iec01,
          installationMethod: InstallationMethod.group1,
          loadedConductors: 2,
          coreType: CoreType.multiCore,
          routingMode: CableDesignRoutingMode.routingV2,
          routingCableIdentity: CableRoutingIdentity.vaf,
          engineeringInstallation: EngineeringInstallationInput(
            environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
            supports: {InstallationSupport.surfaceMount},
          ),
          supplementalCableProperties: SupplementalCablePropertiesInput(
            cableShape: CableShape.round,
          ),
        ),
      ),
    );
    expect(result.legacyResult, isNull);
    expect(
      result.routingV2Result!.status,
      CombinedCableDesignStatusV2.ampacityNoMatch,
    );
    expect(spy.received, isNull);
  });
  test('routing v2 preserves failed VD without optimization', () async {
    final spy = _LegacySpy();
    final result = await CableDesignExecutionGateway(legacy: spy).execute(
      CableDesignExecutionRequest(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: const CableDesignRequest(
          loadCurrent: 10,
          phaseSystem: PhaseSystem.singlePhase,
          cableType: CableType.iec01,
          installationMethod: InstallationMethod.group1,
          loadedConductors: 2,
          coreType: CoreType.multiCore,
          ambientTemperature: 40,
          routingMode: CableDesignRoutingMode.routingV2,
          routingCableIdentity: CableRoutingIdentity.vaf,
          engineeringInstallation: EngineeringInstallationInput(
            environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
            supports: {InstallationSupport.surfaceMount},
          ),
        ),
        routingV2VoltageDropContext: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group1,
          insulation: CableInsulation.pvc,
          coreType: CoreType.multiCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 1000,
          allowableVoltageDropPercent: .01,
        ),
      ),
    );

    final v2 = result.routingV2Result!;
    expect(result.legacyResult, isNull);
    expect(v2.status, CombinedCableDesignStatusV2.voltageDropFailed);
    expect(v2.ampacityResult.selected, isNotNull);
    expect(v2.voltageDropResult.status, VoltageDropVerificationStatusV2.failed);
    expect(v2.voltageDropResult.voltageDropPercent, isNotNull);
    expect(v2.voltageDropResult.allowableVoltageDropPercent, .01);
    expect(v2.voltageDropResult.marginPercent, lessThan(0));
    expect(v2.ampacityResult.selected!.candidate.sizeSqmm, 1);
    expect(v2.ampacityResult.selected!.runs, 1);
    expect(spy.received, isNull);
  });
  test('legacy mode without a legacy request is invalid', () async {
    final legacy = _LegacySpy();
    final routingV2 = _RoutingV2Spy();
    final result =
        await CableDesignExecutionGateway(
          legacy: legacy,
          routingV2: routingV2,
        ).execute(
          const CableDesignExecutionRequest(
            routingMode: CableDesignRoutingMode.legacy,
          ),
        );

    expect(result.legacyResult, isNull);
    expect(result.routingV2Result, isNull);
    expect(result.reason, 'Legacy request is required.');
    expect(legacy.received, isNull);
    expect(routingV2.invoked, isFalse);
  });
  test('routing v2 without a cable request is invalid', () async {
    final legacy = _LegacySpy();
    final routingV2 = _RoutingV2Spy();
    final result =
        await CableDesignExecutionGateway(
          legacy: legacy,
          routingV2: routingV2,
        ).execute(
          const CableDesignExecutionRequest(
            routingMode: CableDesignRoutingMode.routingV2,
          ),
        );

    expect(result.legacyResult, isNull);
    expect(result.routingV2Result, isNull);
    expect(result.reason, 'Routing v2 request is required.');
    expect(legacy.received, isNull);
    expect(routingV2.invoked, isFalse);
  });
  test('routing mode mismatch is an invalid execution contract', () async {
    final legacy = _LegacySpy();
    final routingV2 = _RoutingV2Spy();
    final result =
        await CableDesignExecutionGateway(
          legacy: legacy,
          routingV2: routingV2,
        ).execute(
          CableDesignExecutionRequest(
            routingMode: CableDesignRoutingMode.routingV2,
            routingV2CableRequest: const CableDesignRequest(
              loadCurrent: 10,
              phaseSystem: PhaseSystem.singlePhase,
              cableType: CableType.iec01,
              installationMethod: InstallationMethod.group1,
              loadedConductors: 2,
              coreType: CoreType.multiCore,
              routingMode: CableDesignRoutingMode.legacy,
            ),
          ),
        );

    expect(result.legacyResult, isNull);
    expect(result.routingV2Result, isNull);
    expect(result.reason, 'Routing v2 request is required.');
    expect(legacy.received, isNull);
    expect(routingV2.invoked, isFalse);
  });
}
