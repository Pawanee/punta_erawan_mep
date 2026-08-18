import '../models/ampacity_candidate_v2.dart';
import '../models/ampacity_correction_context_v2.dart';

/// Boundary for correction results already resolved by approved services.
/// A resolver may vary correction context by candidate and parallel run count.
abstract interface class CorrectionResolverV2 {
  Future<AmpacityCorrectionContextV2> resolve(
    AmpacityCandidateV2 candidate,
    int runs,
  );
}
