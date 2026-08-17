import '../../enums/conductor_temperature_class.dart';
import '../../enums/core_type.dart';
import '../../enums/cable_shape.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../enums/cable_profile_type.dart';
import '../enums/routing_electrical_system.dart';
import '../enums/routing_property_source.dart';
import 'cable_type_profile.dart';
import 'installation_conditions.dart';
import 'installation_reference_resolution.dart';

/// Parallel contract for future ampacity-table routing; not used by the active
/// VoltageDropCableDesignEngine or the existing CableContext.
class AmpacityRoutingContext {
  const AmpacityRoutingContext({
    required this.cableType,
    required this.userInstallationConditions,
    required this.electricalSystem,
    required this.loadedConductors,
    required this.cableProfile,
    required this.cableShape,
    required this.coreType,
    required this.insulation,
    required this.conductorTemperatureClass,
    required this.hasOuterSheath,
    required this.installationResolution,
    required this.sourceReferences,
    required this.propertySources,
  });

  final CableProfileType cableType;
  final InstallationConditions userInstallationConditions;
  final RoutingElectricalSystem electricalSystem;
  final int loadedConductors;
  final CableTypeProfile cableProfile;
  final CableShape? cableShape;
  final CoreType? coreType;
  final CableInsulation? insulation;
  final ConductorTemperatureClass? conductorTemperatureClass;
  final bool? hasOuterSheath;
  final InstallationReferenceResolution installationResolution;
  final List<String> sourceReferences;
  final Map<String, RoutingPropertySource> propertySources;
}
