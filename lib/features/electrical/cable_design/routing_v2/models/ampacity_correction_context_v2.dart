import 'resolved_correction_application_v2.dart';

/// Traceability-only correction context for a future candidate pipeline.
/// Factors stay null until an approved correction-table routing is resolved.
class AmpacityCorrectionContextV2 {
  const AmpacityCorrectionContextV2({
    this.groupingFactor,
    this.groupingReference,
    this.temperatureFactor,
    this.temperatureReference,
    this.groupingApplication,
    this.temperatureApplication,
  });

  final double? groupingFactor;
  final String? groupingReference;
  final double? temperatureFactor;
  final String? temperatureReference;
  final ResolvedCorrectionApplicationV2? groupingApplication;
  final ResolvedCorrectionApplicationV2? temperatureApplication;
}
