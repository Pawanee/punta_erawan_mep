import 'ampacity_candidate_v2.dart';

class AmpacitySelectedCandidateV2 {
  const AmpacitySelectedCandidateV2({
    required this.candidate,
    required this.runs,
    required this.currentPerRun,
    required this.groupingFactor,
    required this.temperatureFactor,
    required this.correctedAmpacityPerRun,
  });
  final AmpacityCandidateV2 candidate;
  final int runs;
  final double currentPerRun;
  final double groupingFactor;
  final double temperatureFactor;
  final double correctedAmpacityPerRun;
  double get totalCorrectedCapacity => correctedAmpacityPerRun * runs;
}
