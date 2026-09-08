import 'cable_coordination_result.dart';
import 'circuit_breaker_selection_result.dart';

class CableCoordinationOutcome {
  const CableCoordinationOutcome({
    required this.cable,
    required this.circuitBreaker,
  });

  final CableCoordinationResult cable;
  final CircuitBreakerSelectionResult circuitBreaker;
}
