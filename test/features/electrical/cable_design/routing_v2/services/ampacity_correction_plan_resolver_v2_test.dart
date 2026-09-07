import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/correction_dimension_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/correction_requirement_state_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/ampacity_correction_plan_resolver_v2.dart';

void main() {
  const resolver = AmpacityCorrectionPlanResolverV2();
  test('Table 5-21 routes temperature only when ambient differs from 40C', () {
    final at40 = resolver.resolve(
      sourceTableId: '5-21',
      ambientTemperatureC: 40,
    );
    final at45 = resolver.resolve(
      sourceTableId: '5-21',
      ambientTemperatureC: 45,
    );
    final temp40 = at40.requirements.firstWhere(
      (r) => r.dimension == CorrectionDimensionV2.ambientTemperature,
    );
    final temp45 = at45.requirements.firstWhere(
      (r) => r.dimension == CorrectionDimensionV2.ambientTemperature,
    );
    expect(temp40.state, CorrectionRequirementStateV2.notRequiredBySource);
    expect(temp45.state, CorrectionRequirementStateV2.conditional);
    expect(temp45.correctionTableId, '5-43');
    for (final dimension in [
      CorrectionDimensionV2.grouping,
      CorrectionDimensionV2.undergroundGrouping,
      CorrectionDimensionV2.trayGrouping,
    ]) {
      expect(
        at45.requirements.firstWhere((r) => r.dimension == dimension).state,
        CorrectionRequirementStateV2.notRequiredBySource,
      );
    }
  });
  test('unknown table dependencies remain unresolved, not 1.0', () {
    final plan = resolver.resolve(
      sourceTableId: '5-20',
      ambientTemperatureC: 40,
    );
    expect(
      plan.requirements.every(
        (r) => r.state == CorrectionRequirementStateV2.unresolved,
      ),
      isTrue,
    );
  });

  test('underground tables require explicit circuit count and Table 5-44', () {
    final baseline = resolver.resolve(
      sourceTableId: '5-29',
      ambientTemperatureC: 30,
      groupedCircuitCount: 1,
    );
    expect(baseline.referenceAmbientTemperatureC, 30);
    expect(
      baseline.requirements
          .where(
            (r) =>
                r.dimension == CorrectionDimensionV2.ambientTemperature ||
                r.dimension == CorrectionDimensionV2.grouping,
          )
          .every(
            (r) => r.state == CorrectionRequirementStateV2.notRequiredBySource,
          ),
      isTrue,
    );

    final unknownGrouping = resolver.resolve(
      sourceTableId: '5-23',
      ambientTemperatureC: 30,
    );
    expect(
      unknownGrouping.requirements
          .firstWhere((r) => r.dimension == CorrectionDimensionV2.grouping)
          .state,
      CorrectionRequirementStateV2.unresolved,
    );

    final nonReferenceAmbient = resolver.resolve(
      sourceTableId: '5-23',
      ambientTemperatureC: 35,
      groupedCircuitCount: 1,
    );
    final temperature = nonReferenceAmbient.requirements.firstWhere(
      (r) => r.dimension == CorrectionDimensionV2.ambientTemperature,
    );
    expect(temperature.state, CorrectionRequirementStateV2.conditional);
    expect(temperature.correctionTableId, '5-44');
  });
}
