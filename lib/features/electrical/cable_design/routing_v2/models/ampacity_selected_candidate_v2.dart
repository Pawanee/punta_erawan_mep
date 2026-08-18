import 'ampacity_candidate_v2.dart';
import 'resolved_correction_application_v2.dart';

class AmpacitySelectedCandidateV2 {
  const AmpacitySelectedCandidateV2({
    required this.candidate,
    required this.runs,
    required this.currentPerRun,
    required this.groupingFactor,
    required this.temperatureFactor,
    required this.correctedAmpacityPerRun,
    required this.groupingApplication,
    required this.temperatureApplication,
  });
  final AmpacityCandidateV2 candidate;
  final int runs;
  final double currentPerRun;
  final double? groupingFactor;
  final double? temperatureFactor;
  final double correctedAmpacityPerRun;
  final ResolvedCorrectionApplicationV2 groupingApplication;
  final ResolvedCorrectionApplicationV2 temperatureApplication;
  double get totalCorrectedCapacity => correctedAmpacityPerRun * runs;
}
