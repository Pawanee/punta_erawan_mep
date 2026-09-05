import '../../enums/cable_design_routing_mode.dart';
import '../../enums/core_type.dart';
import '../../enums/phase_system.dart';
import '../../models/cable_routing_identity.dart';
import '../../models/engineering_installation_input.dart';
import '../../models/supplemental_cable_properties_input.dart';
import '../enums/routing_electrical_system.dart';

/// Native, source-faithful ampacity request for Routing v2 execution.
///
/// It intentionally contains no legacy CableType, InstallationMethod, or
/// voltage-drop routing facts. Null identity/installation fields remain
/// explicit so the caller boundary can fail closed with actionable feedback.
class CableDesignRequestV2 {
  const CableDesignRequestV2({
    required this.loadCurrent,
    required this.phaseSystem,
    this.routingElectricalSystem,
    required this.loadedConductors,
    required this.coreType,
    required this.ambientTemperature,
    this.routingMode = CableDesignRoutingMode.routingV2,
    this.identity,
    this.engineeringInstallation,
    this.supplementalCableProperties,
  });

  final double loadCurrent;
  final PhaseSystem phaseSystem;
  final RoutingElectricalSystem? routingElectricalSystem;
  final int loadedConductors;
  final CoreType coreType;
  final double ambientTemperature;
  final CableDesignRoutingMode routingMode;
  final CableRoutingIdentity? identity;
  final EngineeringInstallationInput? engineeringInstallation;
  final SupplementalCablePropertiesInput? supplementalCableProperties;

  CableDesignRequestV2 copyWith({
    double? loadCurrent,
    PhaseSystem? phaseSystem,
    RoutingElectricalSystem? routingElectricalSystem,
    int? loadedConductors,
    CoreType? coreType,
    double? ambientTemperature,
    CableDesignRoutingMode? routingMode,
    CableRoutingIdentity? identity,
    EngineeringInstallationInput? engineeringInstallation,
    SupplementalCablePropertiesInput? supplementalCableProperties,
  }) => CableDesignRequestV2(
    loadCurrent: loadCurrent ?? this.loadCurrent,
    phaseSystem: phaseSystem ?? this.phaseSystem,
    routingElectricalSystem:
        routingElectricalSystem ?? this.routingElectricalSystem,
    loadedConductors: loadedConductors ?? this.loadedConductors,
    coreType: coreType ?? this.coreType,
    ambientTemperature: ambientTemperature ?? this.ambientTemperature,
    routingMode: routingMode ?? this.routingMode,
    identity: identity ?? this.identity,
    engineeringInstallation:
        engineeringInstallation ?? this.engineeringInstallation,
    supplementalCableProperties:
        supplementalCableProperties ?? this.supplementalCableProperties,
  );
}
