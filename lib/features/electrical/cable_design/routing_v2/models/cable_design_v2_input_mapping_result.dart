import '../enums/cable_design_v2_input_mapping_status.dart';
import 'cable_design_request_v2.dart';
import 'voltage_drop_continuation_context_v2.dart';

class CableDesignV2InputMappingResult {
  const CableDesignV2InputMappingResult({
    required this.status,
    this.ampacityRequest,
    this.voltageDropContext,
    this.missingFields = const [],
    this.reason,
  });
  final CableDesignV2InputMappingStatus status;
  final CableDesignRequestV2? ampacityRequest;
  final VoltageDropContinuationContextV2? voltageDropContext;
  final List<String> missingFields;
  final String? reason;
  bool get isReady =>
      status == CableDesignV2InputMappingStatus.ready &&
      ampacityRequest != null;
}
