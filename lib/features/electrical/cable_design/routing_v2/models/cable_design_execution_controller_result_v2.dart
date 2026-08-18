import '../enums/cable_design_execution_controller_status_v2.dart';
import 'cable_design_execution_caller_adaptation_result.dart';
import 'cable_design_execution_result.dart';

/// Branch-preserving result from the non-UI execution controller.
class CableDesignExecutionControllerResultV2 {
  const CableDesignExecutionControllerResultV2({
    required this.status,
    required this.adaptation,
    this.execution,
    this.reason,
  });

  final CableDesignExecutionControllerStatusV2 status;
  final CableDesignExecutionCallerAdaptationResult adaptation;
  final CableDesignExecutionResult? execution;
  final String? reason;
}
