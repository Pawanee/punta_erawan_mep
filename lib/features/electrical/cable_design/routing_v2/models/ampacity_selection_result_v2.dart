import '../enums/ampacity_selection_status_v2.dart';
import 'ampacity_selected_candidate_v2.dart';

class AmpacitySelectionResultV2 {
  const AmpacitySelectionResultV2({
    required this.status,
    required this.selected,
    required this.reason,
    required this.voltageDropVerified,
  });
  final AmpacitySelectionStatusV2 status;
  final AmpacitySelectedCandidateV2? selected;
  final String? reason;
  final bool voltageDropVerified;
}
