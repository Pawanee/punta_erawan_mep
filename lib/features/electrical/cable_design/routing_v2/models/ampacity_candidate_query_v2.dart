import '../../enums/conductor_temperature_class.dart';
import '../../enums/core_type.dart';
import '../../models/cable_routing_identity.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';

/// Neutral criteria for filtering already source-adapted candidates.
class AmpacityCandidateQueryV2 {
  const AmpacityCandidateQueryV2({
    required this.sourceTableId,
    required this.installationGroupNumber,
    required this.loadedConductors,
    required this.coreType,
    required this.insulation,
    required this.conductorTemperatureClass,
    this.routingCableIdentity,
    this.sourceColumnId,
  });

  final String sourceTableId;
  final int installationGroupNumber;
  final int loadedConductors;
  final CoreType coreType;
  final CableInsulation insulation;
  final ConductorTemperatureClass conductorTemperatureClass;
  final CableRoutingIdentity? routingCableIdentity;
  final String? sourceColumnId;
}
