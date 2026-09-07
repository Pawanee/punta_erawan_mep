import '../enums/breaker_pole_configuration.dart';
import '../enums/breaker_selection_mode.dart';
import '../enums/breaker_type.dart';

class CircuitBreakerSelectionInput {
  CircuitBreakerSelectionInput({
    required this.selectionMode,
    required this.breakerType,
    this.ratedCurrentA,
    this.poleConfiguration,
    this.breakingCapacityKa,
    this.tripCurveDesignation,
    this.manualOverrideReason,
  }) {
    if (breakingCapacityKa != null &&
        (!breakingCapacityKa!.isFinite || breakingCapacityKa! <= 0)) {
      throw ArgumentError.value(breakingCapacityKa, 'breakingCapacityKa');
    }
    if (tripCurveDesignation != null && tripCurveDesignation!.trim().isEmpty) {
      throw ArgumentError.value(tripCurveDesignation, 'tripCurveDesignation');
    }
    if (manualOverrideReason != null && manualOverrideReason!.trim().isEmpty) {
      throw ArgumentError.value(manualOverrideReason, 'manualOverrideReason');
    }
    if (selectionMode == BreakerSelectionMode.automatic) {
      if (ratedCurrentA != null || manualOverrideReason != null) {
        throw ArgumentError(
          'Automatic selection cannot contain a manual rating or reason.',
        );
      }
    } else {
      if (ratedCurrentA == null ||
          !ratedCurrentA!.isFinite ||
          ratedCurrentA! <= 0) {
        throw ArgumentError(
          'Manual selection requires a finite positive rated current.',
        );
      }
    }
  }

  final BreakerSelectionMode selectionMode;
  final BreakerType breakerType;
  final double? ratedCurrentA;
  final BreakerPoleConfiguration? poleConfiguration;
  final double? breakingCapacityKa;
  final String? tripCurveDesignation;
  final String? manualOverrideReason;
}
