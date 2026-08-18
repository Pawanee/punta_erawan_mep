import '../enums/cable_design_execution_controller_status_v2.dart';
import '../enums/cable_design_v2_presentation_status.dart';
import '../enums/combined_cable_design_status_v2.dart';
import '../models/ampacity_design_result_v2.dart';
import '../models/ampacity_selected_candidate_v2.dart';
import '../models/cable_design_execution_controller_result_v2.dart';
import '../models/cable_design_v2_presentation_state.dart';
import '../models/resolved_correction_application_v2.dart';
import '../models/voltage_drop_continuation_context_v2.dart';
import '../models/voltage_drop_verification_result_v2.dart';

/// Pure mapping from completed V2 execution data to UI-ready presentation.
/// It neither executes a design nor makes engineering decisions.
class CableDesignV2ResultPresenter {
  const CableDesignV2ResultPresenter();

  CableDesignV2PresentationState present(
    CableDesignExecutionControllerResultV2 result,
  ) {
    switch (result.status) {
      case CableDesignExecutionControllerStatusV2.insufficient:
        return CableDesignV2PresentationState(
          status: CableDesignV2PresentationStatus.needsInput,
          headline: 'More design input is required',
          message: result.reason ?? 'Complete the required V2 design inputs.',
          missingInputs: List.unmodifiable(result.adaptation.missingFields),
        );
      case CableDesignExecutionControllerStatusV2.invalid:
        return CableDesignV2PresentationState(
          status: CableDesignV2PresentationStatus.invalidInput,
          headline: 'Design input is invalid',
          message: result.reason ?? 'Review the supplied V2 design inputs.',
          missingInputs: List.unmodifiable(result.adaptation.missingFields),
        );
      case CableDesignExecutionControllerStatusV2.completed:
        return _presentCompleted(result);
    }
  }

  CableDesignV2PresentationState _presentCompleted(
    CableDesignExecutionControllerResultV2 controller,
  ) {
    final combined = controller.execution?.routingV2Result;
    if (combined == null) {
      return CableDesignV2PresentationState(
        status: CableDesignV2PresentationStatus.unsupported,
        headline: 'Routing v2 result is unavailable',
        message: controller.reason ?? 'No V2 design result was returned.',
      );
    }
    final context = controller.adaptation.request?.routingV2VoltageDropContext;
    final selected = _selected(controller, combined.ampacityResult.selected);
    final ampacity = _ampacity(combined.ampacityResult);
    final voltageDrop = _voltageDrop(combined.voltageDropResult, context);
    final copy = _statusCopy(combined.status, combined.ampacityResult.reason);
    return CableDesignV2PresentationState(
      status: copy.status,
      headline: copy.headline,
      message: copy.message,
      selectedDesign: selected,
      ampacitySummary: ampacity,
      voltageDropSummary: voltageDrop,
    );
  }

  CableDesignV2SelectedDesignPresentation? _selected(
    CableDesignExecutionControllerResultV2 controller,
    AmpacitySelectedCandidateV2? selected,
  ) {
    if (selected == null) return null;
    return CableDesignV2SelectedDesignPresentation(
      cableIdentityDisplay:
          controller.adaptation.request?.routingV2CableRequest?.identity?.code,
      cableSizeSqmm: selected.candidate.sizeSqmm,
      runs: selected.runs,
      currentPerRun: selected.currentPerRun,
      baseAmpacity: selected.candidate.baseAmpacity,
      correctedAmpacityPerRun: selected.correctedAmpacityPerRun,
    );
  }

  CableDesignV2AmpacityPresentation _ampacity(AmpacityDesignResultV2 result) {
    final selected = result.selected;
    final candidate = selected?.candidate;
    final corrections = selected == null
        ? const <CableDesignV2CorrectionPresentation>[]
        : [
            _correction(
              'Temperature correction',
              selected.temperatureApplication,
            ),
            _correction('Grouping correction', selected.groupingApplication),
          ];
    final references = <String>{...?candidate?.sourceReferences};
    final correctionReferences = corrections
        .map((correction) => correction.sourceReference)
        .whereType<String>()
        .toList(growable: false);
    return CableDesignV2AmpacityPresentation(
      status: result.status,
      installationGroupNumber: candidate?.installationGroupNumber,
      sourceTableId: candidate?.sourceTableId,
      sourceColumnId: candidate?.sourceColumnId,
      baseAmpacity: candidate?.baseAmpacity,
      correctedAmpacityPerRun: selected?.correctedAmpacityPerRun,
      corrections: List.unmodifiable(corrections),
      sourceReferences: List.unmodifiable(references),
      correctionReferences: List.unmodifiable(correctionReferences),
      reason: result.reason,
    );
  }

  CableDesignV2CorrectionPresentation _correction(
    String name,
    ResolvedCorrectionApplicationV2 application,
  ) => CableDesignV2CorrectionPresentation(
    name: name,
    state: application.state,
    factor: application.factor,
    sourceReference: application.sourceReference,
    reason: application.reason,
  );

  CableDesignV2VoltageDropPresentation _voltageDrop(
    VoltageDropVerificationResultV2 result,
    VoltageDropContinuationContextV2? context,
  ) => CableDesignV2VoltageDropPresentation(
    status: result.status,
    sourceTableId: result.tableId,
    mvPerAperM: result.mvPerAperM,
    voltageDropV: result.voltageDropV,
    voltageDropPercent: result.voltageDropPercent,
    allowableVoltageDropPercent: result.allowableVoltageDropPercent,
    marginPercent: result.marginPercent,
    circuitLengthM: context?.lengthM,
    phase: context?.phase,
    installationGroup: context?.installationGroup,
    insulation: context?.insulation,
    coreType: context?.coreType,
    sourceReferences: List.unmodifiable(result.sourceReferences),
    reason: result.reason,
  );

  _StatusCopy _statusCopy(
    CombinedCableDesignStatusV2 status,
    String? reason,
  ) => switch (status) {
    CombinedCableDesignStatusV2.resolved => const _StatusCopy(
      CableDesignV2PresentationStatus.voltageDropVerified,
      'Cable design verified',
      'Ampacity and voltage drop are verified.',
    ),
    CombinedCableDesignStatusV2.ampacityInsufficient => _StatusCopy(
      CableDesignV2PresentationStatus.ampacityUnresolved,
      'Ampacity input is incomplete',
      reason ?? 'Complete the ampacity-routing inputs.',
    ),
    CombinedCableDesignStatusV2.ampacityAmbiguous => _StatusCopy(
      CableDesignV2PresentationStatus.ampacityUnresolved,
      'Ampacity routing is ambiguous',
      reason ?? 'The supplied conditions match more than one source.',
    ),
    CombinedCableDesignStatusV2.ampacityNoMatch => _StatusCopy(
      CableDesignV2PresentationStatus.ampacityUnresolved,
      'Ampacity source does not match',
      reason ?? 'No approved source combination matches the supplied facts.',
    ),
    CombinedCableDesignStatusV2.ampacityUnsupported => _StatusCopy(
      CableDesignV2PresentationStatus.unsupported,
      'Ampacity routing is unsupported',
      reason ?? 'The requested ampacity route is not supported.',
    ),
    CombinedCableDesignStatusV2.ampacityNoCandidate => _StatusCopy(
      CableDesignV2PresentationStatus.ampacityUnresolved,
      'No ampacity candidate was selected',
      reason ?? 'No source-backed candidate satisfies the request.',
    ),
    CombinedCableDesignStatusV2.voltageDropNotVerified => const _StatusCopy(
      CableDesignV2PresentationStatus.voltageDropNotVerified,
      'Voltage drop not verified',
      'Ampacity is available; voltage-drop facts were not supplied.',
    ),
    CombinedCableDesignStatusV2.voltageDropInsufficient => const _StatusCopy(
      CableDesignV2PresentationStatus.voltageDropInsufficient,
      'Voltage-drop input is incomplete',
      'Ampacity remains available; complete voltage-drop input to verify it.',
    ),
    CombinedCableDesignStatusV2.voltageDropFailed => const _StatusCopy(
      CableDesignV2PresentationStatus.voltageDropFailed,
      'Voltage drop failed',
      'The selected ampacity design is retained; no automatic change was made.',
    ),
    CombinedCableDesignStatusV2.unsupported => const _StatusCopy(
      CableDesignV2PresentationStatus.unsupported,
      'Voltage-drop context is unsupported',
      'The supplied voltage-drop context is not supported.',
    ),
  };
}

class _StatusCopy {
  const _StatusCopy(this.status, this.headline, this.message);
  final CableDesignV2PresentationStatus status;
  final String headline;
  final String message;
}
