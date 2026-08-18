import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/voltage_drop_verification_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_candidate_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_design_result_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_selected_candidate_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/resolved_correction_application_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/voltage_drop_continuation_context_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/voltage_drop_continuation_service_v2.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_arrangement.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/services/voltage_drop_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final continuation = VoltageDropContinuationServiceV2();

  AmpacityDesignResultV2 ampacity(
    CoreType core, {
    int runs = 1,
    double current = 10,
  }) {
    final candidate = AmpacityCandidateV2(
      sizeSqmm: 10,
      baseAmpacity: 56,
      sourceTableId: '5-21',
      sourceTableDisplayName: 'Table 5-21',
      sourceColumnId: 'C1',
      installationGroupNumber: 3,
      loadedConductors: 2,
      coreType: core,
      insulation: CableInsulation.pvc,
      conductorTemperatureClass: ConductorTemperatureClass.pvc70,
      applicableCableIdentities: const {CableRoutingIdentity.vaf},
      sourceReferences: const ['Table 5-21'],
    );
    return AmpacityDesignResultV2(
      status: AmpacityRoutingStatus.resolved,
      selected: AmpacitySelectedCandidateV2(
        candidate: candidate,
        runs: runs,
        currentPerRun: current,
        groupingFactor: null,
        temperatureFactor: null,
        correctedAmpacityPerRun: 56,
        groupingApplication: const ResolvedCorrectionApplicationV2.notRequired(
          'source',
          'Table 5-21',
        ),
        temperatureApplication:
            const ResolvedCorrectionApplicationV2.notRequired(
              'source',
              'Table 5-21',
            ),
      ),
      reason: null,
      voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
    );
  }

  Future<void> verify(
    CableInsulation insulation,
    CoreType core,
    String table,
  ) async {
    final design = ampacity(core);
    final result = await continuation.verify(
      ampacity: design,
      context: VoltageDropContinuationContextV2(
        installationGroup: VoltageDropInstallationGroup.group1,
        insulation: insulation,
        coreType: core,
        phase: VoltagePhase.singlePhase,
        systemVoltage: 230,
        lengthM: 10,
        allowableVoltageDropPercent: 99,
      ),
    );
    expect(result.tableId, table);
    expect(result.mvPerAperM, isNotNull);
    expect(
      result.voltageDropV,
      closeTo(result.mvPerAperM! * 10 * 10 / 1000, 0.000001),
    );
    expect(design.selected!.candidate.sourceTableId, '5-21');
    expect(design.selected!.candidate.sourceColumnId, 'C1');
    expect(design.selected!.candidate.sizeSqmm, 10);
    expect(design.selected!.runs, 1);
  }

  test(
    'PVC single-core routes independently to Table 9.1',
    () => verify(CableInsulation.pvc, CoreType.singleCore, '9.1'),
  );
  test(
    'PVC multi-core routes independently to Table 9.2',
    () => verify(CableInsulation.pvc, CoreType.multiCore, '9.2'),
  );
  test(
    'XLPE single-core routes independently to Table 9.3',
    () => verify(CableInsulation.xlpe, CoreType.singleCore, '9.3'),
  );
  test(
    'XLPE multi-core routes independently to Table 9.4',
    () => verify(CableInsulation.xlpe, CoreType.multiCore, '9.4'),
  );

  test('missing voltage-drop context remains not verified', () async {
    final design = ampacity(CoreType.multiCore);
    final result = await continuation.verify(ampacity: design);
    expect(result.status, VoltageDropVerificationStatusV2.notVerified);
    expect(design.status, AmpacityRoutingStatus.resolved);
    expect(design.selected!.candidate.sizeSqmm, 10);
    expect(design.selected!.runs, 1);
  });

  test('missing phase is insufficient without inference', () async {
    final design = ampacity(CoreType.multiCore);
    final result = await continuation.verify(
      ampacity: design,
      context: const VoltageDropContinuationContextV2(
        installationGroup: VoltageDropInstallationGroup.group1,
        insulation: CableInsulation.pvc,
        coreType: CoreType.multiCore,
        systemVoltage: 230,
        lengthM: 10,
        allowableVoltageDropPercent: 3,
      ),
    );
    expect(result.status, VoltageDropVerificationStatusV2.insufficient);
    expect(design.selected!.runs, 1);
  });

  test('missing core type is insufficient without table guessing', () async {
    final result = await continuation.verify(
      ampacity: ampacity(CoreType.multiCore),
      context: const VoltageDropContinuationContextV2(
        installationGroup: VoltageDropInstallationGroup.group1,
        insulation: CableInsulation.pvc,
        phase: VoltagePhase.singlePhase,
        systemVoltage: 230,
        lengthM: 10,
        allowableVoltageDropPercent: 3,
      ),
    );
    expect(result.status, VoltageDropVerificationStatusV2.insufficient);
  });

  test('missing insulation is insufficient', () async {
    final result = await continuation.verify(
      ampacity: ampacity(CoreType.multiCore),
      context: const VoltageDropContinuationContextV2(
        installationGroup: VoltageDropInstallationGroup.group1,
        coreType: CoreType.multiCore,
        phase: VoltagePhase.singlePhase,
        systemVoltage: 230,
        lengthM: 10,
        allowableVoltageDropPercent: 3,
      ),
    );
    expect(result.status, VoltageDropVerificationStatusV2.insufficient);
  });

  test('missing VD installation group is insufficient', () async {
    final result = await continuation.verify(
      ampacity: ampacity(CoreType.multiCore),
      context: const VoltageDropContinuationContextV2(
        insulation: CableInsulation.pvc,
        coreType: CoreType.multiCore,
        phase: VoltagePhase.singlePhase,
        systemVoltage: 230,
        lengthM: 10,
        allowableVoltageDropPercent: 3,
      ),
    );
    expect(result.status, VoltageDropVerificationStatusV2.insufficient);
  });

  test('unsupported complete context does not fall back', () async {
    final design = ampacity(CoreType.singleCore);
    final result = await continuation.verify(
      ampacity: design,
      context: const VoltageDropContinuationContextV2(
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
    expect(result.status, VoltageDropVerificationStatusV2.unsupported);
    expect(design.selected!.candidate.sizeSqmm, 10);
    expect(design.selected!.runs, 1);
  });

  test(
    'multiple runs uses selected current per run without reselection',
    () async {
      final design = ampacity(CoreType.multiCore, runs: 2, current: 25);
      final result = await continuation.verify(
        ampacity: design,
        context: const VoltageDropContinuationContextV2(
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
        result.voltageDropV,
        closeTo(result.mvPerAperM! * 25 * 10 / 1000, .000001),
      );
      expect(design.selected!.runs, 2);
      expect(design.selected!.candidate.sizeSqmm, 10);
    },
  );

  test('failed VD retains selected ampacity and negative margin', () async {
    final design = ampacity(CoreType.multiCore);
    final result = await continuation.verify(
      ampacity: design,
      context: const VoltageDropContinuationContextV2(
        installationGroup: VoltageDropInstallationGroup.group1,
        insulation: CableInsulation.pvc,
        coreType: CoreType.multiCore,
        phase: VoltagePhase.singlePhase,
        systemVoltage: 230,
        lengthM: 1000,
        allowableVoltageDropPercent: .01,
      ),
    );
    expect(result.status, VoltageDropVerificationStatusV2.failed);
    expect(result.marginPercent, lessThan(0));
    expect(design.status, AmpacityRoutingStatus.resolved);
    expect(design.selected!.runs, 1);
  });

  test(
    'Table 5-21 traceability is unchanged by independent VD contexts',
    () async {
      final design = ampacity(CoreType.multiCore);
      final selected = design.selected!;
      final first = await continuation.verify(
        ampacity: design,
        context: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group1,
          insulation: CableInsulation.pvc,
          coreType: CoreType.multiCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 10,
          allowableVoltageDropPercent: 99,
        ),
      );
      final second = await continuation.verify(
        ampacity: design,
        context: const VoltageDropContinuationContextV2(
          installationGroup: VoltageDropInstallationGroup.group1,
          insulation: CableInsulation.xlpe,
          coreType: CoreType.singleCore,
          phase: VoltagePhase.singlePhase,
          systemVoltage: 230,
          lengthM: 10,
          allowableVoltageDropPercent: 99,
        ),
      );
      expect(first.tableId, '9.2');
      expect(second.tableId, '9.3');
      expect(selected.candidate.sourceTableId, '5-21');
      expect(selected.candidate.sourceColumnId, 'C1');
      expect(selected.candidate.baseAmpacity, 56);
      expect(selected.runs, 1);
      expect(selected.groupingApplication.sourceReference, 'Table 5-21');
      expect(selected.temperatureApplication.sourceReference, 'Table 5-21');
    },
  );
}
