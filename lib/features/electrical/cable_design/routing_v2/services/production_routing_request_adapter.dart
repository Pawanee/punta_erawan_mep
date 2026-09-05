import '../../enums/phase_system.dart';
import '../../models/cable_routing_identity.dart';
import '../models/cable_design_request_v2.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/cable_profile_type.dart';
import '../enums/routing_electrical_system.dart';
import '../models/ampacity_routing_request.dart';
import '../models/installation_conditions.dart';
import '../models/production_routing_adaptation_result.dart';
import '../models/routing_cable_properties_input.dart';
import '../repositories/cable_type_profile_repository.dart';

/// Production boundary for future Routing Context v2 activation.
///
/// This adapter is intentionally not referenced by the active engine. It maps
/// only explicit production inputs and approved Table 5-48 profile facts.
class ProductionRoutingRequestAdapter {
  ProductionRoutingRequestAdapter({CableTypeProfileRepository? cableProfiles})
    : _cableProfiles = cableProfiles ?? const CableTypeProfileRepository();

  final CableTypeProfileRepository _cableProfiles;

  Future<ProductionRoutingAdaptationResult> adapt(
    CableDesignRequestV2 productionRequest,
  ) async {
    final installation = productionRequest.engineeringInstallation;
    if (installation == null) {
      return const ProductionRoutingAdaptationResult(
        status: AmpacityRoutingStatus.insufficient,
        request: null,
        missingFields: ['engineeringInstallation'],
      );
    }
    final missing = <String>[];
    if (installation.environments == null ||
        installation.environments!.isEmpty) {
      missing.add('engineeringInstallation.environments');
    }
    if (installation.supports == null || installation.supports!.isEmpty) {
      missing.add('engineeringInstallation.supports');
    }
    final identity = productionRequest.identity;
    if (identity == null) {
      missing.add('identity');
      return ProductionRoutingAdaptationResult(
        status: AmpacityRoutingStatus.insufficient,
        request: null,
        missingFields: List.unmodifiable(missing),
      );
    }
    final profileType = _profileTypeFor(identity);
    final profile = await _cableProfiles.profileFor(profileType);
    final electricalSystem =
        productionRequest.routingElectricalSystem ??
        _approvedCompatibilitySystem(identity, productionRequest.phaseSystem);
    if (electricalSystem == null) {
      missing.add('routingElectricalSystem');
    }
    final hasOuterSheath =
        installation.hasOuterSheath ?? profile.hasOuterSheath;
    if (hasOuterSheath == null) {
      missing.add('engineeringInstallation.hasOuterSheath');
    }
    if (missing.isNotEmpty) {
      return ProductionRoutingAdaptationResult(
        status: AmpacityRoutingStatus.insufficient,
        request: null,
        missingFields: List.unmodifiable(missing),
      );
    }
    final supplemental = productionRequest.supplementalCableProperties;
    return ProductionRoutingAdaptationResult(
      status: AmpacityRoutingStatus.resolved,
      request: AmpacityRoutingRequest(
        cableType: profileType,
        installationConditions: InstallationConditions(
          environments: installation.environments!,
          supports: installation.supports!,
          coreType: productionRequest.coreType,
          hasOuterSheath: hasOuterSheath!,
          spacingAtLeastCableDiameter: installation.spacingAtLeastCableDiameter,
          ventilationOpeningPercent: installation.ventilationOpeningPercent,
        ),
        electricalSystem: electricalSystem!,
        loadedConductors: productionRequest.loadedConductors,
        cableProperties: RoutingCablePropertiesInput(
          cableShape: supplemental?.cableShape,
          coreType: supplemental?.coreType ?? productionRequest.coreType,
          insulation: supplemental?.insulation,
          conductorTemperatureClass: supplemental?.conductorTemperatureClass,
          hasOuterSheath:
              supplemental?.hasOuterSheath ?? installation.hasOuterSheath,
        ),
        ambientTemperatureC: productionRequest.ambientTemperature,
      ),
      missingFields: const [],
    );
  }

  CableProfileType _profileTypeFor(CableRoutingIdentity cableType) =>
      CableProfileType.values.singleWhere(
        (profile) => profile.code == cableType.code,
      );

  RoutingElectricalSystem? _approvedCompatibilitySystem(
    CableRoutingIdentity identity,
    PhaseSystem phaseSystem,
  ) => switch (identity) {
    CableRoutingIdentity.vaf ||
    CableRoutingIdentity.vafG ||
    CableRoutingIdentity.iec10 ||
    CableRoutingIdentity.nyy => _systemFor(phaseSystem),
    _ => null,
  };

  RoutingElectricalSystem _systemFor(PhaseSystem system) => switch (system) {
    PhaseSystem.singlePhase => RoutingElectricalSystem.singlePhaseAc,
    PhaseSystem.threePhase => RoutingElectricalSystem.threePhaseAc,
  };
}
