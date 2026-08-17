import '../../enums/core_type.dart';
import '../../enums/cable_shape.dart';
import '../../enums/conductor_temperature_class.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../enums/cable_conductor_construction.dart';
import '../enums/cable_profile_type.dart';
import '../enums/installation_environment.dart';
import '../enums/installation_support.dart';

/// Intrinsic cable facts only where supported by the approved source.
/// A null or empty value is unresolved, not an inferred engineering property.
class CableTypeProfile {
  const CableTypeProfile({
    required this.cableType,
    required this.sizeRanges,
    required this.conductorConstructions,
    required this.coreTypes,
    required this.nominalCoreConfiguration,
    required this.conductorTemperatureC,
    required this.conductorTemperatureClass,
    required this.insulation,
    required this.hasOuterSheath,
    required this.cableShape,
    required this.ratedVoltage,
    required this.permittedEnvironments,
    required this.permittedSupports,
    required this.prohibitedEnvironments,
    required this.prohibitedSupports,
    required this.sourceReferences,
    required this.notes,
  });

  final CableProfileType cableType;
  final Map<String, String> sizeRanges;
  final Set<CableConductorConstruction> conductorConstructions;
  final Set<CoreType> coreTypes;
  final String? nominalCoreConfiguration;
  final int? conductorTemperatureC;
  final ConductorTemperatureClass? conductorTemperatureClass;
  final CableInsulation? insulation;
  final bool? hasOuterSheath;
  final CableShape? cableShape;
  final String? ratedVoltage;
  final Set<InstallationEnvironment> permittedEnvironments;
  final Set<InstallationSupport> permittedSupports;
  final Set<InstallationEnvironment> prohibitedEnvironments;
  final Set<InstallationSupport> prohibitedSupports;
  final List<String> sourceReferences;
  final List<String> notes;
}
