import '../../enums/cable_design_routing_mode.dart';
import '../../enums/ampacity_table.dart';
import '../../models/cable_design_request.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/voltage_drop_verification_status_v2.dart';
import '../models/ampacity_design_result_v2.dart';
import '../services/ampacity_candidate_v2_adapter.dart';
import '../services/ampacity_routing_context_builder.dart';
import '../services/production_routing_request_adapter.dart';
import '../../repositories/table_5_21_repository.dart';

/// Parallel, fail-closed routing-to-candidate boundary. Not used by active engine.
class ActiveAmpacityOrchestratorV2 {
  ActiveAmpacityOrchestratorV2({
    ProductionRoutingRequestAdapter? adapter,
    AmpacityRoutingContextBuilder? routing,
    Table521Repository? table521,
    AmpacityCandidateV2Adapter? candidates,
  }) : _adapter = adapter ?? ProductionRoutingRequestAdapter(),
       _routing = routing ?? AmpacityRoutingContextBuilder(),
       _table521 = table521 ?? Table521Repository(),
       _candidates = candidates ?? const AmpacityCandidateV2Adapter();
  final ProductionRoutingRequestAdapter _adapter;
  final AmpacityRoutingContextBuilder _routing;
  final Table521Repository _table521;
  final AmpacityCandidateV2Adapter _candidates;
  Future<AmpacityDesignResultV2> prepare(CableDesignRequest request) async {
    if (request.routingMode != CableDesignRoutingMode.routingV2)
      return _result(
        AmpacityRoutingStatus.unsupported,
        'Request is not eligible for Routing v2.',
      );
    final adapted = await _adapter.adapt(request);
    if (!adapted.isComplete)
      return _result(adapted.status, 'Production routing input is incomplete.');
    final route = await _routing.build(adapted.request!);
    if (route.status != AmpacityRoutingStatus.resolved)
      return AmpacityDesignResultV2(
        status: route.status,
        selected: null,
        reason: route.reason,
        voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
        routingResult: route,
      );
    if (route.ampacityTable != AmpacityTable.table521 ||
        route.context?.installationResolution.reference?.group != 3 ||
        route.sourceColumnId == null)
      return AmpacityDesignResultV2(
        status: AmpacityRoutingStatus.unsupported,
        selected: null,
        reason: 'Only resolved Group 3/Table 5-21 routing is supported.',
        voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
        routingResult: route,
      );
    final data = await _table521.loadTable();
    return AmpacityDesignResultV2(
      status: AmpacityRoutingStatus.resolved,
      selected: null,
      reason:
          'Ampacity candidates prepared; correction and selection are pending.',
      voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
      routingResult: route,
      candidates: _candidates.fromTable521(
        data: data,
        sourceColumnId: route.sourceColumnId!,
      ),
    );
  }

  AmpacityDesignResultV2 _result(AmpacityRoutingStatus status, String reason) =>
      AmpacityDesignResultV2(
        status: status,
        selected: null,
        reason: reason,
        voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
      );
}
