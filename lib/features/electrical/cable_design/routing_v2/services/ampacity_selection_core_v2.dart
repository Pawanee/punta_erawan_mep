import '../../services/ampacity_correction_service.dart';
import '../enums/ampacity_selection_status_v2.dart';
import '../models/ampacity_selection_request_v2.dart';
import '../models/ampacity_selection_result_v2.dart';
import '../models/ampacity_selected_candidate_v2.dart';

/// Generic, table-agnostic ampacity selection core.
/// Candidates must already be source-filtered and source-ordered.
class AmpacitySelectionCoreV2 {
  AmpacitySelectionCoreV2({AmpacityCorrectionService? correctionService})
    : _correctionService =
          correctionService ?? const AmpacityCorrectionService();
  final AmpacityCorrectionService _correctionService;

  Future<AmpacitySelectionResultV2> select(
    AmpacitySelectionRequestV2 request,
  ) async {
    if (request.loadCurrent <= 0 || request.maximumRuns <= 0) {
      return const AmpacitySelectionResultV2(
        status: AmpacitySelectionStatusV2.insufficient,
        selected: null,
        reason: 'Load current and maximum runs must be positive.',
        voltageDropVerified: false,
      );
    }
    if (!_isAscending(request.candidates)) {
      return const AmpacitySelectionResultV2(
        status: AmpacitySelectionStatusV2.unsupported,
        selected: null,
        reason: 'Candidates are not in approved source/size order.',
        voltageDropVerified: false,
      );
    }
    if (request.candidates.isEmpty) {
      return const AmpacitySelectionResultV2(
        status: AmpacitySelectionStatusV2.noCandidate,
        selected: null,
        reason: 'No source candidates are available.',
        voltageDropVerified: false,
      );
    }
    var sawResolvedCorrection = false;
    for (var runs = 1; runs <= request.maximumRuns; runs++) {
      final currentPerRun = request.loadCurrent / runs;
      for (final candidate in request.candidates) {
        final correction = await request.correctionResolver.resolve(
          candidate,
          runs,
        );
        final grouping = correction.groupingFactor;
        final temperature = correction.temperatureFactor;
        if (grouping == null || temperature == null) continue;
        sawResolvedCorrection = true;
        final corrected = _correctionService.calculate(
          baseAmpacity: candidate.baseAmpacity,
          groupingFactor: grouping,
          temperatureFactor: temperature,
        );
        if (corrected == null || corrected < currentPerRun) continue;
        return AmpacitySelectionResultV2(
          status: AmpacitySelectionStatusV2.resolved,
          selected: AmpacitySelectedCandidateV2(
            candidate: candidate,
            runs: runs,
            currentPerRun: currentPerRun,
            groupingFactor: grouping,
            temperatureFactor: temperature,
            correctedAmpacityPerRun: corrected,
          ),
          reason: request.voltageDropContext == null
              ? 'Ampacity resolved; voltage drop not verified.'
              : 'Ampacity resolved; voltage drop continuation is pending.',
          voltageDropVerified: false,
        );
      }
    }
    return AmpacitySelectionResultV2(
      status: sawResolvedCorrection
          ? AmpacitySelectionStatusV2.noCandidate
          : AmpacitySelectionStatusV2.insufficient,
      selected: null,
      reason: sawResolvedCorrection
          ? 'No source candidate passes ampacity selection.'
          : 'Required correction context is unresolved.',
      voltageDropVerified: false,
    );
  }

  bool _isAscending(List<dynamic> candidates) {
    for (var index = 1; index < candidates.length; index++) {
      if (candidates[index - 1].sizeSqmm > candidates[index].sizeSqmm)
        return false;
    }
    return true;
  }
}
