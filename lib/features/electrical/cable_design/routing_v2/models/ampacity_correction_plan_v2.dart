import 'ampacity_correction_requirement_v2.dart';

class AmpacityCorrectionPlanV2 {
  const AmpacityCorrectionPlanV2({
    required this.sourceTableId,
    required this.referenceAmbientTemperatureC,
    required this.requirements,
    required this.sourceReferences,
  });
  final String sourceTableId;
  final double? referenceAmbientTemperatureC;
  final List<AmpacityCorrectionRequirementV2> requirements;
  final List<String> sourceReferences;
}
