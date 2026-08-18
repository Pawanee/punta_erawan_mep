import '../enums/cable_design_execution_caller_adaptation_status.dart';
import 'cable_design_execution_request.dart';

/// Non-throwing result for caller-side execution request preparation.
class CableDesignExecutionCallerAdaptationResult {
  const CableDesignExecutionCallerAdaptationResult({
    required this.status,
    required this.request,
    this.missingFields = const [],
    this.reason,
  });

  final CableDesignExecutionCallerAdaptationStatus status;
  final CableDesignExecutionRequest? request;
  final List<String> missingFields;
  final String? reason;

  bool get isReady =>
      status == CableDesignExecutionCallerAdaptationStatus.ready &&
      request != null;
}
