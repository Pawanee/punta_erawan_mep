import '../../enums/cable_design_routing_mode.dart';
import '../enums/cable_design_execution_caller_adaptation_status.dart';
import '../models/cable_design_execution_caller_adaptation_result.dart';
import '../models/cable_design_execution_caller_input.dart';
import '../models/cable_design_execution_request.dart';

/// Prepares branch-specific execution requests from explicit caller input.
///
/// It never invokes the gateway and does not infer physical routing or
/// voltage-drop facts from legacy fields or ampacity sources.
class CableDesignExecutionCallerAdapter {
  const CableDesignExecutionCallerAdapter();

  CableDesignExecutionCallerAdaptationResult adapt(
    CableDesignExecutionCallerInput input,
  ) {
    if (input.routingMode == CableDesignRoutingMode.legacy) {
      final legacy = input.legacyRequest;
      if (legacy == null) {
        return const CableDesignExecutionCallerAdaptationResult(
          status: CableDesignExecutionCallerAdaptationStatus.insufficient,
          request: null,
          missingFields: ['legacyRequest'],
          reason: 'Legacy request is required.',
        );
      }
      return CableDesignExecutionCallerAdaptationResult(
        status: CableDesignExecutionCallerAdaptationStatus.ready,
        request: CableDesignExecutionRequest(
          routingMode: CableDesignRoutingMode.legacy,
          legacyRequest: legacy,
        ),
      );
    }

    final v2 = input.routingV2CableRequest;
    if (v2 == null) {
      return const CableDesignExecutionCallerAdaptationResult(
        status: CableDesignExecutionCallerAdaptationStatus.insufficient,
        request: null,
        missingFields: ['routingV2CableRequest'],
        reason: 'Routing v2 cable request is required.',
      );
    }
    if (v2.routingMode != CableDesignRoutingMode.routingV2) {
      return const CableDesignExecutionCallerAdaptationResult(
        status: CableDesignExecutionCallerAdaptationStatus.invalid,
        request: null,
        reason: 'Routing v2 caller input requires routingMode = routingV2.',
      );
    }

    final missing = <String>[];
    if (v2.routingCableIdentity == null) {
      missing.add('routingV2CableRequest.routingCableIdentity');
    }
    final installation = v2.engineeringInstallation;
    if (installation == null) {
      missing.add('routingV2CableRequest.engineeringInstallation');
    } else {
      if (installation.environments == null ||
          installation.environments!.isEmpty) {
        missing.add('engineeringInstallation.environments');
      }
      if (installation.supports == null || installation.supports!.isEmpty) {
        missing.add('engineeringInstallation.supports');
      }
    }
    if (missing.isNotEmpty) {
      return CableDesignExecutionCallerAdaptationResult(
        status: CableDesignExecutionCallerAdaptationStatus.insufficient,
        request: null,
        missingFields: List.unmodifiable(missing),
        reason: 'Routing v2 caller input is incomplete.',
      );
    }

    return CableDesignExecutionCallerAdaptationResult(
      status: CableDesignExecutionCallerAdaptationStatus.ready,
      request: CableDesignExecutionRequest(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: v2,
        routingV2VoltageDropContext: input.routingV2VoltageDropContext,
      ),
    );
  }
}
