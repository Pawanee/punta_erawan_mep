import '../../enums/cable_design_routing_mode.dart';
import '../enums/cable_design_workflow.dart';

/// Explicit activation contract for choosing the isolated Advanced workflow.
/// It intentionally has no relationship to populated V2 input fields.
class CableDesignWorkflowActivation {
  const CableDesignWorkflowActivation({
    this.workflow = CableDesignWorkflow.legacy,
  });

  final CableDesignWorkflow workflow;

  bool get isAdvancedCableDesign =>
      workflow == CableDesignWorkflow.advancedCableDesign;

  CableDesignRoutingMode get routingMode => isAdvancedCableDesign
      ? CableDesignRoutingMode.routingV2
      : CableDesignRoutingMode.legacy;
}
