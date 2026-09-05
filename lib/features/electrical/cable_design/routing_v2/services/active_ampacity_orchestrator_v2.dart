import '../../enums/cable_design_routing_mode.dart';
import '../../enums/ampacity_table.dart';
import '../../enums/core_type.dart';
import '../../enums/cable_shape.dart';
import '../../enums/conductor_temperature_class.dart';
import '../../models/cable_routing_identity.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/ampacity_selection_status_v2.dart';
import '../enums/voltage_drop_verification_status_v2.dart';
import '../models/ampacity_design_result_v2.dart';
import '../models/ampacity_candidate_v2.dart';
import '../models/ampacity_correction_context_v2.dart';
import '../models/ampacity_selection_request_v2.dart';
import '../models/cable_design_request_v2.dart';
import '../services/ampacity_candidate_v2_adapter.dart';
import '../services/ampacity_correction_plan_resolver_v2.dart';
import '../services/ampacity_routing_context_builder.dart';
import '../services/ampacity_selection_core_v2.dart';
import '../services/correction_application_resolver_v2.dart';
import '../services/correction_resolver_v2.dart';
import '../services/production_routing_request_adapter.dart';
import '../../repositories/table_5_21_repository.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';

/// Parallel, fail-closed V2 ampacity boundary. Not used by the active engine.
class ActiveAmpacityOrchestratorV2 {
  ActiveAmpacityOrchestratorV2({
    ProductionRoutingRequestAdapter? adapter,
    AmpacityRoutingContextBuilder? routing,
    Table521Repository? table521,
    AmpacityCandidateV2Adapter? candidates,
    AmpacitySelectionCoreV2? selectionCore,
    AmpacityCorrectionPlanResolverV2? correctionPlans,
    CorrectionApplicationResolverV2? correctionApplications,
    CorrectionResolverV2? correctionResolver,
  }) : _adapter = adapter ?? ProductionRoutingRequestAdapter(),
       _routing = routing ?? AmpacityRoutingContextBuilder(),
       _table521 = table521 ?? Table521Repository(),
       _candidates = candidates ?? const AmpacityCandidateV2Adapter(),
       _selectionCore = selectionCore ?? AmpacitySelectionCoreV2(),
       _correctionPlans =
           correctionPlans ?? const AmpacityCorrectionPlanResolverV2(),
       _correctionApplications =
           correctionApplications ?? CorrectionApplicationResolverV2(),
       _correctionResolver = correctionResolver;
  final ProductionRoutingRequestAdapter _adapter;
  final AmpacityRoutingContextBuilder _routing;
  final Table521Repository _table521;
  final AmpacityCandidateV2Adapter _candidates;
  final AmpacitySelectionCoreV2 _selectionCore;
  final AmpacityCorrectionPlanResolverV2 _correctionPlans;
  final CorrectionApplicationResolverV2 _correctionApplications;
  final CorrectionResolverV2? _correctionResolver;
  Future<AmpacityDesignResultV2> prepare(CableDesignRequestV2 request) async {
    if (request.routingMode != CableDesignRoutingMode.routingV2)
      return _result(
        AmpacityRoutingStatus.unsupported,
        'Request is not eligible for Routing v2.',
      );
    if (request.identity == CableRoutingIdentity.iec10 &&
        request.loadedConductors != 2 &&
        request.loadedConductors != 3) {
      return _result(
        AmpacityRoutingStatus.unsupported,
        '60227 IEC 10 supports only the approved Table 5-21 C6/C7 loaded-conductor scopes.',
      );
    }
    if (request.identity == CableRoutingIdentity.nyy &&
        (request.coreType != CoreType.singleCore ||
            (request.loadedConductors != 2 && request.loadedConductors != 3))) {
      return _result(
        AmpacityRoutingStatus.unsupported,
        'NYY is limited to the approved single-core Table 5-21 C2/C3 scope.',
      );
    }
    if (request.identity == CableRoutingIdentity.iec605021) {
      if (request.coreType != CoreType.singleCore ||
          (request.loadedConductors != 2 && request.loadedConductors != 3)) {
        return _result(
          AmpacityRoutingStatus.unsupported,
          'IEC 60502-1 is limited to the approved single-core Table 5-21 C4/C5 scope.',
        );
      }
      if (request.routingElectricalSystem == null) {
        return _result(
          AmpacityRoutingStatus.insufficient,
          'IEC 60502-1 requires an explicit Routing V2 electrical system.',
        );
      }
      final properties = request.supplementalCableProperties;
      final hasCompleteConstruction =
          properties?.cableShape != null &&
          properties?.insulation != null &&
          properties?.conductorTemperatureClass != null;
      if (hasCompleteConstruction &&
          (properties!.cableShape != CableShape.round ||
              properties.insulation != CableInsulation.xlpe ||
              properties.conductorTemperatureClass !=
                  ConductorTemperatureClass.xlpeEpr90)) {
        return _result(
          AmpacityRoutingStatus.unsupported,
          'IEC 60502-1 C4/C5 requires explicit round XLPE 90°C construction facts.',
        );
      }
    }
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
    final candidates = _candidates.fromTable521(
      data: await _table521.loadTable(),
      sourceColumnId: route.sourceColumnId!,
    );
    final selection = await _selectionCore.select(
      AmpacitySelectionRequestV2(
        loadCurrent: request.loadCurrent,
        candidates: candidates,
        correctionResolver:
            _correctionResolver ??
            _PlanCorrectionResolverV2(
              ambientTemperatureC: request.ambientTemperature,
              plans: _correctionPlans,
              applications: _correctionApplications,
            ),
      ),
    );
    return AmpacityDesignResultV2(
      status: _selectionStatus(selection.status),
      selected: selection.selected,
      reason: selection.reason,
      voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
      routingResult: route,
      candidates: candidates,
    );
  }

  AmpacityRoutingStatus _selectionStatus(
    AmpacitySelectionStatusV2 status,
  ) => switch (status) {
    AmpacitySelectionStatusV2.resolved => AmpacityRoutingStatus.resolved,
    AmpacitySelectionStatusV2.insufficient =>
      AmpacityRoutingStatus.insufficient,
    AmpacitySelectionStatusV2.noCandidate => AmpacityRoutingStatus.noCandidate,
    AmpacitySelectionStatusV2.unsupported => AmpacityRoutingStatus.unsupported,
  };

  AmpacityDesignResultV2 _result(AmpacityRoutingStatus status, String reason) =>
      AmpacityDesignResultV2(
        status: status,
        selected: null,
        reason: reason,
        voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
      );
}

/// Resolves source-approved correction state for each candidate/run evaluation.
/// Run count is deliberately not translated into a grouping factor.
class _PlanCorrectionResolverV2 implements CorrectionResolverV2 {
  const _PlanCorrectionResolverV2({
    required this.ambientTemperatureC,
    required this.plans,
    required this.applications,
  });

  final double ambientTemperatureC;
  final AmpacityCorrectionPlanResolverV2 plans;
  final CorrectionApplicationResolverV2 applications;

  @override
  Future<AmpacityCorrectionContextV2> resolve(
    AmpacityCandidateV2 candidate,
    int runs,
  ) {
    final plan = plans.resolve(
      sourceTableId: candidate.sourceTableId,
      ambientTemperatureC: ambientTemperatureC,
    );
    return applications.resolve(
      plan: plan,
      candidate: candidate,
      ambientTemperatureC: ambientTemperatureC,
    );
  }
}
