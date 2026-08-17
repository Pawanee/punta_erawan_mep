import '../../enums/conductor_temperature_class.dart';
import '../../enums/core_type.dart';
import '../../models/cable_routing_identity.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';

/// Source-faithful candidate for future active ampacity selection.
/// It deliberately contains no legacy CableType or InstallationMethod.
class AmpacityCandidateV2 {
  const AmpacityCandidateV2({
    required this.sizeSqmm,
    required this.baseAmpacity,
    required this.sourceTableId,
    required this.sourceTableDisplayName,
    required this.sourceColumnId,
    required this.installationGroupNumber,
    required this.loadedConductors,
    required this.coreType,
    required this.insulation,
    required this.conductorTemperatureClass,
    required this.applicableCableIdentities,
    required this.sourceReferences,
  });

  final double sizeSqmm;
  final double baseAmpacity;
  final String sourceTableId;
  final String sourceTableDisplayName;
  final String? sourceColumnId;
  final int installationGroupNumber;
  final int loadedConductors;
  final CoreType coreType;
  final CableInsulation insulation;
  final ConductorTemperatureClass conductorTemperatureClass;
  final Set<CableRoutingIdentity> applicableCableIdentities;
  final List<String> sourceReferences;
}
