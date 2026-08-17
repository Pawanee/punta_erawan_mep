import '../../enums/ampacity_table.dart';
import '../enums/ampacity_routing_status.dart';
import 'ampacity_routing_context.dart';
import 'cable_type_profile.dart';
import 'installation_reference_resolution.dart';

/// Complete dry-run outcome including engineering resolution traceability.
class AmpacityRoutingResult {
  const AmpacityRoutingResult({
    required this.status,
    required this.cableProfile,
    required this.installationResolution,
    required this.context,
    required this.ampacityTable,
    required this.sourceColumnId,
    required this.sourceReferences,
    required this.reason,
    required this.missingDimensions,
    required this.ambiguityCandidates,
  });
  final AmpacityRoutingStatus status;
  final CableTypeProfile cableProfile;
  final InstallationReferenceResolution installationResolution;
  final AmpacityRoutingContext? context;
  final AmpacityTable? ampacityTable;
  final String? sourceColumnId;
  final List<String> sourceReferences;
  final String? reason;
  final List<String> missingDimensions;
  final List<String> ambiguityCandidates;
}
