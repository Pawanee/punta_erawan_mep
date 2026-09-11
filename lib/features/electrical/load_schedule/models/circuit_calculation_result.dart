import 'dart:math' as math;

import '../enums/breaker_pole_configuration.dart';
import '../enums/breaker_selection_mode.dart';
import '../enums/calculation_status.dart';
import '../enums/cable_selection_status.dart';
import '../enums/circuit_phase_configuration.dart';
import '../enums/circuit_breaker_selection_status.dart';
import '../enums/circuit_status.dart';
import '../enums/grounding_conductor_selection_status.dart';
import '../enums/phase_assignment.dart';
import '../enums/voltage_basis.dart';
import '../enums/voltage_drop_calculation_status.dart';
import 'calculation_step_result.dart';
import 'cable_coordination_result.dart';
import 'circuit_breaker_selection_result.dart';
import 'current_calculation_result.dart';
import 'grounding_conductor_selection_result.dart';
import 'voltage_drop_calculation_result.dart';

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
    if ((circuitStatus == CircuitStatus.spare ||
            circuitStatus == CircuitStatus.space) &&
        (cable.status != CableSelectionStatus.notCalculated ||
            voltageDrop.status != VoltageDropCalculationStatus.notCalculated)) {
      throw ArgumentError(
        'SPARE and SPACE circuits require cable and voltage drop '
        'status notCalculated.',
      );
    }
    if (circuitStatus == CircuitStatus.space &&
        (_hasCalculatedEquipment || assignedPhase != null)) {
      throw ArgumentError('SPACE circuits cannot contain equipment results.');
    }
    if (circuitStatus == CircuitStatus.spare &&
        (current.status == CalculationStatus.calculated ||
            cable.status == CableSelectionStatus.coordinated ||
            voltageDrop.status == VoltageDropCalculationStatus.calculated)) {
      throw ArgumentError(
        'SPARE circuits cannot contain calculated load results.',
      );
    }
    _validateCircuitBreaker();
    _validateGrounding();
  }

  final int circuitNo;
  final CircuitStatus circuitStatus;
  final CircuitPhaseConfiguration phaseConfiguration;
  final CircuitValidationStatus validationStatus;
  final List<String> validationReasons;
  final PhaseAssignment? assignedPhase;
  final CurrentCalculationResult current;
  final CableCoordinationResult cable;
  final VoltageDropCalculationResult voltageDrop;
  final CircuitBreakerSelectionResult circuitBreaker;
  final GroundingConductorSelectionResult ground;
  final PendingEngineeringResult conduit;

  void _validateCircuitBreaker() {
    if (cable.status == CableSelectionStatus.coordinated &&
        circuitBreaker.status != CircuitBreakerSelectionStatus.selected) {
      throw ArgumentError(
        'A coordinated cable requires a selected circuit breaker.',
      );
    }
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
          circuitBreaker.cableCoordinationStatus == null) {
        throw ArgumentError(
          'ACTIVE selected breaker requires calculated current and cable '
          'coordination status.',
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
      if (cable.status == CableSelectionStatus.coordinated) {
        if (circuitBreaker.cableCoordinationStatus !=
                CableCoordinationStatus.coordinated ||
            cable.designCurrentIbA == null ||
            cable.breakerRatedCurrentInA == null) {
          throw ArgumentError(
            'Coordinated cable requires a coordinated breaker payload.',
          );
        }
        final cableIb = cable.designCurrentIbA!;
        final cableIn = cable.breakerRatedCurrentInA!;
        final inA = circuitBreaker.ratedCurrentA!;
        if (!_close(currentIb, cableIb) || !_close(inA, cableIn)) {
          throw ArgumentError(
            'Cable Ib/In must match current and circuit breaker results.',
          );
        }
        final expectedLoadedConductors =
            phaseConfiguration == CircuitPhaseConfiguration.singlePhase ? 2 : 3;
        if (cable.loadedConductors != expectedLoadedConductors) {
          throw ArgumentError(
            'Cable loaded-conductor count is incompatible with circuit phase.',
          );
        }
      } else if (circuitBreaker.cableCoordinationStatus !=
          CableCoordinationStatus.pendingCableSelection) {
        throw ArgumentError(
          'An unresolved cable requires pending breaker coordination.',
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
    _validateVoltageDrop();
  }

  void _validateVoltageDrop() {
    if (voltageDrop.status != VoltageDropCalculationStatus.calculated) {
      return;
    }
    if (circuitStatus != CircuitStatus.active ||
        current.status != CalculationStatus.calculated ||
        cable.status != CableSelectionStatus.coordinated) {
      throw ArgumentError(
        'Calculated voltage drop requires an ACTIVE circuit with calculated '
        'current and coordinated cable.',
      );
    }
    if (!_close(voltageDrop.designCurrentIbA!, current.designCurrentA!) ||
        !_close(voltageDrop.designCurrentIbA!, cable.designCurrentIbA!) ||
        !_close(voltageDrop.sizeSqmm!, cable.sizeSqmm!) ||
        voltageDrop.runs != cable.runs ||
        voltageDrop.identity != cable.identity ||
        voltageDrop.insulation != cable.insulation ||
        voltageDrop.coreType!.name != cable.coreType!.name) {
      throw ArgumentError(
        'Voltage-drop cable/current facts must match CP2 and CP4 results.',
      );
    }
    final singlePhase =
        phaseConfiguration == CircuitPhaseConfiguration.singlePhase;
    if (singlePhase !=
            (voltageDrop.voltageBasis == VoltageBasis.lineToNeutral) ||
        singlePhase != (voltageDrop.phase!.name == 'singlePhase')) {
      throw ArgumentError(
        'Voltage-drop phase and voltage basis must match the circuit.',
      );
    }
  }

  void _validateGrounding() {
    if (circuitStatus != CircuitStatus.active) {
      if (ground.status != GroundingConductorSelectionStatus.notCalculated) {
        throw ArgumentError(
          'SPARE and SPACE circuits require grounding status notCalculated.',
        );
      }
      return;
    }
    if (ground.status != GroundingConductorSelectionStatus.selected) {
      return;
    }
    if (circuitBreaker.status != CircuitBreakerSelectionStatus.selected ||
        circuitBreaker.ratedCurrentA == null ||
        !_close(ground.ratedCurrentA!, circuitBreaker.ratedCurrentA!)) {
      throw ArgumentError(
        'Selected grounding conductor must match the selected breaker.',
      );
    }
    if (ground.phaseConductorSizeSqmm != null) {
      if (cable.status != CableSelectionStatus.coordinated ||
          !_close(ground.phaseConductorSizeSqmm!, cable.sizeSqmm!)) {
        throw ArgumentError(
          'Grounding phase-conductor snapshot must match the CP4 cable.',
        );
      }
    }
  }

  bool _close(double left, double right) {
    final scale = math.max(1.0, math.max(left.abs(), right.abs()));
    return (left - right).abs() <= 1e-9 * scale;
  }

  bool get _hasCalculatedEquipment =>
      current.status == CalculationStatus.calculated ||
      cable.status == CableSelectionStatus.coordinated ||
      voltageDrop.status == VoltageDropCalculationStatus.calculated ||
      circuitBreaker.status != CircuitBreakerSelectionStatus.notCalculated ||
      ground.status != GroundingConductorSelectionStatus.notCalculated ||
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
        cable: CableCoordinationResult.fromJson(
          Map<String, Object?>.from(json['cable'] as Map),
        ),
        voltageDrop: VoltageDropCalculationResult.fromJson(
          Map<String, Object?>.from(json['voltageDrop'] as Map),
        ),
        circuitBreaker: CircuitBreakerSelectionResult.fromJson(
          Map<String, Object?>.from(json['circuitBreaker'] as Map),
        ),
        ground: GroundingConductorSelectionResult.fromJson(
          Map<String, Object?>.from(json['ground'] as Map),
        ),
        conduit: PendingEngineeringResult.fromJson(
          Map<String, Object?>.from(json['conduit'] as Map),
        ),
      );
}
