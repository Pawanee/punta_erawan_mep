import '../../models/cable_design_request.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/combined_cable_design_status_v2.dart';
import '../enums/voltage_drop_verification_status_v2.dart';
import '../models/combined_cable_design_result_v2.dart';
import '../models/voltage_drop_continuation_context_v2.dart';
import '../models/voltage_drop_verification_result_v2.dart';
import 'active_ampacity_orchestrator_v2.dart';
import 'voltage_drop_continuation_service_v2.dart';

class CombinedCableDesignOrchestratorV2 {
  CombinedCableDesignOrchestratorV2({
    ActiveAmpacityOrchestratorV2? ampacity,
    VoltageDropContinuationServiceV2? voltageDrop,
  }) : _ampacity = ampacity ?? ActiveAmpacityOrchestratorV2(),
       _voltageDrop = voltageDrop ?? VoltageDropContinuationServiceV2();
  final ActiveAmpacityOrchestratorV2 _ampacity;
  final VoltageDropContinuationServiceV2 _voltageDrop;
  Future<CombinedCableDesignResultV2> design(
    CableDesignRequest request, {
    VoltageDropContinuationContextV2? voltageDropContext,
  }) async {
    final a = await _ampacity.prepare(request);
    if (a.status != AmpacityRoutingStatus.resolved)
      return CombinedCableDesignResultV2(
        status: _ampacityStatus(a.status),
        ampacityResult: a,
        voltageDropResult: const VoltageDropVerificationResultV2(
          status: VoltageDropVerificationStatusV2.notVerified,
          reason: 'Ampacity unresolved.',
        ),
      );
    final v = await _voltageDrop.verify(
      ampacity: a,
      context: voltageDropContext,
    );
    return CombinedCableDesignResultV2(
      status: switch (v.status) {
        VoltageDropVerificationStatusV2.verified =>
          CombinedCableDesignStatusV2.resolved,
        VoltageDropVerificationStatusV2.failed =>
          CombinedCableDesignStatusV2.voltageDropFailed,
        VoltageDropVerificationStatusV2.insufficient =>
          CombinedCableDesignStatusV2.voltageDropInsufficient,
        VoltageDropVerificationStatusV2.unsupported =>
          CombinedCableDesignStatusV2.unsupported,
        VoltageDropVerificationStatusV2.notVerified =>
          CombinedCableDesignStatusV2.voltageDropNotVerified,
      },
      ampacityResult: a,
      voltageDropResult: v,
    );
  }

  CombinedCableDesignStatusV2 _ampacityStatus(AmpacityRoutingStatus status) =>
      switch (status) {
        AmpacityRoutingStatus.insufficient =>
          CombinedCableDesignStatusV2.ampacityInsufficient,
        AmpacityRoutingStatus.ambiguous =>
          CombinedCableDesignStatusV2.ampacityAmbiguous,
        AmpacityRoutingStatus.noMatch =>
          CombinedCableDesignStatusV2.ampacityNoMatch,
        AmpacityRoutingStatus.unsupported =>
          CombinedCableDesignStatusV2.ampacityUnsupported,
        AmpacityRoutingStatus.noCandidate =>
          CombinedCableDesignStatusV2.ampacityNoCandidate,
        AmpacityRoutingStatus.resolved => CombinedCableDesignStatusV2.resolved,
      };
}
