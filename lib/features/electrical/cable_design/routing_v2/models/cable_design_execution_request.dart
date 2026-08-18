import '../../enums/cable_design_routing_mode.dart';
import '../../../voltage_drop/models/voltage_drop_cable_selection_request.dart';
import 'cable_design_request_v2.dart';
import 'voltage_drop_continuation_context_v2.dart';

class CableDesignExecutionRequest {
  const CableDesignExecutionRequest({
    required this.routingMode,
    this.legacyRequest,
    this.routingV2CableRequest,
    this.routingV2VoltageDropContext,
  });
  final CableDesignRoutingMode routingMode;
  final VoltageDropCableSelectionRequest? legacyRequest;
  final CableDesignRequestV2? routingV2CableRequest;
  final VoltageDropContinuationContextV2? routingV2VoltageDropContext;
}
