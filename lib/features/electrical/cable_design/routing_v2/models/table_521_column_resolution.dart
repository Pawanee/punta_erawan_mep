import '../enums/ampacity_routing_status.dart';

class Table521ColumnResolution {
  const Table521ColumnResolution({
    required this.status,
    required this.columnId,
    required this.reason,
    required this.missingDimensions,
    required this.candidates,
  });
  final AmpacityRoutingStatus status;
  final String? columnId;
  final String? reason;
  final List<String> missingDimensions;
  final List<String> candidates;
}
