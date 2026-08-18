import '../enums/resolved_correction_state_v2.dart';

class ResolvedCorrectionApplicationV2 {
  const ResolvedCorrectionApplicationV2.applied(
    this.factor,
    this.sourceReference,
  ) : state = ResolvedCorrectionStateV2.applied,
      reason = null;
  const ResolvedCorrectionApplicationV2.notRequired(
    this.reason,
    this.sourceReference,
  ) : state = ResolvedCorrectionStateV2.notRequired,
      factor = null;
  const ResolvedCorrectionApplicationV2.unresolved(this.reason)
    : state = ResolvedCorrectionStateV2.unresolved,
      factor = null,
      sourceReference = null;
  final ResolvedCorrectionStateV2 state;
  final double? factor;
  final String? sourceReference;
  final String? reason;
}
