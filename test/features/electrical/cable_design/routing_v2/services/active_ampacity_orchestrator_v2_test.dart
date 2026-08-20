import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/models/supplemental_cable_properties_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/voltage_drop_verification_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/resolved_correction_state_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_candidate_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_correction_context_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_request_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/resolved_correction_application_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/active_ampacity_orchestrator_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/correction_resolver_v2.dart';
import 'package:mep_project/features/electrical/cable_design/services/temperature_factor_service.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final orchestrator = ActiveAmpacityOrchestratorV2();

  CableDesignRequestV2 request({
    CableDesignRoutingMode routingMode = CableDesignRoutingMode.legacy,
    CableRoutingIdentity? identity,
    CoreType coreType = CoreType.multiCore,
    int loadedConductors = 2,
    double loadCurrent = 10,
    double ambientTemperature = 40,
    EngineeringInstallationInput? installation,
    SupplementalCablePropertiesInput? supplemental,
  }) => CableDesignRequestV2(
    loadCurrent: loadCurrent,
    phaseSystem: PhaseSystem.singlePhase,
    loadedConductors: loadedConductors,
    coreType: coreType,
    routingMode: routingMode,
    ambientTemperature: ambientTemperature,
    engineeringInstallation: installation,
    identity: identity,
    supplementalCableProperties: supplemental,
  );

  const surfaceWall = EngineeringInstallationInput(
    environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
    supports: {InstallationSupport.surfaceMount},
  );

  void expectNotPrepared(
    result,
    AmpacityRoutingStatus status, {
    bool hasPreparedCandidates = false,
  }) {
    expect(result.status, status);
    expect(result.selected, isNull);
    expect(result.candidates, hasPreparedCandidates ? isNotEmpty : isEmpty);
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
      request(identity: CableRoutingIdentity.vaf, installation: surfaceWall),
    );

    expectNotPrepared(result, AmpacityRoutingStatus.unsupported);
    expect(result.routingResult, isNull);
  });

  test('routing v2 selects VAF at 40C from Group 3/Table 5-21/C1', () async {
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.vaf,
        installation: surfaceWall,
      ),
    );

    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(result.selected, isNotNull);
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
    expect(result.selected!.candidate.sourceColumnId, 'C1');
    expect(
      result.selected!.correctedAmpacityPerRun,
      result.selected!.candidate.baseAmpacity,
    );
    expect(result.selected!.temperatureFactor, isNull);
    expect(result.selected!.groupingFactor, isNull);
    expect(
      result.selected!.temperatureApplication.state,
      ResolvedCorrectionStateV2.notRequired,
    );
    expect(
      result.selected!.groupingApplication.state,
      ResolvedCorrectionStateV2.notRequired,
    );
  });

  test(
    'routing v2 selects VAF-G from explicit identity and installation',
    () async {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          identity: CableRoutingIdentity.vafG,
          installation: surfaceWall,
        ),
      );

      expect(result.status, AmpacityRoutingStatus.resolved);
      expect(result.selected!.candidate.sourceTableId, '5-21');
      expect(result.selected!.candidate.sourceColumnId, 'C1');
    },
  );

  test(
    'prepared C1 candidates retain source traceability without legacy values',
    () async {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          identity: CableRoutingIdentity.vaf,
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

  test('routing v2 applies the actual Table 5-43 factor at 45C', () async {
    final factor = await TemperatureFactorService().resolve(
      ambientTemperatureC: 45,
      temperatureClass: ConductorTemperatureClass.pvc70,
    );
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.vaf,
        installation: surfaceWall,
        ambientTemperature: 45,
      ),
    );

    expect(factor, isNotNull);
    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(result.selected, isNotNull);
    expect(result.selected!.temperatureFactor, factor);
    expect(
      result.selected!.temperatureApplication.state,
      ResolvedCorrectionStateV2.applied,
    );
    expect(
      result.selected!.temperatureApplication.sourceReference,
      'Table 5-43',
    );
    expect(result.selected!.groupingFactor, isNull);
    expect(
      result.selected!.correctedAmpacityPerRun,
      closeTo(result.selected!.candidate.baseAmpacity * factor!, 0.0001),
    );
    expect(
      result.voltageDropStatus,
      VoltageDropVerificationStatusV2.notVerified,
    );
  });

  test('IEC 10 resolves only Table 5-21 C6 at 40C', () async {
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.iec10,
        installation: surfaceWall,
        supplemental: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          insulation: CableInsulation.pvc,
          conductorTemperatureClass: ConductorTemperatureClass.pvc70,
        ),
      ),
    );

    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(result.routingResult!.ampacityTable, AmpacityTable.table521);
    expect(result.routingResult!.sourceColumnId, 'C6');
    expect(result.selected!.candidate.sourceTableId, '5-21');
    expect(result.selected!.candidate.sourceColumnId, 'C6');
    expect(result.selected!.temperatureFactor, isNull);
    expect(result.selected!.groupingFactor, isNull);
    expect(
      result.selected!.temperatureApplication.state,
      ResolvedCorrectionStateV2.notRequired,
    );
    expect(
      result.selected!.groupingApplication.state,
      ResolvedCorrectionStateV2.notRequired,
    );
  });

  test('IEC 10 applies only Table 5-43 temperature correction at 45C', () async {
    final factor = await TemperatureFactorService().resolve(
      ambientTemperatureC: 45,
      temperatureClass: ConductorTemperatureClass.pvc70,
    );
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.iec10,
        installation: surfaceWall,
        ambientTemperature: 45,
        supplemental: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          insulation: CableInsulation.pvc,
          conductorTemperatureClass: ConductorTemperatureClass.pvc70,
        ),
      ),
    );

    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(result.selected!.candidate.sourceColumnId, 'C6');
    expect(result.selected!.temperatureFactor, factor);
    expect(
      result.selected!.temperatureApplication.sourceReference,
      'Table 5-43',
    );
    expect(result.selected!.groupingFactor, isNull);
    expect(
      result.selected!.groupingApplication.state,
      ResolvedCorrectionStateV2.notRequired,
    );
  });

  test('IEC 10 fails closed for missing or contradictory supplemental facts', () async {
    for (final supplemental in <SupplementalCablePropertiesInput>[
      const SupplementalCablePropertiesInput(
        insulation: CableInsulation.pvc,
        conductorTemperatureClass: ConductorTemperatureClass.pvc70,
      ),
      const SupplementalCablePropertiesInput(
        cableShape: CableShape.round,
        conductorTemperatureClass: ConductorTemperatureClass.pvc70,
      ),
      const SupplementalCablePropertiesInput(
        cableShape: CableShape.round,
        insulation: CableInsulation.pvc,
      ),
    ]) {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          identity: CableRoutingIdentity.iec10,
          installation: surfaceWall,
          supplemental: supplemental,
        ),
      );
      expectNotPrepared(result, AmpacityRoutingStatus.insufficient);
    }
    final contradictory = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.iec10,
        installation: surfaceWall,
        supplemental: const SupplementalCablePropertiesInput(
          cableShape: CableShape.flat,
          insulation: CableInsulation.pvc,
          conductorTemperatureClass: ConductorTemperatureClass.pvc70,
        ),
      ),
    );
    expectNotPrepared(contradictory, AmpacityRoutingStatus.noMatch);
  });

  test('IEC 10 rejects three loaded conductors without activating C7', () async {
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.iec10,
        loadedConductors: 3,
        installation: surfaceWall,
        supplemental: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          insulation: CableInsulation.pvc,
          conductorTemperatureClass: ConductorTemperatureClass.pvc70,
        ),
      ),
    );
    expectNotPrepared(result, AmpacityRoutingStatus.unsupported);
    expect(result.routingResult, isNull);
  });

  test('conflicting VAF round shape fails closed without fallback', () async {
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.vaf,
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
          identity: CableRoutingIdentity.vaf,
        ),
      );

      expectNotPrepared(result, AmpacityRoutingStatus.insufficient);
    },
  );

  test(
    'unavailable Table 5-43 correction fails closed as insufficient',
    () async {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          identity: CableRoutingIdentity.vaf,
          installation: surfaceWall,
          ambientTemperature: -1,
        ),
      );

      expectNotPrepared(
        result,
        AmpacityRoutingStatus.insufficient,
        hasPreparedCandidates: true,
      );
    },
  );

  test(
    'unresolved correction bridge maps to insufficient without fallback',
    () async {
      final result =
          await ActiveAmpacityOrchestratorV2(
            correctionResolver: _UnresolvedCorrectionResolver(),
          ).prepare(
            request(
              routingMode: CableDesignRoutingMode.routingV2,
              identity: CableRoutingIdentity.vaf,
              installation: surfaceWall,
            ),
          );

      expectNotPrepared(
        result,
        AmpacityRoutingStatus.insufficient,
        hasPreparedCandidates: true,
      );
    },
  );

  test('selection evaluates multiple runs with current per run', () async {
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.vaf,
        installation: surfaceWall,
        loadCurrent: 500,
      ),
    );

    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(result.selected!.runs, greaterThan(1));
    expect(
      result.selected!.currentPerRun,
      closeTo(500 / result.selected!.runs, 0.0001),
    );
    expect(result.selected!.groupingFactor, isNull);
  });

  test('VAF 100 A selects the minimum real two-run C1 design', () async {
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.vaf,
        installation: surfaceWall,
        loadCurrent: 100,
      ),
    );

    final selected = result.selected!;
    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(
      result.candidates.every((candidate) => candidate.baseAmpacity < 100),
      isTrue,
    );
    expect(selected.candidate.sourceTableId, '5-21');
    expect(selected.candidate.sourceColumnId, 'C1');
    expect(selected.candidate.sizeSqmm, 10);
    expect(selected.candidate.baseAmpacity, 56);
    expect(selected.runs, 2);
    expect(selected.currentPerRun, 50);
    expect(selected.correctedAmpacityPerRun, 56);
    expect(
      selected.temperatureApplication.state,
      ResolvedCorrectionStateV2.notRequired,
    );
    expect(selected.groupingFactor, isNull);
    expect(
      selected.groupingApplication.state,
      ResolvedCorrectionStateV2.notRequired,
    );
  });

  test('exhausted Table 5-21 candidates map to noCandidate', () async {
    final result = await orchestrator.prepare(
      request(
        routingMode: CableDesignRoutingMode.routingV2,
        identity: CableRoutingIdentity.vaf,
        installation: surfaceWall,
        loadCurrent: 100000,
      ),
    );

    expectNotPrepared(
      result,
      AmpacityRoutingStatus.noCandidate,
      hasPreparedCandidates: true,
    );
  });

  test(
    'IEC 60502-1 without supplemental intrinsic properties is insufficient',
    () async {
      final result = await orchestrator.prepare(
        request(
          routingMode: CableDesignRoutingMode.routingV2,
          identity: CableRoutingIdentity.iec605021,
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
          identity: CableRoutingIdentity.iec01,
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
        identity: CableRoutingIdentity.vaf,
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

class _UnresolvedCorrectionResolver implements CorrectionResolverV2 {
  @override
  Future<AmpacityCorrectionContextV2> resolve(
    AmpacityCandidateV2 candidate,
    int runs,
  ) async => const AmpacityCorrectionContextV2(
    temperatureApplication: ResolvedCorrectionApplicationV2.unresolved(
      'Unsupported correction reference.',
    ),
    groupingApplication: ResolvedCorrectionApplicationV2.notRequired(
      'Not required by source.',
      'Table 5-21',
    ),
  );
}
