import '../enums/correction_dimension_v2.dart';
import '../enums/correction_requirement_state_v2.dart';
import '../models/ampacity_correction_plan_v2.dart';
import '../models/ampacity_correction_requirement_v2.dart';

class AmpacityCorrectionPlanResolverV2 {
  const AmpacityCorrectionPlanResolverV2();
  AmpacityCorrectionPlanV2 resolve({
    required String sourceTableId,
    required double ambientTemperatureC,
    int? groupedCircuitCount,
  }) {
    if (sourceTableId == '5-21') return _table521(ambientTemperatureC);
    if (sourceTableId == '5-20') {
      return _airTable(
        sourceTableId,
        ambientTemperatureC,
        groupedCircuitCount,
      );
    }
    if (sourceTableId == '5-27') {
      return _airTable(
        sourceTableId,
        ambientTemperatureC,
        groupedCircuitCount,
      );
    }
    if (sourceTableId == '5-23' || sourceTableId == '5-29') {
      return _underground(
        sourceTableId,
        ambientTemperatureC,
        groupedCircuitCount,
      );
    }
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

  AmpacityCorrectionPlanV2 _airTable(
    String sourceTableId,
    double ambient,
    int? groupedCircuitCount,
  ) => AmpacityCorrectionPlanV2(
    sourceTableId: sourceTableId,
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
      _groupingRequirement(groupedCircuitCount, correctionTableId: '5-8'),
      const AmpacityCorrectionRequirementV2(
        dimension: CorrectionDimensionV2.undergroundGrouping,
        state: CorrectionRequirementStateV2.notRequiredBySource,
      ),
      const AmpacityCorrectionRequirementV2(
        dimension: CorrectionDimensionV2.trayGrouping,
        state: CorrectionRequirementStateV2.notRequiredBySource,
      ),
    ],
    sourceReferences: ['Table $sourceTableId'],
  );

  AmpacityCorrectionPlanV2 _underground(
    String sourceTableId,
    double ambient,
    int? groupedCircuitCount,
  ) => AmpacityCorrectionPlanV2(
    sourceTableId: sourceTableId,
    referenceAmbientTemperatureC: 30,
    requirements: [
      AmpacityCorrectionRequirementV2(
        dimension: CorrectionDimensionV2.ambientTemperature,
        state: ambient == 30
            ? CorrectionRequirementStateV2.notRequiredBySource
            : CorrectionRequirementStateV2.conditional,
        correctionTableId: ambient == 30 ? null : '5-44',
        trigger: 'ambientTemperature != 30C',
      ),
      _groupingRequirement(groupedCircuitCount, correctionTableId: '5-45/5-46'),
      AmpacityCorrectionRequirementV2(
        dimension: CorrectionDimensionV2.undergroundGrouping,
        state: groupedCircuitCount == 1
            ? CorrectionRequirementStateV2.notRequiredBySource
            : groupedCircuitCount == null
            ? CorrectionRequirementStateV2.unresolved
            : CorrectionRequirementStateV2.conditional,
        correctionTableId:
            groupedCircuitCount != null && groupedCircuitCount > 1
            ? '5-45/5-46'
            : null,
        trigger: 'groupedCircuitCount > 1',
      ),
      const AmpacityCorrectionRequirementV2(
        dimension: CorrectionDimensionV2.trayGrouping,
        state: CorrectionRequirementStateV2.notRequiredBySource,
      ),
    ],
    sourceReferences: ['Table $sourceTableId'],
  );

  AmpacityCorrectionRequirementV2 _groupingRequirement(
    int? groupedCircuitCount, {
    required String correctionTableId,
  }) => AmpacityCorrectionRequirementV2(
    dimension: CorrectionDimensionV2.grouping,
    state: groupedCircuitCount == 1
        ? CorrectionRequirementStateV2.notRequiredBySource
        : groupedCircuitCount == null || groupedCircuitCount < 1
        ? CorrectionRequirementStateV2.unresolved
        : CorrectionRequirementStateV2.conditional,
    correctionTableId: groupedCircuitCount != null && groupedCircuitCount > 1
        ? correctionTableId
        : null,
    trigger: 'groupedCircuitCount > 1',
  );

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
