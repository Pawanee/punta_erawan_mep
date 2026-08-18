import '../../services/temperature_factor_service.dart';
import '../enums/correction_dimension_v2.dart';
import '../enums/correction_requirement_state_v2.dart';
import '../models/ampacity_candidate_v2.dart';
import '../models/ampacity_correction_context_v2.dart';
import '../models/ampacity_correction_plan_v2.dart';
import '../models/resolved_correction_application_v2.dart';

class CorrectionApplicationResolverV2 {
  CorrectionApplicationResolverV2({TemperatureFactorService? temperatureFactors})
      : _temperatureFactors = temperatureFactors ?? TemperatureFactorService();
  final TemperatureFactorService _temperatureFactors;
  Future<AmpacityCorrectionContextV2> resolve({required AmpacityCorrectionPlanV2 plan, required AmpacityCandidateV2 candidate, required double ambientTemperatureC}) async {
    final temperature = await _application(plan, CorrectionDimensionV2.ambientTemperature, candidate, ambientTemperatureC);
    final grouping = await _application(plan, CorrectionDimensionV2.grouping, candidate, ambientTemperatureC);
    return AmpacityCorrectionContextV2(temperatureApplication: temperature, groupingApplication: grouping);
  }
  Future<ResolvedCorrectionApplicationV2> _application(AmpacityCorrectionPlanV2 plan, CorrectionDimensionV2 dimension, AmpacityCandidateV2 candidate, double ambient) async {
    final requirement = plan.requirements.where((item) => item.dimension == dimension).firstOrNull;
    if (requirement == null || requirement.state == CorrectionRequirementStateV2.unresolved) return const ResolvedCorrectionApplicationV2.unresolved('Correction requirement is unresolved.');
    if (requirement.state == CorrectionRequirementStateV2.notRequiredBySource) return ResolvedCorrectionApplicationV2.notRequired(requirement.trigger ?? 'Not required by source.', plan.sourceReferences.isEmpty ? null : plan.sourceReferences.first);
    if (dimension == CorrectionDimensionV2.ambientTemperature && requirement.correctionTableId == '5-43') {
      final factor = await _temperatureFactors.resolve(ambientTemperatureC: ambient, temperatureClass: candidate.conductorTemperatureClass);
      return factor == null ? const ResolvedCorrectionApplicationV2.unresolved('Table 5-43 factor is unavailable.') : ResolvedCorrectionApplicationV2.applied(factor, 'Table 5-43');
    }
    return const ResolvedCorrectionApplicationV2.unresolved('Correction table is unsupported by this bridge.');
  }
}
