import 'ampacity_candidate_v2.dart';
import 'voltage_drop_continuation_context_v2.dart';
import '../services/correction_resolver_v2.dart';

class AmpacitySelectionRequestV2 {
  const AmpacitySelectionRequestV2({
    required this.loadCurrent,
    required this.candidates,
    required this.correctionResolver,
    this.maximumRuns = 20,
    this.voltageDropContext,
  });
  final double loadCurrent;
  final List<AmpacityCandidateV2> candidates;
  final CorrectionResolverV2 correctionResolver;
  final int maximumRuns;
  final VoltageDropContinuationContextV2? voltageDropContext;
}
