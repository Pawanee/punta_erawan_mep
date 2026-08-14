/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module  : Electrical
/// Feature : Cable Design
/// File    : ampacity_correction_service.dart
///
/// OFOR-050
///
/// Description
/// ----------------------------------------------------------------------------
///
/// Calculates corrected cable ampacity from:
///
///   Base Ampacity
///   × Grouping Factor
///   × Temperature Factor
///
/// This service is calculation-only.
///
/// It does NOT:
/// - load JSON;
/// - select cable type;
/// - select cable size;
/// - resolve grouping factors;
/// - resolve temperature factors;
/// - calculate voltage drop;
/// - apply additional engineering factors.
/// ============================================================================

class AmpacityCorrectionService {
  const AmpacityCorrectionService();

  /// Calculates corrected ampacity.
  ///
  /// Formula:
  ///
  ///   correctedAmpacity =
  ///       baseAmpacity
  ///       × groupingFactor
  ///       × temperatureFactor
  ///
  /// Returns null when a correction factor is unavailable.
  double? calculate({
    required double baseAmpacity,
    required double? groupingFactor,
    required double? temperatureFactor,
  }) {
    if (groupingFactor == null || temperatureFactor == null) {
      return null;
    }

    return baseAmpacity * groupingFactor * temperatureFactor;
  }
}