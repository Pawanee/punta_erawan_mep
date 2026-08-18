import '../../enums/cable_design_routing_mode.dart';
import '../../../voltage_drop/models/voltage_drop_design_result.dart';
import 'combined_cable_design_result_v2.dart';

class CableDesignExecutionResult {
  const CableDesignExecutionResult({
    required this.routingMode,
    this.legacyResult,
    this.routingV2Result,
    this.reason,
  });
  final CableDesignRoutingMode routingMode;
  final VoltageDropDesignResult? legacyResult;
  final CombinedCableDesignResultV2? routingV2Result;
  final String? reason;
}
