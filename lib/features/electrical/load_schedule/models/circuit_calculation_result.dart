import 'dart:math' as math;

import '../enums/breaker_pole_configuration.dart';
import '../enums/breaker_selection_mode.dart';
import '../enums/calculation_status.dart';
import '../enums/circuit_phase_configuration.dart';
import '../enums/circuit_breaker_selection_status.dart';
import '../enums/circuit_status.dart';
import '../enums/phase_assignment.dart';
import 'calculation_step_result.dart';
import 'circuit_breaker_selection_result.dart';
import 'current_calculation_result.dart';

class CircuitCalculationResult {
  CircuitCalculationResult({
    required this.circuitNo,
    required this.circuitStatus,
    required this.phaseConfiguration,
    required this.validationStatus,
    required this.current,
    required this.cable,
    required this.voltageDrop,
    required this.circuitBreaker,
    required this.ground,
    required this.conduit,
    this.assignedPhase,
    List<String> validationReasons = const [],
  }) : validationReasons = List.unmodifiable(validationReasons) {
    if (circuitNo <= 0) {
      throw ArgumentError.value(circuitNo, 'circuitNo');
    }
    if (validationStatus != CircuitValidationStatus.valid &&
        validationReasons.isEmpty) {
      throw ArgumentError('Fail-closed validation requires a reason.');
    }
    if (phaseConfiguration == CircuitPhaseConfiguration.threePhase &&
        assignedPhase != PhaseAssignment.rst) {
      throw ArgumentError('Three-phase results must remain assigned to RST.');
    }
    if (phaseConfiguration == CircuitPhaseConfiguration.singlePhase &&
        assignedPhase == PhaseAssignment.rst) {
      throw ArgumentError('Single-phase results cannot be assigned to RST.');
    }
    if (circuitStatus == CircuitStatus.space &&
        (_hasCalculatedEquipment || assignedPhase != null)) {
      throw ArgumentError('SPACE circuits cannot contain equipment results.');
    }
    if (circuitStatus == CircuitStatus.spare &&
        (current.status == CalculationStatus.calculated ||
            cable.status == CalculationStatus.calculated ||
            voltageDrop.status == CalculationStatus.calculated)) {
      throw ArgumentError(
        'SPARE circuits cannot contain calculated load results.',
      );
    }
    _validateCircuitBreaker();
  }

  final int circuitNo;
  final CircuitStatus circuitStatus;
  final CircuitPhaseConfiguration phaseConfiguration;
  final CircuitValidationStatus validationStatus;
  final List<String> validationReasons;
  final PhaseAssignment? assignedPhase;
  final CurrentCalculationResult current;
  final CalculationStepResult cable;
  final CalculationStepResult voltageDrop;
  final CircuitBreakerSelectionResult circuitBreaker;
  final PendingEngineeringResult ground;
  final PendingEngineeringResult conduit;

  void _validateCircuitBreaker() {
    if (circuitBreaker.status != CircuitBreakerSelectionStatus.selected) {
      return;
    }
    final pole = circuitBreaker.poleConfiguration!;
    final compatiblePole = switch (phaseConfiguration) {
      CircuitPhaseConfiguration.singlePhase =>
        pole == BreakerPoleConfiguration.oneP ||
            pole == BreakerPoleConfiguration.onePPlusN ||
            pole == BreakerPoleConfiguration.twoP,
      CircuitPhaseConfiguration.threePhase =>
        pole == BreakerPoleConfiguration.threeP ||
            pole == BreakerPoleConfiguration.fourP,
    };
    if (!compatiblePole) {
      throw ArgumentError(
        'Breaker pole configuration is incompatible with circuit phase.',
      );
    }
    if (circuitStatus == CircuitStatus.active) {
      if (current.status != CalculationStatus.calculated ||
          circuitBreaker.designCurrentIbA == null ||
          circuitBreaker.cableCoordinationStatus !=
              CableCoordinationStatus.pendingCableSelection) {
        throw ArgumentError(
          'ACTIVE selected breaker requires calculated current and pending '
          'cable coordination.',
        );
      }
      final currentIb = current.designCurrentA!;
      final breakerIb = circuitBreaker.designCurrentIbA!;
      final scale = math.max(1.0, math.max(currentIb.abs(), breakerIb.abs()));
      if ((currentIb - breakerIb).abs() > 1e-9 * scale) {
        throw ArgumentError(
          'Breaker design current must match the calculated circuit current.',
        );
      }
    }
    if (circuitStatus == CircuitStatus.spare &&
        (circuitBreaker.selectionMode != BreakerSelectionMode.manual ||
            circuitBreaker.designCurrentIbA != null ||
            circuitBreaker.currentMarginA != null ||
            circuitBreaker.cableCoordinationStatus != null ||
            circuitBreaker.manualOverrideReason == null ||
            circuitBreaker.manualOverrideReason!.trim().isEmpty)) {
      throw ArgumentError(
        'SPARE selected breaker requires a complete manual-only payload.',
      );
    }
  }

  bool get _hasCalculatedEquipment =>
      current.status == CalculationStatus.calculated ||
      cable.status == CalculationStatus.calculated ||
      voltageDrop.status == CalculationStatus.calculated ||
      circuitBreaker.status != CircuitBreakerSelectionStatus.notCalculated ||
      ground.status == PendingEngineeringStatus.insufficient ||
      conduit.status == PendingEngineeringStatus.insufficient;

  Map<String, Object?> toJson() => {
    'circuitNo': circuitNo,
    'circuitStatus': circuitStatus.name,
    'phaseConfiguration': phaseConfiguration.name,
    'validationStatus': validationStatus.name,
    'validationReasons': validationReasons,
    if (assignedPhase != null) 'assignedPhase': assignedPhase!.name,
    'current': current.toJson(),
    'cable': cable.toJson(),
    'voltageDrop': voltageDrop.toJson(),
    'circuitBreaker': circuitBreaker.toJson(),
    'ground': ground.toJson(),
    'conduit': conduit.toJson(),
  };

  factory CircuitCalculationResult.fromJson(Map<String, Object?> json) =>
      CircuitCalculationResult(
        circuitNo: json['circuitNo'] as int,
        circuitStatus: CircuitStatus.values.byName(
          json['circuitStatus'] as String,
        ),
        phaseConfiguration: CircuitPhaseConfiguration.values.byName(
          json['phaseConfiguration'] as String,
        ),
        validationStatus: CircuitValidationStatus.values.byName(
          json['validationStatus'] as String,
        ),
        validationReasons: (json['validationReasons'] as List).cast<String>(),
        assignedPhase: json['assignedPhase'] == null
            ? null
            : PhaseAssignment.values.byName(json['assignedPhase'] as String),
        current: CurrentCalculationResult.fromJson(
          Map<String, Object?>.from(json['current'] as Map),
        ),
        cable: CalculationStepResult.fromJson(
          Map<String, Object?>.from(json['cable'] as Map),
        ),
        voltageDrop: CalculationStepResult.fromJson(
          Map<String, Object?>.from(json['voltageDrop'] as Map),
        ),
        circuitBreaker: CircuitBreakerSelectionResult.fromJson(
          Map<String, Object?>.from(json['circuitBreaker'] as Map),
        ),
        ground: PendingEngineeringResult.fromJson(
          Map<String, Object?>.from(json['ground'] as Map),
        ),
        conduit: PendingEngineeringResult.fromJson(
          Map<String, Object?>.from(json['conduit'] as Map),
        ),
      );
}
