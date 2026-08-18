import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/correction_dimension_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/correction_requirement_state_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/resolved_correction_state_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_candidate_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_correction_plan_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_correction_requirement_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/correction_application_resolver_v2.dart';
import 'package:mep_project/features/electrical/cable_design/services/temperature_factor_service.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const candidate = AmpacityCandidateV2(
    sizeSqmm: 10,
    baseAmpacity: 56,
    sourceTableId: '5-21',
    sourceTableDisplayName: 'Table 5-21',
    sourceColumnId: 'C1',
    installationGroupNumber: 3,
    loadedConductors: 2,
    coreType: CoreType.multiCore,
    insulation: CableInsulation.pvc,
    conductorTemperatureClass: ConductorTemperatureClass.pvc70,
    applicableCableIdentities: {CableRoutingIdentity.vaf},
    sourceReferences: ['Table 5-21'],
  );

  AmpacityCorrectionPlanV2 plan(
    List<AmpacityCorrectionRequirementV2> requirements,
  ) => AmpacityCorrectionPlanV2(
    sourceTableId: '5-21',
    referenceAmbientTemperatureC: 40,
    requirements: requirements,
    sourceReferences: const ['Table 5-21'],
  );

  test('not-required correction retains a null factor', () async {
    final result = await CorrectionApplicationResolverV2().resolve(
      plan: plan(const [
        AmpacityCorrectionRequirementV2(
          dimension: CorrectionDimensionV2.ambientTemperature,
          state: CorrectionRequirementStateV2.notRequiredBySource,
        ),
        AmpacityCorrectionRequirementV2(
          dimension: CorrectionDimensionV2.grouping,
          state: CorrectionRequirementStateV2.notRequiredBySource,
        ),
      ]),
      candidate: candidate,
      ambientTemperatureC: 40,
    );

    expect(
      result.temperatureApplication!.state,
      ResolvedCorrectionStateV2.notRequired,
    );
    expect(result.temperatureApplication!.factor, isNull);
    expect(result.groupingApplication!.factor, isNull);
  });

  test(
    'Table 5-43 temperature factor is applied with its source reference',
    () async {
      final expectedFactor = await TemperatureFactorService().resolve(
        ambientTemperatureC: 45,
        temperatureClass: ConductorTemperatureClass.pvc70,
      );
      final result = await CorrectionApplicationResolverV2().resolve(
        plan: plan(const [
          AmpacityCorrectionRequirementV2(
            dimension: CorrectionDimensionV2.ambientTemperature,
            state: CorrectionRequirementStateV2.conditional,
            correctionTableId: '5-43',
          ),
          AmpacityCorrectionRequirementV2(
            dimension: CorrectionDimensionV2.grouping,
            state: CorrectionRequirementStateV2.notRequiredBySource,
          ),
        ]),
        candidate: candidate,
        ambientTemperatureC: 45,
      );

      expect(expectedFactor, isNotNull);
      expect(
        result.temperatureApplication!.state,
        ResolvedCorrectionStateV2.applied,
      );
      expect(result.temperatureApplication!.factor, expectedFactor);
      expect(result.temperatureApplication!.sourceReference, 'Table 5-43');
    },
  );

  test('unavailable Table 5-43 factor remains unresolved', () async {
    final result = await CorrectionApplicationResolverV2().resolve(
      plan: plan(const [
        AmpacityCorrectionRequirementV2(
          dimension: CorrectionDimensionV2.ambientTemperature,
          state: CorrectionRequirementStateV2.conditional,
          correctionTableId: '5-43',
        ),
        AmpacityCorrectionRequirementV2(
          dimension: CorrectionDimensionV2.grouping,
          state: CorrectionRequirementStateV2.notRequiredBySource,
        ),
      ]),
      candidate: candidate,
      ambientTemperatureC: -1,
    );

    expect(
      result.temperatureApplication!.state,
      ResolvedCorrectionStateV2.unresolved,
    );
    expect(result.temperatureApplication!.factor, isNull);
  });

  test(
    'unsupported correction table remains unresolved without a factor',
    () async {
      final result = await CorrectionApplicationResolverV2().resolve(
        plan: plan(const [
          AmpacityCorrectionRequirementV2(
            dimension: CorrectionDimensionV2.ambientTemperature,
            state: CorrectionRequirementStateV2.required,
            correctionTableId: '5-40',
          ),
          AmpacityCorrectionRequirementV2(
            dimension: CorrectionDimensionV2.grouping,
            state: CorrectionRequirementStateV2.notRequiredBySource,
          ),
        ]),
        candidate: candidate,
        ambientTemperatureC: 45,
      );

      expect(
        result.temperatureApplication!.state,
        ResolvedCorrectionStateV2.unresolved,
      );
      expect(result.temperatureApplication!.factor, isNull);
      expect(result.temperatureApplication!.sourceReference, isNull);
    },
  );
}
