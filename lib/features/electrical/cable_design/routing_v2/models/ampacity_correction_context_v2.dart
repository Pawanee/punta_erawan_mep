/// Traceability-only correction context for a future candidate pipeline.
/// Factors stay null until an approved correction-table routing is resolved.
class AmpacityCorrectionContextV2 {
  const AmpacityCorrectionContextV2({
    this.groupingFactor,
    this.groupingReference,
    this.temperatureFactor,
    this.temperatureReference,
  });

  final double? groupingFactor;
  final String? groupingReference;
  final double? temperatureFactor;
  final String? temperatureReference;
}
