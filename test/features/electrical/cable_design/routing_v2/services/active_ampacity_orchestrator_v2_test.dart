import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_design_request.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/models/supplemental_cable_properties_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/voltage_drop_verification_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/active_ampacity_orchestrator_v2.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final orchestrator = ActiveAmpacityOrchestratorV2();

  CableDesignRequest request({
    CableDesignRoutingMode routingMode = CableDesignRoutingMode.legacy,
    CableType cableType = CableType.iec01,
    CableRoutingIdentity? routingCableIdentity,
    CoreType coreType = CoreType.multiCore,
    EngineeringInstallationInput? installation,
    SupplementalCablePropertiesInput? supplemental,
  }) => CableDesignRequest(
    loadCurrent: 10,
    phaseSystem: PhaseSystem.singlePhase,
    cableType: cableType,
    installationMethod: InstallationMethod.group1,
    loadedConductors: 2,
    coreType: coreType,
    routingMode: routingMode,
    engineeringInstallation: installation,
    routingCableIdentity: routingCableIdentity,
    supplementalCableProperties: supplemental,
  );

  const surfaceWall = EngineeringInstallationInput(
    environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
    supports: {InstallationSupport.surfaceMount},
  );

  void expectNotPrepared(result, AmpacityRoutingStatus status) {
    expect(result.status, status);
    expect(result.selected, isNull);
    expect(result.candidates, isEmpty);
    expect(
      result.voltageDropStatus,
      VoltageDropVerificationStatusV2.notVerified,
    );
  }

  test(
    'default routing mode is not eligible and does not prepare candidates',
    () async {
      final result = await orchestrator.prepare(request());

      expectNotPrepared(result, AmpacityRoutingStatus.unsupported);
      expect(result.routingResult, isNull);
    },
  );

  test('legacy mode remains ineligible even with engineering input', () async {
    final result = await orchestrator.prepare(
      request(
        routingCableIdentity: CableRoutingIdentity.vaf,
        installation: surfaceWall,
      ),
    );

    expectNotPrepared(result, AmpacityRoutingStatus.unsupported);
    expect(result.routingResult, isNull);
  });

  test(
    'routing v2 resolves VAF wall installation to Group 3/Table 5-21/C1',
    () async {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          routingCableIdentity: CableRoutingIdentity.vaf,
          installation: surfaceWall,
        ),
      );

      expect(result.status, AmpacityRoutingStatus.resolved);
      expect(result.selected, isNull);
      expect(
        result.voltageDropStatus,
        VoltageDropVerificationStatusV2.notVerified,
      );
      expect(
        result.routingResult!.context!.installationResolution.reference!.group,
        3,
      );
      expect(result.routingResult!.ampacityTable, AmpacityTable.table521);
      expect(result.routingResult!.sourceColumnId, 'C1');
      expect(result.candidates, isNotEmpty);
    },
  );

  test(
    'prepared C1 candidates retain source traceability without legacy values',
    () async {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          routingCableIdentity: CableRoutingIdentity.vaf,
          installation: surfaceWall,
        ),
      );
      final candidate = result.candidates.firstWhere(
        (candidate) => candidate.sizeSqmm == 10,
      );

      expect(candidate.baseAmpacity, 56);
      expect(candidate.sourceTableId, '5-21');
      expect(candidate.sourceColumnId, 'C1');
      expect(candidate.installationGroupNumber, 3);
      expect(candidate.loadedConductors, 2);
      expect(candidate.coreType, CoreType.multiCore);
      expect(candidate.applicableCableIdentities, {
        CableRoutingIdentity.vaf,
        CableRoutingIdentity.vafG,
      });
      expect(candidate.sourceReferences, contains('Table 5-21'));
    },
  );

  test('conflicting VAF round shape fails closed without fallback', () async {
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        routingCableIdentity: CableRoutingIdentity.vaf,
        installation: surfaceWall,
        supplemental: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
        ),
      ),
    );

    expectNotPrepared(result, AmpacityRoutingStatus.noMatch);
    expect(result.routingResult, isNotNull);
  });

  test(
    'incomplete installation remains insufficient without fallback',
    () async {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          routingCableIdentity: CableRoutingIdentity.vaf,
        ),
      );

      expectNotPrepared(result, AmpacityRoutingStatus.insufficient);
    },
  );

  test(
    'IEC 60502-1 without supplemental intrinsic properties is insufficient',
    () async {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          cableType: CableType.iec605021,
          coreType: CoreType.singleCore,
          installation: const EngineeringInstallationInput(
            environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
            supports: {InstallationSupport.surfaceMount},
            hasOuterSheath: true,
          ),
        ),
      );

      expectNotPrepared(result, AmpacityRoutingStatus.insufficient);
      expect(result.routingResult, isNotNull);
    },
  );

  test(
    'a resolved non-Table-5-21 route is unsupported without fallback',
    () async {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          coreType: CoreType.singleCore,
          installation: const EngineeringInstallationInput(
            environments: {InstallationEnvironment.thermallyInsulatedCeiling},
            supports: {InstallationSupport.wiringEnclosure},
            hasOuterSheath: false,
          ),
          supplemental: const SupplementalCablePropertiesInput(
            insulation: CableInsulation.pvc,
            conductorTemperatureClass: ConductorTemperatureClass.pvc70,
          ),
        ),
      );

      expectNotPrepared(result, AmpacityRoutingStatus.unsupported);
      expect(result.routingResult, isNotNull);
      expect(result.routingResult!.ampacityTable, AmpacityTable.table520);
    },
  );

  test('C1 preserves source order and excludes unavailable cells', () async {
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        routingCableIdentity: CableRoutingIdentity.vaf,
        installation: surfaceWall,
      ),
    );

    final sizes = result.candidates
        .map((candidate) => candidate.sizeSqmm)
        .toList();
    expect(sizes, orderedEquals([1, 1.5, 2.5, 4, 6, 10, 16]));
    expect(
      result.candidates.every((candidate) => candidate.baseAmpacity > 0),
      isTrue,
    );
    expect(sizes, isNot(contains(25)));
  });
}
