import '../enums/cable_design_execution_caller_adaptation_status.dart';
import '../enums/cable_design_execution_controller_status_v2.dart';
import '../models/cable_design_execution_caller_input.dart';
import '../models/cable_design_execution_controller_result_v2.dart';
import 'cable_design_execution_caller_adapter.dart';
import 'cable_design_execution_gateway.dart';

/// Non-UI composition boundary for caller adaptation and branch execution.
///
/// This service contains no engineering routing or result translation.
class CableDesignExecutionControllerV2 {
  CableDesignExecutionControllerV2({
    CableDesignExecutionCallerAdapter? callerAdapter,
    CableDesignExecutionGateway? gateway,
  }) : _callerAdapter =
           callerAdapter ?? const CableDesignExecutionCallerAdapter(),
       _gateway = gateway ?? CableDesignExecutionGateway();

  final CableDesignExecutionCallerAdapter _callerAdapter;
  final CableDesignExecutionGateway _gateway;

  Future<CableDesignExecutionControllerResultV2> execute(
    CableDesignExecutionCallerInput input,
  ) async {
    final adaptation = _callerAdapter.adapt(input);
    if (!adaptation.isReady) {
      return CableDesignExecutionControllerResultV2(
        status: switch (adaptation.status) {
          CableDesignExecutionCallerAdaptationStatus.insufficient =>
            CableDesignExecutionControllerStatusV2.insufficient,
          CableDesignExecutionCallerAdaptationStatus.invalid =>
            CableDesignExecutionControllerStatusV2.invalid,
          CableDesignExecutionCallerAdaptationStatus.ready =>
            CableDesignExecutionControllerStatusV2.invalid,
        },
        adaptation: adaptation,
        reason: adaptation.reason,
      );
    }

    final execution = await _gateway.execute(adaptation.request!);
    return CableDesignExecutionControllerResultV2(
      status: CableDesignExecutionControllerStatusV2.completed,
      adaptation: adaptation,
      execution: execution,
      reason: execution.reason,
    );
  }
}
