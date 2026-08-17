import '../enums/ampacity_routing_status.dart';
import 'ampacity_routing_request.dart';

/// Outcome of translating a production request without running active routing.
class ProductionRoutingAdaptationResult {
  const ProductionRoutingAdaptationResult({
    required this.status,
    required this.request,
    required this.missingFields,
  });

  final AmpacityRoutingStatus status;
  final AmpacityRoutingRequest? request;
  final List<String> missingFields;

  bool get isComplete =>
      status == AmpacityRoutingStatus.resolved && request != null;
}
