import '../enums/breaker_pole_configuration.dart';
import '../enums/breaker_selection_mode.dart';
import '../enums/calculation_status.dart';
import '../enums/circuit_phase_configuration.dart';
import '../enums/circuit_status.dart';
import '../models/calculation_source_reference.dart';
import '../models/circuit_breaker_catalog.dart';
import '../models/circuit_breaker_selection_input.dart';
import '../models/circuit_breaker_selection_result.dart';
import '../models/circuit_definition.dart';
import '../models/current_calculation_result.dart';

class CircuitBreakerSelector {
  const CircuitBreakerSelector();

  CircuitBreakerSelectionResult select({
    required CircuitDefinition circuit,
    required CurrentCalculationResult current,
    CircuitBreakerSelectionInput? input,
  }) {
    if (circuit.status == CircuitStatus.space) {
      return CircuitBreakerSelectionResult.notCalculated(
        reason: 'SPACE circuits do not have a circuit breaker.',
      );
    }
    if (input == null) {
      return CircuitBreakerSelectionResult.insufficient(
        reason: 'Circuit breaker selection input is required.',
      );
    }
    if (circuit.status == CircuitStatus.spare &&
        input.poleConfiguration == null) {
      return CircuitBreakerSelectionResult.insufficient(
        reason: 'SPARE circuits require a manual pole configuration.',
      );
    }
    final pole =
        input.poleConfiguration ??
        (circuit.phaseConfiguration == CircuitPhaseConfiguration.singlePhase
            ? BreakerPoleConfiguration.oneP
            : BreakerPoleConfiguration.threeP);
    if (!_isCompatiblePole(circuit.phaseConfiguration, pole)) {
      return CircuitBreakerSelectionResult.invalid(
        reason: 'Pole configuration is incompatible with circuit phase.',
      );
    }
    if (circuit.status == CircuitStatus.spare) {
      if (input.selectionMode != BreakerSelectionMode.manual) {
        return CircuitBreakerSelectionResult.insufficient(
          reason: 'SPARE circuits require manual circuit breaker details.',
        );
      }
      return _manualResult(input: input, pole: pole);
    }
    if (current.status != CalculationStatus.calculated ||
        current.designCurrentA == null ||
        !current.designCurrentA!.isFinite ||
        current.designCurrentA! <= 0) {
      return CircuitBreakerSelectionResult.invalid(
        reason: 'ACTIVE selection requires a valid calculated design current.',
      );
    }
    final ib = current.designCurrentA!;
    if (input.selectionMode == BreakerSelectionMode.manual) {
      if (input.manualOverrideReason == null) {
        return CircuitBreakerSelectionResult.invalid(
          reason: 'ACTIVE manual override requires a non-empty reason.',
        );
      }
      return _manualResult(input: input, pole: pole, ib: ib);
    }
    double? rating;
    for (final candidate in CircuitBreakerCatalog.ratingsFor(
      input.breakerType,
    )) {
      if (candidate >= ib) {
        rating = candidate;
        break;
      }
    }
    if (rating == null) {
      return CircuitBreakerSelectionResult.noMatch(
        reason: 'Design current exceeds the selected breaker type catalog.',
      );
    }
    return CircuitBreakerSelectionResult.selected(
      breakerType: input.breakerType,
      ratedCurrentA: rating,
      poleConfiguration: pole,
      selectionMode: BreakerSelectionMode.automatic,
      designCurrentIbA: ib,
      currentMarginA: rating - ib,
      breakingCapacityKa: input.breakingCapacityKa,
      tripCurveDesignation: input.tripCurveDesignation,
      sourceReferences: [_catalogReference(input.breakerType.name)],
      catalogVersion: CircuitBreakerCatalog.version,
    );
  }

  CircuitBreakerSelectionResult _manualResult({
    required CircuitBreakerSelectionInput input,
    required BreakerPoleConfiguration pole,
    double? ib,
  }) {
    final rating = input.ratedCurrentA!;
    if (!CircuitBreakerCatalog.contains(input.breakerType, rating)) {
      return CircuitBreakerSelectionResult.invalid(
        reason: 'Manual rated current is not in the selected type catalog.',
      );
    }
    if (ib != null && rating < ib) {
      return CircuitBreakerSelectionResult.invalid(
        reason: 'Manual rated current cannot be below design current Ib.',
      );
    }
    return CircuitBreakerSelectionResult.selected(
      breakerType: input.breakerType,
      ratedCurrentA: rating,
      poleConfiguration: pole,
      selectionMode: BreakerSelectionMode.manual,
      designCurrentIbA: ib,
      currentMarginA: ib == null ? null : rating - ib,
      breakingCapacityKa: input.breakingCapacityKa,
      tripCurveDesignation: input.tripCurveDesignation,
      manualOverrideReason: input.manualOverrideReason,
      sourceReferences: [_catalogReference(input.breakerType.name)],
      catalogVersion: CircuitBreakerCatalog.version,
    );
  }

  bool _isCompatiblePole(
    CircuitPhaseConfiguration phase,
    BreakerPoleConfiguration pole,
  ) => switch (phase) {
    CircuitPhaseConfiguration.singlePhase =>
      pole == BreakerPoleConfiguration.oneP ||
          pole == BreakerPoleConfiguration.onePPlusN ||
          pole == BreakerPoleConfiguration.twoP,
    CircuitPhaseConfiguration.threePhase =>
      pole == BreakerPoleConfiguration.threeP ||
          pole == BreakerPoleConfiguration.fourP,
  };

  CalculationSourceReference _catalogReference(String rowId) =>
      CalculationSourceReference(
        sourceId: 'load-schedule-circuit-breaker-catalog',
        label: 'LOAD-SCHEDULE-V1 CP3 approved circuit breaker catalog',
        rowId: rowId,
        sourceVersion: CircuitBreakerCatalog.version,
      );
}
