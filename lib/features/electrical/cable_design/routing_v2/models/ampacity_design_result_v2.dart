import '../enums/ampacity_routing_status.dart';
import '../enums/voltage_drop_verification_status_v2.dart';
import 'ampacity_selected_candidate_v2.dart';
import 'ampacity_candidate_v2.dart';
import 'ampacity_routing_result.dart';

class AmpacityDesignResultV2 {
  const AmpacityDesignResultV2({
    required this.status,
    required this.selected,
    required this.reason,
    required this.voltageDropStatus,
    this.routingResult,
    this.candidates = const [],
  });
  final AmpacityRoutingStatus status;
  final AmpacitySelectedCandidateV2? selected;
  final String? reason;
  final VoltageDropVerificationStatusV2 voltageDropStatus;
  final AmpacityRoutingResult? routingResult;

  /// Prepared source-faithful candidates only; selection remains pending.
  final List<AmpacityCandidateV2> candidates;
}
