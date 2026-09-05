import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/models/supplemental_cable_properties_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/combined_cable_design_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/voltage_drop_verification_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/routing_electrical_system.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/voltage_drop_continuation_context_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_request_v2.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_arrangement.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/combined_cable_design_orchestrator_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = CombinedCableDesignOrchestratorV2();
  CableDesignRequestV2 request({
    bool context = true,
    double load = 10,
    CableRoutingIdentity identity = CableRoutingIdentity.vaf,
    SupplementalCablePropertiesInput? supplemental,
    double ambientTemperature = 40,
  }) => CableDesignRequestV2(
    loadCurrent: load,
    phaseSystem: PhaseSystem.singlePhase,
    loadedConductors: 2,
    coreType: CoreType.multiCore,
    routingMode: CableDesignRoutingMode.routingV2,
    identity: identity,
    engineeringInstallation: context
        ? const EngineeringInstallationInput(
            environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
            supports: {InstallationSupport.surfaceMount},
          )
        : null,
    ambientTemperature: ambientTemperature,
    supplementalCableProperties: supplemental,
  );
  test('ampacity insufficient maps without VD continuation', () async {
    final r = await service.design(request(context: false));
    expect(r.status, CombinedCableDesignStatusV2.ampacityInsufficient);
    expect(r.ampacityResult.status, AmpacityRoutingStatus.insufficient);
    expect(
      r.voltageDropResult.status,
      VoltageDropVerificationStatusV2.notVerified,
    );
  });
  test('ampacity resolved without VD context is not verified', () async {
    final r = await service.design(request());
    expect(r.status, CombinedCableDesignStatusV2.voltageDropNotVerified);
    expect(r.ampacityResult.status, AmpacityRoutingStatus.resolved);
    expect(r.ampacityResult.selected, isNotNull);
    expect(r.ampacityResult.selected!.runs, 1);
    expect(
      r.voltageDropResult.status,
      VoltageDropVerificationStatusV2.notVerified,
    );
  });
  test(
    'ampacity resolved with incomplete VD context is VD insufficient',
    () async {
      final r = await service.design(
        request(),
        voltageDropContext: const VoltageDropContinuationContextV2(),
      );
      expect(r.status, CombinedCableDesignStatusV2.voltageDropInsufficient);
      expect(r.ampacityResult.status, AmpacityRoutingStatus.resolved);
      expect(r.ampacityResult.selected!.candidate.sizeSqmm, 1);
      expect(r.ampacityResult.selected!.runs, 1);
      expect(
        r.voltageDropResult.status,
        VoltageDropVerificationStatusV2.insufficient,
      );
    },
  );
  test('ampacity ambiguous maps without VD continuation', () async {
    final r = await service.design(
      request().copyWith(
        engineeringInstallation: const EngineeringInstallationInput(
          environments: {
            InstallationEnvironment.thermallyInsulatedCeiling,
            InstallationEnvironment.surfaceMountedWallOrCeiling,
          },
          supports: {InstallationSupport.wiringEnclosure},
        ),
      ),
    );
    expect(r.status, CombinedCableDesignStatusV2.ampacityAmbiguous);
    expect(r.ampacityResult.status, AmpacityRoutingStatus.ambiguous);
    expect(
      r.voltageDropResult.status,
      VoltageDropVerificationStatusV2.notVerified,
    );
  });
  test('ampacity noMatch maps without VD continuation', () async {
    final r = await service.design(
      request().copyWith(
        supplementalCableProperties: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
        ),
      ),
    );
    expect(r.status, CombinedCableDesignStatusV2.ampacityNoMatch);
    expect(r.ampacityResult.status, AmpacityRoutingStatus.noMatch);
    expect(
      r.voltageDropResult.status,
      VoltageDropVerificationStatusV2.notVerified,
    );
  });
  test('ampacity unsupported maps without VD continuation', () async {
    final r = await service.design(
      request().copyWith(routingMode: CableDesignRoutingMode.legacy),
    );
    expect(r.status, CombinedCableDesignStatusV2.ampacityUnsupported);
    expect(r.ampacityResult.status, AmpacityRoutingStatus.unsupported);
    expect(
      r.voltageDropResult.status,
      VoltageDropVerificationStatusV2.notVerified,
    );
  });
  test('ampacity noCandidate maps without VD continuation', () async {
    final r = await service.design(request(load: 100000));
    expect(r.status, CombinedCableDesignStatusV2.ampacityNoCandidate);
    expect(r.ampacityResult.status, AmpacityRoutingStatus.noCandidate);
    expect(
      r.voltageDropResult.status,
      VoltageDropVerificationStatusV2.notVerified,
    );
  });
  test('resolved ampacity preserves unsupported VD outcome', () async {
    final r = await service.design(
      request(),
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
    expect(r.status, CombinedCableDesignStatusV2.unsupported);
    expect(r.ampacityResult.status, AmpacityRoutingStatus.resolved);
    expect(
      r.voltageDropResult.status,
      VoltageDropVerificationStatusV2.unsupported,
    );
    expect(r.ampacityResult.selected!.runs, 1);
  });
  test('resolved ampacity preserves failed VD without optimization', () async {
    final r = await service.design(
      request(),
      voltageDropContext: const VoltageDropContinuationContextV2(
        installationGroup: VoltageDropInstallationGroup.group1,
        insulation: CableInsulation.pvc,
        coreType: CoreType.multiCore,
        phase: VoltagePhase.singlePhase,
        systemVoltage: 230,
        lengthM: 1000,
        allowableVoltageDropPercent: .01,
      ),
    );
    expect(r.status, CombinedCableDesignStatusV2.voltageDropFailed);
    expect(r.voltageDropResult.status, VoltageDropVerificationStatusV2.failed);
    expect(r.voltageDropResult.marginPercent, lessThan(0));
    expect(r.ampacityResult.selected!.candidate.sizeSqmm, 1);
    expect(r.ampacityResult.selected!.runs, 1);
  });
  test('resolved ampacity and verified VD maps resolved', () async {
    final r = await service.design(
      request(),
      voltageDropContext: const VoltageDropContinuationContextV2(
        installationGroup: VoltageDropInstallationGroup.group1,
        insulation: CableInsulation.pvc,
        coreType: CoreType.multiCore,
        phase: VoltagePhase.singlePhase,
        systemVoltage: 230,
        lengthM: 10,
        allowableVoltageDropPercent: 99,
      ),
    );
    expect(r.status, CombinedCableDesignStatusV2.resolved);
    expect(
      r.voltageDropResult.status,
      VoltageDropVerificationStatusV2.verified,
    );
    expect(r.ampacityResult.selected!.candidate.sourceTableId, '5-21');
    expect(r.voltageDropResult.tableId, '9.2');
  });
  test(
    'Table 5-21 C1 end-to-end at 40C keeps VD routing independent',
    () async {
      final r = await service.design(
        request(),
        voltageDropContext: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group1,
          insulation: CableInsulation.pvc,
          coreType: CoreType.multiCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 10,
          allowableVoltageDropPercent: 99,
        ),
      );
      expect(
        r
            .ampacityResult
            .routingResult!
            .context!
            .installationResolution
            .reference!
            .group,
        3,
      );
      expect(r.ampacityResult.selected!.candidate.sourceTableId, '5-21');
      expect(r.ampacityResult.selected!.candidate.sourceColumnId, 'C1');
      expect(r.ampacityResult.selected!.candidate.baseAmpacity, isNotNull);
      expect(r.voltageDropResult.tableId, '9.2');
      expect(r.voltageDropResult.sourceReferences, contains('9.2'));
    },
  );
  test('45C keeps Table 5-43 correction separate from VD table', () async {
    final r = await service.design(
      request().copyWith(ambientTemperature: 45),
      voltageDropContext: const VoltageDropContinuationContextV2(
        installationGroup: VoltageDropInstallationGroup.group1,
        insulation: CableInsulation.pvc,
        coreType: CoreType.multiCore,
        phase: VoltagePhase.singlePhase,
        systemVoltage: 230,
        lengthM: 10,
        allowableVoltageDropPercent: 99,
      ),
    );
    expect(r.ampacityResult.selected!.candidate.sourceTableId, '5-21');
    expect(r.ampacityResult.selected!.candidate.sourceColumnId, 'C1');
    expect(
      r.ampacityResult.selected!.temperatureApplication.sourceReference,
      'Table 5-43',
    );
    expect(r.ampacityResult.selected!.groupingFactor, isNull);
    expect(r.voltageDropResult.tableId, '9.2');
    expect(r.voltageDropResult.sourceReferences, contains('9.2'));
  });
  test(
    'failed VD preserves the one selected ampacity result without optimization',
    () async {
      final r = await service.design(
        request(),
        voltageDropContext: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group1,
          insulation: CableInsulation.pvc,
          coreType: CoreType.multiCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 1000,
          allowableVoltageDropPercent: .01,
        ),
      );
      expect(r.status, CombinedCableDesignStatusV2.voltageDropFailed);
      expect(r.ampacityResult.candidates, hasLength(7));
      expect(r.ampacityResult.selected!.candidate.sizeSqmm, 1);
      expect(r.ampacityResult.selected!.runs, 1);
    },
  );

  test(
    'two-run VAF design passes explicit VD without changing ampacity',
    () async {
      final r = await service.design(
        request(load: 100),
        voltageDropContext: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group1,
          insulation: CableInsulation.pvc,
          coreType: CoreType.multiCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 10,
          allowableVoltageDropPercent: 99,
        ),
      );

      final selected = r.ampacityResult.selected!;
      expect(r.status, CombinedCableDesignStatusV2.resolved);
      expect(selected.candidate.sizeSqmm, 10);
      expect(selected.runs, 2);
      expect(selected.currentPerRun, 50);
      expect(selected.groupingFactor, isNull);
      expect(r.voltageDropResult.tableId, '9.2');
      expect(r.voltageDropResult.mvPerAperM, isNotNull);
      expect(
        r.voltageDropResult.voltageDropV,
        closeTo(
          r.voltageDropResult.mvPerAperM! * selected.currentPerRun * 10 / 1000,
          0.000001,
        ),
      );
    },
  );

  test(
    'failed VD retains the real two-run VAF selection without retry',
    () async {
      final r = await service.design(
        request(load: 100),
        voltageDropContext: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group1,
          insulation: CableInsulation.pvc,
          coreType: CoreType.multiCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 1000,
          allowableVoltageDropPercent: .01,
        ),
      );

      final selected = r.ampacityResult.selected!;
      expect(r.status, CombinedCableDesignStatusV2.voltageDropFailed);
      expect(r.ampacityResult.status, AmpacityRoutingStatus.resolved);
      expect(selected.candidate.sizeSqmm, 10);
      expect(selected.runs, 2);
      expect(selected.currentPerRun, 50);
      expect(r.voltageDropResult.marginPercent, lessThan(0));
      expect(r.voltageDropResult.allowableVoltageDropPercent, .01);
    },
  );

  test(
    'IEC 10 C6 ampacity traceability remains independent from VD routing',
    () async {
      final r = await service.design(
        request(
          identity: CableRoutingIdentity.iec10,
          supplemental: const SupplementalCablePropertiesInput(
            cableShape: CableShape.round,
            insulation: CableInsulation.pvc,
            conductorTemperatureClass: ConductorTemperatureClass.pvc70,
          ),
        ),
        voltageDropContext: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group1,
          insulation: CableInsulation.pvc,
          coreType: CoreType.multiCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 10,
          allowableVoltageDropPercent: 99,
        ),
      );

      expect(r.ampacityResult.status, AmpacityRoutingStatus.resolved);
      expect(r.ampacityResult.selected!.candidate.sourceTableId, '5-21');
      expect(r.ampacityResult.selected!.candidate.sourceColumnId, 'C6');
      expect(r.ampacityResult.selected!.temperatureFactor, isNull);
      expect(r.ampacityResult.selected!.groupingFactor, isNull);
      expect(r.voltageDropResult.tableId, '9.2');
      expect(r.voltageDropResult.sourceReferences, contains('9.2'));
    },
  );

  test(
    'NYY C3 ampacity provenance remains independent from explicit VD',
    () async {
      final r = await service.design(
        request().copyWith(
          identity: CableRoutingIdentity.nyy,
          coreType: CoreType.singleCore,
          loadedConductors: 3,
          loadCurrent: 50,
          supplementalCableProperties: const SupplementalCablePropertiesInput(
            cableShape: CableShape.round,
            insulation: CableInsulation.pvc,
            conductorTemperatureClass: ConductorTemperatureClass.pvc70,
          ),
        ),
        voltageDropContext: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group1,
          insulation: CableInsulation.pvc,
          coreType: CoreType.singleCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 10,
          allowableVoltageDropPercent: 99,
        ),
      );
      expect(r.ampacityResult.selected!.candidate.sourceTableId, '5-21');
      expect(r.ampacityResult.selected!.candidate.sourceColumnId, 'C3');
      expect(r.ampacityResult.selected!.candidate.loadedConductors, 3);
      expect(r.voltageDropResult.tableId, isNotNull);
      expect(
        r.ampacityResult.selected!.candidate.sourceReferences,
        isNot(contains(r.voltageDropResult.tableId)),
      );
    },
  );

  test('IEC 60502-1 C4 runs without inferring a voltage-drop route', () async {
    final r = await service.design(
      request().copyWith(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        loadCurrent: 50,
        routingElectricalSystem: RoutingElectricalSystem.dc,
        engineeringInstallation: const EngineeringInstallationInput(
          environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
          supports: {InstallationSupport.surfaceMount},
          hasOuterSheath: true,
        ),
        supplementalCableProperties: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          insulation: CableInsulation.xlpe,
          conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
        ),
      ),
    );
    expect(r.status, CombinedCableDesignStatusV2.voltageDropNotVerified);
    expect(r.ampacityResult.selected!.candidate.sourceColumnId, 'C4');
    expect(r.voltageDropResult.tableId, isNull);
    expect(r.voltageDropResult.sourceReferences, isEmpty);
  });
}
