import '../enums/correction_dimension_v2.dart';
import '../enums/correction_requirement_state_v2.dart';
import '../models/ampacity_correction_plan_v2.dart';
import '../models/ampacity_correction_requirement_v2.dart';

class AmpacityCorrectionPlanResolverV2 {
  const AmpacityCorrectionPlanResolverV2();
  AmpacityCorrectionPlanV2 resolve({
    required String sourceTableId,
    required double ambientTemperatureC,
  }) {
    if (sourceTableId == '5-21') return _table521(ambientTemperatureC);
    return AmpacityCorrectionPlanV2(
      sourceTableId: sourceTableId,
      referenceAmbientTemperatureC: null,
      requirements: const [
        AmpacityCorrectionRequirementV2(
          dimension: CorrectionDimensionV2.ambientTemperature,
          state: CorrectionRequirementStateV2.unresolved,
        ),
        AmpacityCorrectionRequirementV2(
          dimension: CorrectionDimensionV2.grouping,
          state: CorrectionRequirementStateV2.unresolved,
        ),
      ],
      sourceReferences: const [],
    );
  }

  AmpacityCorrectionPlanV2 _table521(double ambient) =>
      AmpacityCorrectionPlanV2(
        sourceTableId: '5-21',
        referenceAmbientTemperatureC: 40,
        requirements: [
          AmpacityCorrectionRequirementV2(
            dimension: CorrectionDimensionV2.ambientTemperature,
            state: ambient == 40
                ? CorrectionRequirementStateV2.notRequiredBySource
                : CorrectionRequirementStateV2.conditional,
            correctionTableId: ambient == 40 ? null : '5-43',
            trigger: 'ambientTemperature != 40C',
          ),
          const AmpacityCorrectionRequirementV2(
            dimension: CorrectionDimensionV2.grouping,
            state: CorrectionRequirementStateV2.notRequiredBySource,
          ),
          const AmpacityCorrectionRequirementV2(
            dimension: CorrectionDimensionV2.undergroundGrouping,
            state: CorrectionRequirementStateV2.notRequiredBySource,
          ),
          const AmpacityCorrectionRequirementV2(
            dimension: CorrectionDimensionV2.trayGrouping,
            state: CorrectionRequirementStateV2.notRequiredBySource,
          ),
        ],
        sourceReferences: const ['Table 5-21'],
      );
}
