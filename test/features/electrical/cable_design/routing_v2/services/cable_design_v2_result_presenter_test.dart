import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/models/supplemental_cable_properties_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_execution_controller_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_execution_caller_adaptation_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_v2_presentation_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/combined_cable_design_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/resolved_correction_state_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/routing_property_source.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/voltage_drop_verification_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_caller_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_caller_adaptation_result.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_controller_result_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_result.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_request_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_v2_presentation_state.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_design_result_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/combined_cable_design_result_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/voltage_drop_continuation_context_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/voltage_drop_verification_result_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_execution_controller_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_v2_result_presenter.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_arrangement.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const presenter = CableDesignV2ResultPresenter();
  final controller = CableDesignExecutionControllerV2();

  CableDesignRequestV2 request({
    double loadCurrent = 10,
    double ambientTemperature = 40,
    CableRoutingIdentity identity = CableRoutingIdentity.vaf,
    int loadedConductors = 2,
    SupplementalCablePropertiesInput? supplemental,
  }) => CableDesignRequestV2(
    loadCurrent: loadCurrent,
    phaseSystem: PhaseSystem.singlePhase,
    loadedConductors: loadedConductors,
    coreType: CoreType.multiCore,
    ambientTemperature: ambientTemperature,
    routingMode: CableDesignRoutingMode.routingV2,
    identity: identity,
    engineeringInstallation: const EngineeringInstallationInput(
      environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
      supports: {InstallationSupport.surfaceMount},
    ),
    supplementalCableProperties: supplemental,
  );

  VoltageDropContinuationContextV2 context({
    double length = 10,
    double allowable = 99,
  }) => VoltageDropContinuationContextV2(
    installationGroup: VoltageDropInstallationGroup.group1,
    insulation: CableInsulation.pvc,
    coreType: CoreType.multiCore,
    phase: VoltagePhase.singlePhase,
    systemVoltage: 230,
    lengthM: length,
    allowableVoltageDropPercent: allowable,
  );

  Future<CableDesignV2PresentationState> present({
    CableDesignRequestV2? requestV2,
    VoltageDropContinuationContextV2? voltageDropContext,
  }) async {
    final result = await controller.execute(
      CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: requestV2 ?? request(),
        routingV2VoltageDropContext: voltageDropContext,
      ),
    );
    return presenter.present(result);
  }

  test('has a distinct initial state', () {
    const state = CableDesignV2PresentationState.initial();
    expect(state.status, CableDesignV2PresentationStatus.initial);
    expect(state.selectedDesign, isNull);
    expect(state.ampacitySummary, isNull);
  });

  test(
    'maps controller insufficient and invalid without a fake design',
    () async {
      final insufficient = await controller.execute(
        const CableDesignExecutionCallerInput(
          routingMode: CableDesignRoutingMode.routingV2,
        ),
      );
      final invalid = await controller.execute(
        CableDesignExecutionCallerInput(
          routingMode: CableDesignRoutingMode.routingV2,
          routingV2CableRequest: request().copyWith(
            routingMode: CableDesignRoutingMode.legacy,
          ),
        ),
      );
      expect(
        insufficient.status,
        CableDesignExecutionControllerStatusV2.insufficient,
      );
      expect(
        presenter.present(insufficient).status,
        CableDesignV2PresentationStatus.needsInput,
      );
      expect(presenter.present(insufficient).selectedDesign, isNull);
      expect(invalid.status, CableDesignExecutionControllerStatusV2.invalid);
      expect(
        presenter.present(invalid).status,
        CableDesignV2PresentationStatus.invalidInput,
      );
    },
  );

  test('presents ampacity selection when VD is not verified', () async {
    final state = await present();
    expect(
      state.status,
      CableDesignV2PresentationStatus.voltageDropNotVerified,
    );
    expect(state.selectedDesign, isNotNull);
    expect(
      state.voltageDropSummary!.status,
      VoltageDropVerificationStatusV2.notVerified,
    );
  });

  test('retains VAF Table 5-48 and Table 5-47 provenance', () async {
    final state = await present();

    expect(state.installationReference!.sourceReference, 'Table 5-47');
    expect(state.installationReference!.groupNumber, 3);
    expect(state.installationReference!.characteristics, isNotEmpty);
    expect(state.cableProfile!.identity, 'VAF');
    expect(state.cableProfile!.sourceReferences, contains('Table 5-48'));
    expect(
      state.cableProfile!.properties
          .where((property) => property.label == 'Shape')
          .single
          .source,
      RoutingPropertySource.cableProfile,
    );
  });

  test('retains equivalent VAF-G approved profile provenance', () async {
    final state = await present(
      requestV2: request(identity: CableRoutingIdentity.vafG),
    );

    expect(state.cableProfile!.identity, 'VAF-G');
    expect(state.cableProfile!.sourceReferences, contains('Table 5-48'));
    expect(state.installationReference!.sourceReference, 'Table 5-47');
    expect(state.installationReference!.groupNumber, 3);
  });

  test(
    'distinguishes supplemental properties from profile-derived facts',
    () async {
      final state = await present(
        requestV2: request(
          identity: CableRoutingIdentity.iec10,
          supplemental: const SupplementalCablePropertiesInput(
            cableShape: CableShape.round,
            insulation: CableInsulation.pvc,
            conductorTemperatureClass: ConductorTemperatureClass.pvc70,
          ),
        ),
      );

      final properties = state.cableProfile!.properties;
      expect(state.cableProfile!.identity, '60227 IEC 10');
      expect(
        properties
            .where((property) => property.label == 'Core type')
            .single
            .source,
        RoutingPropertySource.cableProfile,
      );
      expect(
        properties.where((property) => property.label == 'Shape').single.source,
        RoutingPropertySource.supplementalInput,
      );
      expect(
        properties
            .where((property) => property.label == 'Insulation')
            .single
            .source,
        RoutingPropertySource.supplementalInput,
      );
    },
  );

  test('presents IEC 10 C7 loaded-conductor and source traceability', () async {
    final state = await present(
      requestV2: request(
        identity: CableRoutingIdentity.iec10,
        loadedConductors: 3,
        loadCurrent: 60,
        supplemental: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          insulation: CableInsulation.pvc,
          conductorTemperatureClass: ConductorTemperatureClass.pvc70,
        ),
      ),
    );
    expect(state.selectedDesign!.cableIdentityDisplay, '60227 IEC 10');
    expect(state.selectedDesign!.loadedConductors, 3);
    expect(state.selectedDesign!.cableSizeSqmm, 16);
    expect(state.selectedDesign!.runs, 1);
    expect(state.selectedDesign!.currentPerRun, 60);
    expect(state.selectedDesign!.baseAmpacity, 66);
    expect(state.selectedDesign!.correctedAmpacityPerRun, 66);
    expect(state.ampacitySummary!.sourceTableId, '5-21');
    expect(state.ampacitySummary!.sourceColumnId, 'C7');
    expect(state.installationReference!.sourceReference, 'Table 5-47');
    expect(state.cableProfile!.sourceReferences, contains('Table 5-48'));
  });

  test('presents verified VD separately from ampacity traceability', () async {
    final state = await present(voltageDropContext: context());
    expect(state.status, CableDesignV2PresentationStatus.voltageDropVerified);
    expect(state.ampacitySummary!.sourceTableId, '5-21');
    expect(state.ampacitySummary!.sourceColumnId, 'C1');
    expect(state.voltageDropSummary!.sourceTableId, '9.2');
    expect(state.ampacitySummary!.sourceReferences, isNot(contains('9.2')));
    expect(state.voltageDropSummary!.sourceReferences, contains('9.2'));
  });

  test('presents failed VD while retaining selected ampacity design', () async {
    final state = await present(
      voltageDropContext: context(length: 1000, allowable: .01),
    );
    expect(state.status, CableDesignV2PresentationStatus.voltageDropFailed);
    expect(state.selectedDesign, isNotNull);
    expect(
      state.voltageDropSummary!.status,
      VoltageDropVerificationStatusV2.failed,
    );
    expect(state.voltageDropSummary!.marginPercent, lessThan(0));
  });

  test('presents no match and no candidate as ampacity unresolved', () async {
    final noMatch = await present(
      requestV2: request(
        supplemental: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
        ),
      ),
    );
    final noCandidate = await present(requestV2: request(loadCurrent: 100000));
    expect(noMatch.status, CableDesignV2PresentationStatus.ampacityUnresolved);
    expect(noMatch.selectedDesign, isNull);
    expect(
      noCandidate.status,
      CableDesignV2PresentationStatus.ampacityUnresolved,
    );
    expect(noCandidate.selectedDesign, isNull);
  });

  test('presents ampacity insufficient without a selected cable', () async {
    const result = CableDesignExecutionControllerResultV2(
      status: CableDesignExecutionControllerStatusV2.completed,
      adaptation: CableDesignExecutionCallerAdaptationResult(
        status: CableDesignExecutionCallerAdaptationStatus.ready,
        request: null,
      ),
      execution: CableDesignExecutionResult(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2Result: CombinedCableDesignResultV2(
          status: CombinedCableDesignStatusV2.ampacityInsufficient,
          ampacityResult: AmpacityDesignResultV2(
            status: AmpacityRoutingStatus.insufficient,
            selected: null,
            reason: 'Input is incomplete.',
            voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
          ),
          voltageDropResult: VoltageDropVerificationResultV2(
            status: VoltageDropVerificationStatusV2.notVerified,
            reason: 'Ampacity is not resolved.',
          ),
        ),
      ),
    );
    final state = presenter.present(result);
    expect(state.status, CableDesignV2PresentationStatus.ampacityUnresolved);
    expect(state.selectedDesign, isNull);
  });

  test(
    'VD insufficient and unsupported preserve resolved ampacity selection',
    () async {
      final insufficient = await present(
        voltageDropContext: const VoltageDropContinuationContextV2(),
      );
      final unsupported = await present(
        voltageDropContext: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group3,
          arrangement: CableArrangement.flat,
          insulation: CableInsulation.pvc,
          coreType: CoreType.singleCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 10,
          allowableVoltageDropPercent: 3,
        ),
      );
      expect(
        insufficient.status,
        CableDesignV2PresentationStatus.voltageDropInsufficient,
      );
      expect(insufficient.selectedDesign, isNotNull);
      expect(unsupported.status, CableDesignV2PresentationStatus.unsupported);
      expect(unsupported.selectedDesign, isNotNull);
    },
  );

  test(
    'keeps applied correction numeric and not-required correction non-numeric',
    () async {
      final at45 = await present(
        requestV2: request(ambientTemperature: 45),
        voltageDropContext: context(),
      );
      final at40 = await present(
        requestV2: request(),
        voltageDropContext: context(),
      );
      final applied = at45.ampacitySummary!.corrections.first;
      final notRequired = at40.ampacitySummary!.corrections.last;
      expect(applied.state, ResolvedCorrectionStateV2.applied);
      expect(applied.factor, 0.91);
      expect(applied.sourceReference, 'Table 5-43');
      expect(at45.voltageDropSummary!.sourceTableId, '9.2');
      expect(
        at45.ampacitySummary!.correctionReferences,
        contains('Table 5-43'),
      );
      expect(
        at45.ampacitySummary!.correctionReferences,
        isNot(contains('9.2')),
      );
      expect(notRequired.state, ResolvedCorrectionStateV2.notRequired);
      expect(notRequired.factor, isNull);
    },
  );

  test(
    'presents selected cable size, runs, current per run and source facts',
    () async {
      final state = await present(voltageDropContext: context());
      final selected = state.selectedDesign!;
      expect(selected.cableIdentityDisplay, 'VAF');
      expect(selected.cableSizeSqmm, 1);
      expect(selected.runs, 1);
      expect(selected.currentPerRun, 10);
      expect(selected.baseAmpacity, 14);
      expect(selected.correctedAmpacityPerRun, 14);
      expect(state.ampacitySummary!.installationGroupNumber, 3);
      expect(state.voltageDropSummary!.circuitLengthM, 10);
    },
  );
}
