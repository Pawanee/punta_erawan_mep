import '../../enums/core_type.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../../../voltage_drop/enums/voltage_drop_installation_group.dart';
import '../../../voltage_drop/enums/voltage_phase.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/cable_design_v2_presentation_status.dart';
import '../enums/resolved_correction_state_v2.dart';
import '../enums/routing_property_source.dart';
import '../enums/voltage_drop_verification_status_v2.dart';

/// Immutable, UI-ready view of an already-computed V2 execution outcome.
class CableDesignV2PresentationState {
  const CableDesignV2PresentationState({
    required this.status,
    required this.headline,
    required this.message,
    this.selectedDesign,
    this.ampacitySummary,
    this.voltageDropSummary,
    this.installationReference,
    this.cableProfile,
    this.missingInputs = const [],
  });

  const CableDesignV2PresentationState.initial()
    : status = CableDesignV2PresentationStatus.initial,
      headline = 'Cable design',
      message = 'Enter explicit design inputs to begin.',
      selectedDesign = null,
      ampacitySummary = null,
      voltageDropSummary = null,
      installationReference = null,
      cableProfile = null,
      missingInputs = const [];

  final CableDesignV2PresentationStatus status;
  final String headline;
  final String message;
  final CableDesignV2SelectedDesignPresentation? selectedDesign;
  final CableDesignV2AmpacityPresentation? ampacitySummary;
  final CableDesignV2VoltageDropPresentation? voltageDropSummary;
  final CableDesignV2InstallationReferencePresentation? installationReference;
  final CableDesignV2CableProfilePresentation? cableProfile;
  final List<String> missingInputs;
}

/// UI-ready provenance already resolved by the Table 5-47 routing path.
class CableDesignV2InstallationReferencePresentation {
  const CableDesignV2InstallationReferencePresentation({
    required this.groupNumber,
    required this.sourceReference,
    required this.characteristics,
  });

  final int groupNumber;
  final String sourceReference;
  final List<String> characteristics;
}

/// UI-ready provenance for intrinsic cable facts already resolved by routing.
class CableDesignV2CableProfilePresentation {
  const CableDesignV2CableProfilePresentation({
    required this.identity,
    required this.sourceReferences,
    required this.properties,
  });

  final String identity;
  final List<String> sourceReferences;
  final List<CableDesignV2PropertyPresentation> properties;
}

class CableDesignV2PropertyPresentation {
  const CableDesignV2PropertyPresentation({
    required this.label,
    required this.value,
    required this.source,
  });

  final String label;
  final String value;
  final RoutingPropertySource source;
}

class CableDesignV2SelectedDesignPresentation {
  const CableDesignV2SelectedDesignPresentation({
    required this.cableIdentityDisplay,
    required this.cableSizeSqmm,
    this.loadedConductors,
    required this.runs,
    required this.currentPerRun,
    required this.baseAmpacity,
    required this.correctedAmpacityPerRun,
  });

  final String? cableIdentityDisplay;
  final double cableSizeSqmm;
  final int? loadedConductors;
  final int runs;
  final double currentPerRun;
  final double baseAmpacity;
  final double correctedAmpacityPerRun;
}

class CableDesignV2CorrectionPresentation {
  const CableDesignV2CorrectionPresentation({
    required this.name,
    required this.state,
    this.factor,
    this.sourceReference,
    this.reason,
  });

  final String name;
  final ResolvedCorrectionStateV2 state;
  final double? factor;
  final String? sourceReference;
  final String? reason;
}

class CableDesignV2AmpacityPresentation {
  const CableDesignV2AmpacityPresentation({
    required this.status,
    this.installationGroupNumber,
    this.sourceTableId,
    this.sourceColumnId,
    this.baseAmpacity,
    this.correctedAmpacityPerRun,
    this.corrections = const [],
    this.sourceReferences = const [],
    this.correctionReferences = const [],
    this.reason,
  });

  final AmpacityRoutingStatus status;
  final int? installationGroupNumber;
  final String? sourceTableId;
  final String? sourceColumnId;
  final double? baseAmpacity;
  final double? correctedAmpacityPerRun;
  final List<CableDesignV2CorrectionPresentation> corrections;
  final List<String> sourceReferences;
  final List<String> correctionReferences;
  final String? reason;
}

class CableDesignV2VoltageDropPresentation {
  const CableDesignV2VoltageDropPresentation({
    required this.status,
    this.sourceTableId,
    this.mvPerAperM,
    this.voltageDropV,
    this.voltageDropPercent,
    this.allowableVoltageDropPercent,
    this.marginPercent,
    this.circuitLengthM,
    this.phase,
    this.installationGroup,
    this.insulation,
    this.coreType,
    this.sourceReferences = const [],
    this.reason,
  });

  final VoltageDropVerificationStatusV2 status;
  final String? sourceTableId;
  final double? mvPerAperM;
  final double? voltageDropV;
  final double? voltageDropPercent;
  final double? allowableVoltageDropPercent;
  final double? marginPercent;
  final double? circuitLengthM;
  final VoltagePhase? phase;
  final VoltageDropInstallationGroup? installationGroup;
  final CableInsulation? insulation;
  final CoreType? coreType;
  final List<String> sourceReferences;
  final String? reason;
}
