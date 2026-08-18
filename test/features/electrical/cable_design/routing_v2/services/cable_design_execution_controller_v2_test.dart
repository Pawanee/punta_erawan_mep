import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_design_request.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_execution_controller_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/combined_cable_design_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/voltage_drop_verification_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_caller_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_request.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_result.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_execution_controller_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_execution_gateway.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_cable_selection_request.dart';

class _GatewaySpy extends CableDesignExecutionGateway {
  bool invoked = false;
  CableDesignExecutionRequest? received;
  CableDesignExecutionResult? response;

  @override
  Future<CableDesignExecutionResult> execute(
    CableDesignExecutionRequest request,
  ) async {
    invoked = true;
    received = request;
    return response ?? super.execute(request);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  VoltageDropCableSelectionRequest legacyRequest() =>
      VoltageDropCableSelectionRequest(
        cableRequest: const CableDesignRequest(
          loadCurrent: 10,
          phaseSystem: PhaseSystem.singlePhase,
          cableType: CableType.iec01,
          installationMethod: InstallationMethod.group1,
          loadedConductors: 2,
          coreType: CoreType.singleCore,
        ),
        insulation: CableInsulation.pvc,
        phase: VoltagePhase.singlePhase,
        lengthM: 30,
        systemVoltage: 230,
        allowableVoltageDropPercent: 3,
        installationGroup: VoltageDropInstallationGroup.group1,
      );

  CableDesignRequest v2Request({
    CableRoutingIdentity? identity = CableRoutingIdentity.vaf,
    EngineeringInstallationInput? installation =
        const EngineeringInstallationInput(
          environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
          supports: {InstallationSupport.surfaceMount},
        ),
    CableDesignRoutingMode routingMode = CableDesignRoutingMode.routingV2,
  }) => CableDesignRequest(
    loadCurrent: 10,
    phaseSystem: PhaseSystem.singlePhase,
    cableType: CableType.iec01,
    installationMethod: InstallationMethod.group1,
    loadedConductors: 2,
    coreType: CoreType.multiCore,
    ambientTemperature: 40,
    routingMode: routingMode,
    routingCableIdentity: identity,
    engineeringInstallation: installation,
  );

  test('executes legacy input without reconstructing its request', () async {
    final gateway = _GatewaySpy();
    final legacy = legacyRequest();
    final result = await CableDesignExecutionControllerV2(
      gateway: gateway,
    ).execute(CableDesignExecutionCallerInput(legacyRequest: legacy));

    expect(result.status, CableDesignExecutionControllerStatusV2.completed);
    expect(gateway.received!.legacyRequest, same(legacy));
    expect(result.execution!.legacyResult, isNotNull);
    expect(result.execution!.routingV2Result, isNull);
  });

  test('executes VAF through routing v2 and preserves Table 5-21 C1', () async {
    final gateway = _GatewaySpy();
    final result = await CableDesignExecutionControllerV2(gateway: gateway)
        .execute(
          CableDesignExecutionCallerInput(
            routingMode: CableDesignRoutingMode.routingV2,
            routingV2CableRequest: v2Request(),
          ),
        );

    final v2 = result.execution!.routingV2Result!;
    expect(result.status, CableDesignExecutionControllerStatusV2.completed);
    expect(result.execution!.legacyResult, isNull);
    expect(v2.ampacityResult.selected!.candidate.sourceTableId, '5-21');
    expect(v2.ampacityResult.selected!.candidate.sourceColumnId, 'C1');
  });

  test('V2 without VD context completes with VD not verified', () async {
    final result = await CableDesignExecutionControllerV2().execute(
      CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: v2Request(),
      ),
    );

    expect(result.status, CableDesignExecutionControllerStatusV2.completed);
    expect(
      result.execution!.routingV2Result!.status,
      CombinedCableDesignStatusV2.voltageDropNotVerified,
    );
    expect(
      result.execution!.routingV2Result!.voltageDropResult.status,
      VoltageDropVerificationStatusV2.notVerified,
    );
  });

  test('missing V2 identity is insufficient and skips gateway', () async {
    final gateway = _GatewaySpy();
    final result = await CableDesignExecutionControllerV2(gateway: gateway)
        .execute(
          CableDesignExecutionCallerInput(
            routingMode: CableDesignRoutingMode.routingV2,
            routingV2CableRequest: v2Request(identity: null),
          ),
        );

    expect(result.status, CableDesignExecutionControllerStatusV2.insufficient);
    expect(result.execution, isNull);
    expect(result.reason, 'Routing v2 caller input is incomplete.');
    expect(gateway.invoked, isFalse);
  });

  test('missing installation is insufficient and skips gateway', () async {
    final gateway = _GatewaySpy();
    final result = await CableDesignExecutionControllerV2(gateway: gateway)
        .execute(
          CableDesignExecutionCallerInput(
            routingMode: CableDesignRoutingMode.routingV2,
            routingV2CableRequest: v2Request(installation: null),
          ),
        );

    expect(result.status, CableDesignExecutionControllerStatusV2.insufficient);
    expect(result.execution, isNull);
    expect(result.reason, 'Routing v2 caller input is incomplete.');
    expect(gateway.invoked, isFalse);
  });

  test('routing-mode mismatch is invalid and skips gateway', () async {
    final gateway = _GatewaySpy();
    final result = await CableDesignExecutionControllerV2(gateway: gateway)
        .execute(
          CableDesignExecutionCallerInput(
            routingMode: CableDesignRoutingMode.routingV2,
            routingV2CableRequest: v2Request(
              routingMode: CableDesignRoutingMode.legacy,
            ),
          ),
        );

    expect(result.status, CableDesignExecutionControllerStatusV2.invalid);
    expect(result.execution, isNull);
    expect(
      result.reason,
      'Routing v2 caller input requires routingMode = routingV2.',
    );
    expect(gateway.invoked, isFalse);
  });

  test('preserves an invalid gateway result without fallback', () async {
    final gateway = _GatewaySpy()
      ..response = const CableDesignExecutionResult(
        routingMode: CableDesignRoutingMode.routingV2,
        reason: 'Gateway rejected execution.',
      );
    final result = await CableDesignExecutionControllerV2(gateway: gateway)
        .execute(
          CableDesignExecutionCallerInput(
            routingMode: CableDesignRoutingMode.routingV2,
            routingV2CableRequest: v2Request(),
          ),
        );

    expect(result.status, CableDesignExecutionControllerStatusV2.completed);
    expect(result.reason, 'Gateway rejected execution.');
    expect(result.execution!.legacyResult, isNull);
    expect(result.execution!.routingV2Result, isNull);
    expect(gateway.invoked, isTrue);
  });
}
