import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_design_request.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_execution_caller_adaptation_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_caller_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/voltage_drop_continuation_context_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_execution_caller_adapter.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_cable_selection_request.dart';

void main() {
  const adapter = CableDesignExecutionCallerAdapter();

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

  test('defaults to legacy and passes through the exact legacy request', () {
    final legacy = legacyRequest();
    final result = adapter.adapt(
      CableDesignExecutionCallerInput(legacyRequest: legacy),
    );

    expect(result.status, CableDesignExecutionCallerAdaptationStatus.ready);
    expect(result.request!.routingMode, CableDesignRoutingMode.legacy);
    expect(result.request!.legacyRequest, same(legacy));
    expect(result.request!.routingV2CableRequest, isNull);
  });

  test('legacy mode ignores populated V2 input', () {
    final legacy = legacyRequest();
    final v2 = v2Request();
    final result = adapter.adapt(
      CableDesignExecutionCallerInput(
        legacyRequest: legacy,
        routingV2CableRequest: v2,
      ),
    );

    expect(result.status, CableDesignExecutionCallerAdaptationStatus.ready);
    expect(result.request!.legacyRequest, same(legacy));
    expect(result.request!.routingV2CableRequest, isNull);
  });

  test('constructs a VAF routing v2 execution request', () {
    final v2 = v2Request();
    final result = adapter.adapt(
      CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: v2,
      ),
    );

    expect(result.isReady, isTrue);
    expect(result.request!.routingMode, CableDesignRoutingMode.routingV2);
    expect(result.request!.routingV2CableRequest, same(v2));
    expect(
      result.request!.routingV2CableRequest!.routingCableIdentity,
      CableRoutingIdentity.vaf,
    );
    expect(
      result.request!.routingV2CableRequest!.engineeringInstallation,
      same(v2.engineeringInstallation),
    );
    expect(result.request!.legacyRequest, isNull);
  });

  test('retains VAF-G as a typed routing identity', () {
    final result = adapter.adapt(
      CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: v2Request(identity: CableRoutingIdentity.vafG),
      ),
    );

    expect(result.isReady, isTrue);
    expect(
      result.request!.routingV2CableRequest!.routingCableIdentity,
      CableRoutingIdentity.vafG,
    );
  });

  test('missing routing identity remains insufficient', () {
    final result = adapter.adapt(
      CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: v2Request(identity: null),
      ),
    );

    expect(
      result.status,
      CableDesignExecutionCallerAdaptationStatus.insufficient,
    );
    expect(result.request, isNull);
    expect(
      result.missingFields,
      contains('routingV2CableRequest.routingCableIdentity'),
    );
  });

  test('missing physical installation remains insufficient', () {
    final result = adapter.adapt(
      CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: v2Request(installation: null),
      ),
    );

    expect(
      result.status,
      CableDesignExecutionCallerAdaptationStatus.insufficient,
    );
    expect(result.request, isNull);
    expect(
      result.missingFields,
      contains('routingV2CableRequest.engineeringInstallation'),
    );
  });

  test('routing v2 remains ready without a VD context', () {
    final result = adapter.adapt(
      CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: v2Request(),
      ),
    );

    expect(result.isReady, isTrue);
    expect(result.request!.routingV2VoltageDropContext, isNull);
  });

  test('retains the independently supplied VD context unchanged', () {
    const context = VoltageDropContinuationContextV2(
      installationGroup: VoltageDropInstallationGroup.group1,
      insulation: CableInsulation.pvc,
      coreType: CoreType.multiCore,
      phase: VoltagePhase.singlePhase,
      systemVoltage: 230,
      lengthM: 30,
      allowableVoltageDropPercent: 3,
    );
    final result = adapter.adapt(
      CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: v2Request(),
        routingV2VoltageDropContext: context,
      ),
    );

    expect(result.isReady, isTrue);
    expect(result.request!.routingV2VoltageDropContext, same(context));
  });

  test('does not correct a mismatched V2 request mode', () {
    final result = adapter.adapt(
      CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: v2Request(
          routingMode: CableDesignRoutingMode.legacy,
        ),
      ),
    );

    expect(result.status, CableDesignExecutionCallerAdaptationStatus.invalid);
    expect(result.request, isNull);
  });
}
