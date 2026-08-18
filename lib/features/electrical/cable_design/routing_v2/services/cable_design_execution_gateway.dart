import '../../enums/cable_design_routing_mode.dart';
import '../../../voltage_drop/services/voltage_drop_design_engine.dart';
import '../models/cable_design_execution_request.dart';
import '../models/cable_design_execution_result.dart';
import 'combined_cable_design_orchestrator_v2.dart';

class CableDesignExecutionGateway {
  CableDesignExecutionGateway({
    VoltageDropDesignEngine? legacy,
    CombinedCableDesignOrchestratorV2? routingV2,
  }) : _legacy = legacy ?? VoltageDropDesignEngine(),
       _routingV2 = routingV2 ?? CombinedCableDesignOrchestratorV2();
  final VoltageDropDesignEngine _legacy;
  final CombinedCableDesignOrchestratorV2 _routingV2;
  Future<CableDesignExecutionResult> execute(
    CableDesignExecutionRequest request,
  ) async {
    if (request.routingMode == CableDesignRoutingMode.legacy) {
      if (request.legacyRequest == null)
        return CableDesignExecutionResult(
          routingMode: request.routingMode,
          reason: 'Legacy request is required.',
        );
      return CableDesignExecutionResult(
        routingMode: request.routingMode,
        legacyResult: await _legacy.design(request.legacyRequest!),
      );
    }
    final v2 = request.routingV2CableRequest;
    if (v2 == null || v2.routingMode != CableDesignRoutingMode.routingV2)
      return CableDesignExecutionResult(
        routingMode: request.routingMode,
        reason: 'Routing v2 request is required.',
      );
    return CableDesignExecutionResult(
      routingMode: request.routingMode,
      routingV2Result: await _routingV2.design(
        v2,
        voltageDropContext: request.routingV2VoltageDropContext,
      ),
    );
  }
}
