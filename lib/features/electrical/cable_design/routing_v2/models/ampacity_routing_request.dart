import '../enums/cable_profile_type.dart';
import '../enums/routing_electrical_system.dart';
import 'installation_conditions.dart';
import 'routing_cable_properties_input.dart';

/// User-supplied dry-run inputs. Not connected to the active UI.
class AmpacityRoutingRequest {
  const AmpacityRoutingRequest({
    required this.cableType,
    required this.installationConditions,
    required this.electricalSystem,
    required this.loadedConductors,
    required this.cableProperties,
    this.ambientTemperatureC,
  });
  final CableProfileType cableType;
  final InstallationConditions installationConditions;
  final RoutingElectricalSystem electricalSystem;
  final int loadedConductors;
  final RoutingCablePropertiesInput cableProperties;
  final double? ambientTemperatureC;
}
