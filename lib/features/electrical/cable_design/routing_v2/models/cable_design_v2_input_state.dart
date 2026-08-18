import '../../enums/core_type.dart';
import '../../enums/phase_system.dart';
import '../../models/cable_routing_identity.dart';
import '../../models/supplemental_cable_properties_input.dart';
import '../../../voltage_drop/enums/cable_arrangement.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../../../voltage_drop/enums/voltage_drop_installation_group.dart';
import '../../../voltage_drop/enums/voltage_phase.dart';
import '../enums/installation_environment.dart';
import '../enums/installation_support.dart';

/// Explicit UI facts for an inactive, future V2 design workflow.
class CableDesignV2InputState {
  const CableDesignV2InputState({
    this.loadCurrent,
    this.phaseSystem,
    this.loadedConductors,
    this.coreType,
    this.ambientTemperature,
    this.identity,
    this.environments,
    this.supports,
    this.hasOuterSheath,
    this.spacingAtLeastCableDiameter,
    this.ventilationOpeningPercent,
    this.supplementalCableProperties,
    this.verifyVoltageDrop = false,
    this.voltageDropPhase,
    this.voltageDropInsulation,
    this.voltageDropCoreType,
    this.voltageDropInstallationGroup,
    this.voltageDropArrangement,
    this.circuitLengthM,
    this.systemVoltage,
    this.allowableVoltageDropPercent,
  });
  final double? loadCurrent;
  final PhaseSystem? phaseSystem;
  final int? loadedConductors;
  final CoreType? coreType;
  final double? ambientTemperature;
  final CableRoutingIdentity? identity;
  final Set<InstallationEnvironment>? environments;
  final Set<InstallationSupport>? supports;
  final bool? hasOuterSheath;
  final bool? spacingAtLeastCableDiameter;
  final double? ventilationOpeningPercent;
  final SupplementalCablePropertiesInput? supplementalCableProperties;
  final bool verifyVoltageDrop;
  final VoltagePhase? voltageDropPhase;
  final CableInsulation? voltageDropInsulation;
  final CoreType? voltageDropCoreType;
  final VoltageDropInstallationGroup? voltageDropInstallationGroup;
  final CableArrangement? voltageDropArrangement;
  final double? circuitLengthM;
  final double? systemVoltage;
  final double? allowableVoltageDropPercent;
}
