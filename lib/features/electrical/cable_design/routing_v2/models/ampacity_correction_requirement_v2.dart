import '../enums/correction_dimension_v2.dart';
import '../enums/correction_requirement_state_v2.dart';

class AmpacityCorrectionRequirementV2 {
  const AmpacityCorrectionRequirementV2({
    required this.dimension,
    required this.state,
    this.correctionTableId,
    this.trigger,
  });
  final CorrectionDimensionV2 dimension;
  final CorrectionRequirementStateV2 state;
  final String? correctionTableId;
  final String? trigger;
}
