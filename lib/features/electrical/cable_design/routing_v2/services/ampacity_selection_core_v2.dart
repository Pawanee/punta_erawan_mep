import '../../services/ampacity_correction_service.dart';
import '../enums/ampacity_selection_status_v2.dart';
import '../enums/resolved_correction_state_v2.dart';
import '../models/ampacity_selection_request_v2.dart';
import '../models/ampacity_selection_result_v2.dart';
import '../models/ampacity_selected_candidate_v2.dart';
import '../models/resolved_correction_application_v2.dart';

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
        final groupingApplication =
            correction.groupingApplication ??
            (correction.groupingFactor == null
                ? const ResolvedCorrectionApplicationV2.unresolved(
                    'Grouping correction is unresolved.',
                  )
                : ResolvedCorrectionApplicationV2.applied(
                    correction.groupingFactor!,
                    correction.groupingReference,
                  ));
        final temperatureApplication =
            correction.temperatureApplication ??
            (correction.temperatureFactor == null
                ? const ResolvedCorrectionApplicationV2.unresolved(
                    'Temperature correction is unresolved.',
                  )
                : ResolvedCorrectionApplicationV2.applied(
                    correction.temperatureFactor!,
                    correction.temperatureReference,
                  ));
        if (groupingApplication.state == ResolvedCorrectionStateV2.unresolved ||
            temperatureApplication.state ==
                ResolvedCorrectionStateV2.unresolved)
          continue;
        sawResolvedCorrection = true;
        var corrected = candidate.baseAmpacity;
        if (groupingApplication.state == ResolvedCorrectionStateV2.applied) {
          corrected *= groupingApplication.factor!;
        }
        if (temperatureApplication.state == ResolvedCorrectionStateV2.applied) {
          corrected *= temperatureApplication.factor!;
        }
        final grouping = groupingApplication.factor;
        final temperature = temperatureApplication.factor;
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
            groupingApplication: groupingApplication,
            temperatureApplication: temperatureApplication,
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
