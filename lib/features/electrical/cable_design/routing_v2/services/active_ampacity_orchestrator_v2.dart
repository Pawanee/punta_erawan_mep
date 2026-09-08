import '../../enums/cable_design_routing_mode.dart';
import '../../enums/ampacity_table.dart';
import '../../enums/cable_type.dart';
import '../../enums/core_type.dart';
import '../../enums/cable_shape.dart';
import '../../enums/conductor_temperature_class.dart';
import '../../enums/phase_system.dart';
import '../../models/cable_routing_identity.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/ampacity_selection_status_v2.dart';
import '../enums/installation_environment.dart';
import '../enums/routing_electrical_system.dart';
import '../enums/voltage_drop_verification_status_v2.dart';
import '../models/ampacity_design_result_v2.dart';
import '../models/ampacity_candidate_v2.dart';
import '../models/ampacity_correction_context_v2.dart';
import '../models/ampacity_selection_request_v2.dart';
import '../models/ampacity_routing_result.dart';
import '../models/cable_design_request_v2.dart';
import '../services/ampacity_candidate_v2_adapter.dart';
import '../services/ampacity_correction_plan_resolver_v2.dart';
import '../services/ampacity_routing_context_builder.dart';
import '../services/ampacity_selection_core_v2.dart';
import '../services/correction_application_resolver_v2.dart';
import '../services/correction_resolver_v2.dart';
import '../services/production_routing_request_adapter.dart';
import '../../repositories/table_5_21_repository.dart';
import '../../repositories/table_5_20_repository.dart';
import '../../repositories/table_5_23_repository.dart';
import '../../repositories/table_5_27_repository.dart';
import '../../repositories/table_5_29_repository.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';

/// Fail-closed V2 ampacity boundary.
///
/// Legacy Cable Design callers remain unchanged. Load Schedule CP4 invokes
/// this boundary explicitly with source-complete Routing V2 input.
class ActiveAmpacityOrchestratorV2 {
  ActiveAmpacityOrchestratorV2({
    ProductionRoutingRequestAdapter? adapter,
    AmpacityRoutingContextBuilder? routing,
    Table520Repository? table520,
    Table521Repository? table521,
    Table523Repository? table523,
    Table527Repository? table527,
    Table529Repository? table529,
    AmpacityCandidateV2Adapter? candidates,
    AmpacitySelectionCoreV2? selectionCore,
    AmpacityCorrectionPlanResolverV2? correctionPlans,
    CorrectionApplicationResolverV2? correctionApplications,
    CorrectionResolverV2? correctionResolver,
  }) : _adapter = adapter ?? ProductionRoutingRequestAdapter(),
       _routing = routing ?? AmpacityRoutingContextBuilder(),
       _table520 = table520 ?? Table520Repository(),
       _table521 = table521 ?? Table521Repository(),
       _table523 = table523 ?? const Table523Repository(),
       _table527 = table527 ?? Table527Repository(),
       _table529 = table529 ?? const Table529Repository(),
       _candidates = candidates ?? const AmpacityCandidateV2Adapter(),
       _selectionCore = selectionCore ?? AmpacitySelectionCoreV2(),
       _correctionPlans =
           correctionPlans ?? const AmpacityCorrectionPlanResolverV2(),
       _correctionApplications =
           correctionApplications ?? CorrectionApplicationResolverV2(),
       // Keep the public `correctionResolver` injection name stable.
       // ignore: prefer_initializing_formals
       _correctionResolver = correctionResolver;
  final ProductionRoutingRequestAdapter _adapter;
  final AmpacityRoutingContextBuilder _routing;
  final Table520Repository _table520;
  final Table521Repository _table521;
  final Table523Repository _table523;
  final Table527Repository _table527;
  final Table529Repository _table529;
  final AmpacityCandidateV2Adapter _candidates;
  final AmpacitySelectionCoreV2 _selectionCore;
  final AmpacityCorrectionPlanResolverV2 _correctionPlans;
  final CorrectionApplicationResolverV2 _correctionApplications;
  final CorrectionResolverV2? _correctionResolver;
  Future<AmpacityDesignResultV2> prepare(CableDesignRequestV2 request) async {
    if (request.routingMode != CableDesignRoutingMode.routingV2) {
      return _result(
        AmpacityRoutingStatus.unsupported,
        'Request is not eligible for Routing v2.',
      );
    }
    if (request.identity == CableRoutingIdentity.iec10 &&
        request.loadedConductors != 2 &&
        request.loadedConductors != 3) {
      return _result(
        AmpacityRoutingStatus.unsupported,
        '60227 IEC 10 supports only the approved Table 5-21 C6/C7 loaded-conductor scopes.',
      );
    }
    if (request.identity == CableRoutingIdentity.nyy) {
      final environments = request.engineeringInstallation?.environments;
      final isUnderground =
          environments?.contains(InstallationEnvironment.underground) == true ||
          environments?.contains(InstallationEnvironment.directBuried) == true;
      if ((request.coreType != CoreType.singleCore && !isUnderground) ||
          (request.loadedConductors != 2 && request.loadedConductors != 3)) {
        return _result(
          AmpacityRoutingStatus.unsupported,
          'NYY is outside its approved core or loaded-conductor scope.',
        );
      }
    }
    if (request.identity == CableRoutingIdentity.iec605021) {
      if ((request.coreType != CoreType.singleCore &&
              request.coreType != CoreType.multiCore) ||
          (request.loadedConductors != 2 && request.loadedConductors != 3)) {
        return _result(
          AmpacityRoutingStatus.unsupported,
          'IEC 60502-1 supports only the approved two/three-loaded-conductor scopes.',
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
      final environments = request.engineeringInstallation?.environments;
      final isUnderground =
          environments?.contains(InstallationEnvironment.underground) == true ||
          environments?.contains(InstallationEnvironment.directBuried) == true;
      final hasApprovedTemperaturePair =
          isUnderground &&
              properties?.insulation == CableInsulation.pvc &&
              properties?.conductorTemperatureClass ==
                  ConductorTemperatureClass.pvc70 ||
          properties?.insulation == CableInsulation.xlpe &&
              properties?.conductorTemperatureClass ==
                  ConductorTemperatureClass.xlpeEpr90;
      if (hasCompleteConstruction &&
          (properties!.cableShape != CableShape.round ||
              !hasApprovedTemperaturePair)) {
        return _result(
          AmpacityRoutingStatus.unsupported,
          'IEC 60502-1 requires explicit round PVC 70°C or XLPE 90°C construction facts.',
        );
      }
    }
    final adapted = await _adapter.adapt(request);
    if (!adapted.isComplete) {
      return _result(adapted.status, 'Production routing input is incomplete.');
    }
    final route = await _routing.build(adapted.request!);
    if (route.status != AmpacityRoutingStatus.resolved) {
      return AmpacityDesignResultV2(
        status: route.status,
        selected: null,
        reason: route.reason,
        voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
        routingResult: route,
      );
    }
    if (route.ampacityTable == null) {
      return AmpacityDesignResultV2(
        status: AmpacityRoutingStatus.unsupported,
        selected: null,
        reason: 'No ampacity table is enabled for the resolved route.',
        voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
        routingResult: route,
      );
    }
    if (route.ampacityTable != AmpacityTable.table521 &&
        !_supportsPublishedElectricalSystem(request)) {
      return AmpacityDesignResultV2(
        status: AmpacityRoutingStatus.noMatch,
        selected: null,
        reason:
            'The loaded-conductor count is incompatible with the supplied electrical system.',
        voltageDropStatus: VoltageDropVerificationStatusV2.notVerified,
        routingResult: route,
      );
    }
    final candidates = await _sourceCandidates(request, route);
    final selection = await _selectionCore.select(
      AmpacitySelectionRequestV2(
        loadCurrent: request.loadCurrent,
        candidates: candidates,
        correctionResolver:
            _correctionResolver ??
            _PlanCorrectionResolverV2(
              ambientTemperatureC: request.ambientTemperature,
              groupedCircuitCount:
                  request.engineeringInstallation?.groupedCircuitCount,
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

  bool _supportsPublishedElectricalSystem(CableDesignRequestV2 request) {
    final system =
        request.routingElectricalSystem ??
        switch (request.phaseSystem) {
          PhaseSystem.singlePhase => RoutingElectricalSystem.singlePhaseAc,
          PhaseSystem.threePhase => RoutingElectricalSystem.threePhaseAc,
        };
    return switch (request.loadedConductors) {
      2 =>
        system == RoutingElectricalSystem.singlePhaseAc ||
            system == RoutingElectricalSystem.dc,
      3 => system == RoutingElectricalSystem.threePhaseAc,
      _ => false,
    };
  }

  Future<List<AmpacityCandidateV2>> _sourceCandidates(
    CableDesignRequestV2 request,
    AmpacityRoutingResult route,
  ) async {
    final context = route.context!;
    final all = switch (route.ampacityTable as AmpacityTable) {
      AmpacityTable.table520 => _candidates.fromTable520(
        rows: await _table520.loadTable(
          cableType: _legacyCableType(request.identity!),
        ),
        insulation: CableInsulation.pvc,
        conductorTemperatureClass: ConductorTemperatureClass.pvc70,
      ),
      AmpacityTable.table521 => _candidates.fromTable521(
        data: await _table521.loadTable(),
        sourceColumnId: route.sourceColumnId!,
      ),
      AmpacityTable.table523 => _candidates.fromUndergroundTable(
        rows: await _table523.loadTable(),
        insulation: CableInsulation.pvc,
        conductorTemperatureClass: ConductorTemperatureClass.pvc70,
        routingCableIdentity: request.identity!,
      ),
      AmpacityTable.table527 => _candidates.fromTable527(
        rows: await _table527.loadTable(),
        insulation: CableInsulation.xlpe,
        conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
        routingCableIdentity: request.identity!,
      ),
      AmpacityTable.table529 => _candidates.fromUndergroundTable(
        rows: await _table529.loadTable(),
        insulation: CableInsulation.xlpe,
        conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
        routingCableIdentity: request.identity!,
      ),
    };
    final group = context.installationResolution.reference!.group;
    return all
        .where(
          (candidate) =>
              candidate.installationGroupNumber == group &&
              candidate.loadedConductors == request.loadedConductors &&
              candidate.coreType == request.coreType &&
              candidate.insulation == context.insulation &&
              candidate.conductorTemperatureClass ==
                  context.conductorTemperatureClass &&
              candidate.applicableCableIdentities.contains(request.identity),
        )
        .toList(growable: false);
  }

  CableType _legacyCableType(CableRoutingIdentity identity) =>
      CableType.values.singleWhere((type) => type.code == identity.code);

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
    required this.groupedCircuitCount,
    required this.plans,
    required this.applications,
  });

  final double ambientTemperatureC;
  final int? groupedCircuitCount;
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
      groupedCircuitCount: groupedCircuitCount,
    );
    return applications.resolve(
      plan: plan,
      candidate: candidate,
      ambientTemperatureC: ambientTemperatureC,
    );
  }
}
