import 'dart:math' as math;

import '../../cable_design/enums/phase_system.dart';
import '../../cable_design/routing_v2/enums/ampacity_routing_status.dart';
import '../../cable_design/routing_v2/enums/routing_electrical_system.dart';
import '../../cable_design/routing_v2/models/cable_design_request_v2.dart';
import '../../cable_design/routing_v2/services/active_ampacity_orchestrator_v2.dart';
import '../enums/calculation_status.dart';
import '../enums/breaker_pole_configuration.dart';
import '../enums/circuit_breaker_selection_status.dart';
import '../enums/circuit_phase_configuration.dart';
import '../enums/circuit_status.dart';
import '../models/calculation_source_reference.dart';
import '../models/cable_coordination_outcome.dart';
import '../models/cable_coordination_result.dart';
import '../models/circuit_breaker_selection_result.dart';
import '../models/circuit_definition.dart';
import '../models/current_calculation_result.dart';

class LoadScheduleCableCoordinator {
  LoadScheduleCableCoordinator({ActiveAmpacityOrchestratorV2? ampacity})
    : _ampacity = ampacity ?? ActiveAmpacityOrchestratorV2();

  final ActiveAmpacityOrchestratorV2 _ampacity;

  Future<CableCoordinationOutcome> coordinate({
    required CircuitDefinition circuit,
    required CurrentCalculationResult current,
    required CircuitBreakerSelectionResult circuitBreaker,
  }) async {
    if (circuit.status != CircuitStatus.active) {
      return CableCoordinationOutcome(
        cable: CableCoordinationResult.notCalculated(
          reason:
              '${circuit.status.name.toUpperCase()} circuits do not have a load cable selection.',
        ),
        circuitBreaker: circuitBreaker,
      );
    }
    if (current.status != CalculationStatus.calculated ||
        current.designCurrentA == null) {
      return CableCoordinationOutcome(
        cable: CableCoordinationResult.invalid(
          reason: 'ACTIVE cable coordination requires calculated current Ib.',
        ),
        circuitBreaker: circuitBreaker,
      );
    }
    if (circuitBreaker.status != CircuitBreakerSelectionStatus.selected ||
        circuitBreaker.ratedCurrentA == null ||
        circuitBreaker.designCurrentIbA == null) {
      return CableCoordinationOutcome(
        cable: CableCoordinationResult.insufficient(
          reason: 'ACTIVE cable coordination requires a selected breaker.',
        ),
        circuitBreaker: circuitBreaker,
      );
    }
    if (!_close(current.designCurrentA!, circuitBreaker.designCurrentIbA!)) {
      return CableCoordinationOutcome(
        cable: CableCoordinationResult.invalid(
          reason: 'Breaker Ib does not match the calculated circuit current.',
        ),
        circuitBreaker: circuitBreaker,
      );
    }
    if (!_compatiblePole(
      circuit.phaseConfiguration,
      circuitBreaker.poleConfiguration!,
    )) {
      return CableCoordinationOutcome(
        cable: CableCoordinationResult.invalid(
          reason: 'Breaker pole configuration conflicts with circuit phase.',
        ),
        circuitBreaker: circuitBreaker,
      );
    }
    final input = circuit.cableCoordinationInput;
    if (input == null) {
      return CableCoordinationOutcome(
        cable: CableCoordinationResult.insufficient(
          reason: 'Cable routing and installation input is required.',
        ),
        circuitBreaker: circuitBreaker,
      );
    }

    final inA = circuitBreaker.ratedCurrentA!;
    final phaseSystem =
        circuit.phaseConfiguration == CircuitPhaseConfiguration.singlePhase
        ? PhaseSystem.singlePhase
        : PhaseSystem.threePhase;
    final electricalSystem =
        circuit.phaseConfiguration == CircuitPhaseConfiguration.singlePhase
        ? RoutingElectricalSystem.singlePhaseAc
        : RoutingElectricalSystem.threePhaseAc;
    final loadedConductors =
        circuit.phaseConfiguration == CircuitPhaseConfiguration.singlePhase
        ? 2
        : 3;
    final design = await _ampacity.prepare(
      CableDesignRequestV2(
        // Breaker In, not load Ib, is the required ampacity threshold.
        loadCurrent: inA,
        phaseSystem: phaseSystem,
        routingElectricalSystem: electricalSystem,
        loadedConductors: loadedConductors,
        coreType: input.coreType,
        ambientTemperature: input.ambientTemperatureC,
        identity: input.identity,
        engineeringInstallation: input.toEngineeringInstallation(),
        supplementalCableProperties: input.toSupplementalProperties(),
      ),
    );
    if (design.status != AmpacityRoutingStatus.resolved ||
        design.selected == null) {
      return CableCoordinationOutcome(
        cable: _failure(design.status, design.reason),
        circuitBreaker: circuitBreaker,
      );
    }

    final selected = design.selected!;
    final candidate = selected.candidate;
    if (!CableCoordinationResult.approvedTableIds.contains(
      candidate.sourceTableId,
    )) {
      return CableCoordinationOutcome(
        cable: CableCoordinationResult.unsupported(
          reason: 'Resolved route uses a table outside the approved V1 set.',
        ),
        circuitBreaker: circuitBreaker,
      );
    }
    final sourceLabels = <String>{
      ...candidate.sourceReferences,
      ...?design.routingResult?.sourceReferences,
      if (selected.groupingApplication.sourceReference != null)
        selected.groupingApplication.sourceReference!,
      if (selected.temperatureApplication.sourceReference != null)
        selected.temperatureApplication.sourceReference!,
    };
    final references = sourceLabels.indexed
        .map(
          (entry) => CalculationSourceReference(
            sourceId: 'ampacity-${candidate.sourceTableId}-${entry.$1 + 1}',
            label: entry.$2,
            tableId: candidate.sourceTableId,
            columnId: candidate.sourceColumnId,
            rowId: candidate.sizeSqmm.toString(),
          ),
        )
        .toList(growable: false);
    final cable = CableCoordinationResult.coordinated(
      identity: input.identity,
      insulation: candidate.insulation,
      conductorTemperatureClass: candidate.conductorTemperatureClass,
      coreType: candidate.coreType,
      loadedConductors: candidate.loadedConductors,
      sizeSqmm: candidate.sizeSqmm,
      runs: selected.runs,
      baseAmpacityPerRunA: candidate.baseAmpacity,
      correctedAmpacityPerRunA: selected.correctedAmpacityPerRun,
      totalCorrectedCapacityIzA: selected.totalCorrectedCapacity,
      designCurrentIbA: current.designCurrentA!,
      breakerRatedCurrentInA: inA,
      tableId: candidate.sourceTableId,
      installationGroupNumber: candidate.installationGroupNumber,
      sourceColumnId: candidate.sourceColumnId,
      groupingFactor: selected.groupingFactor,
      temperatureFactor: selected.temperatureFactor,
      sourceReferences: references,
    );
    return CableCoordinationOutcome(
      cable: cable,
      circuitBreaker: circuitBreaker.markCableCoordinated(),
    );
  }

  CableCoordinationResult _failure(
    AmpacityRoutingStatus status,
    String? reason,
  ) {
    final message = reason?.trim().isNotEmpty == true
        ? reason!
        : 'Ampacity routing failed without a usable result.';
    return switch (status) {
      AmpacityRoutingStatus.insufficient =>
        CableCoordinationResult.insufficient(reason: message),
      AmpacityRoutingStatus.ambiguous => CableCoordinationResult.ambiguous(
        reason: message,
      ),
      AmpacityRoutingStatus.unsupported => CableCoordinationResult.unsupported(
        reason: message,
      ),
      AmpacityRoutingStatus.noMatch || AmpacityRoutingStatus.noCandidate =>
        CableCoordinationResult.noMatch(reason: message),
      AmpacityRoutingStatus.resolved => CableCoordinationResult.invalid(
        reason: message,
      ),
    };
  }

  bool _compatiblePole(
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

  bool _close(double left, double right) {
    final scale = math.max(1.0, math.max(left.abs(), right.abs()));
    return (left - right).abs() <= 1e-9 * scale;
  }
}
