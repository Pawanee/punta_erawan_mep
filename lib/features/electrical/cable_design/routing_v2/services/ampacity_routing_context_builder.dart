import '../../enums/conductor_temperature_class.dart';
import '../../enums/core_type.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/routing_property_source.dart';
import '../models/ampacity_routing_context.dart';
import '../models/ampacity_routing_request.dart';
import '../models/ampacity_routing_result.dart';
import '../models/cable_type_profile.dart';
import '../models/installation_reference_resolution.dart';
import '../repositories/cable_type_profile_repository.dart';
import '../repositories/installation_reference_repository.dart';
import 'ampacity_table_resolver.dart';

/// Builds a dry-run context then resolves only approved table metadata/headers.
class AmpacityRoutingContextBuilder {
  AmpacityRoutingContextBuilder({
    CableTypeProfileRepository? cableProfiles,
    InstallationReferenceRepository? installationReferences,
    AmpacityTableResolver? tableResolver,
  }) : _cableProfiles = cableProfiles ?? const CableTypeProfileRepository(),
       _installationReferences =
           installationReferences ?? InstallationReferenceRepository(),
       _tableResolver = tableResolver ?? AmpacityTableResolver();
  final CableTypeProfileRepository _cableProfiles;
  final InstallationReferenceRepository _installationReferences;
  final AmpacityTableResolver _tableResolver;

  Future<AmpacityRoutingResult> build(AmpacityRoutingRequest request) async {
    final profile = await _cableProfiles.profileFor(request.cableType);
    final installation = await _installationReferences.resolve(
      request.installationConditions,
    );
    final installationStatus = _mapInstallationStatus(installation.status);
    if (installationStatus != AmpacityRoutingStatus.resolved)
      return _failure(
        status: installationStatus,
        profile: profile,
        installation: installation,
        reason: 'Installation reference is not uniquely resolved.',
        missing: installationStatus == AmpacityRoutingStatus.insufficient
            ? const ['installationConditions']
            : const [],
      );

    final mismatch = _profileMismatch(profile, request);
    if (mismatch != null)
      return _failure(
        status: AmpacityRoutingStatus.noMatch,
        profile: profile,
        installation: installation,
        reason: mismatch,
        missing: const [],
      );
    final coreType = _resolveCoreType(profile, request);
    final cableShape = profile.cableShape ?? request.cableProperties.cableShape;
    final insulation = profile.insulation ?? request.cableProperties.insulation;
    final temperatureClass =
        profile.conductorTemperatureClass ??
        request.cableProperties.conductorTemperatureClass;
    final hasOuterSheath =
        profile.hasOuterSheath ?? request.cableProperties.hasOuterSheath;
    final context = AmpacityRoutingContext(
      cableType: request.cableType,
      userInstallationConditions: request.installationConditions,
      electricalSystem: request.electricalSystem,
      loadedConductors: request.loadedConductors,
      cableProfile: profile,
      cableShape: cableShape,
      coreType: coreType,
      insulation: insulation,
      conductorTemperatureClass: temperatureClass,
      hasOuterSheath: hasOuterSheath,
      installationResolution: installation,
      sourceReferences: [
        ...profile.sourceReferences,
        installation.reference!.sourceReference,
      ],
      propertySources: {
        if (cableShape != null)
          'cableShape': profile.cableShape != null
              ? RoutingPropertySource.cableProfile
              : RoutingPropertySource.supplementalInput,
        if (coreType != null)
          'coreType': profile.coreTypes.length == 1
              ? RoutingPropertySource.cableProfile
              : RoutingPropertySource.supplementalInput,
        if (insulation != null)
          'insulation': profile.insulation != null
              ? RoutingPropertySource.cableProfile
              : RoutingPropertySource.supplementalInput,
        if (temperatureClass != null)
          'conductorTemperatureClass': profile.conductorTemperatureClass != null
              ? RoutingPropertySource.cableProfile
              : RoutingPropertySource.supplementalInput,
        if (hasOuterSheath != null)
          'hasOuterSheath': profile.hasOuterSheath != null
              ? RoutingPropertySource.cableProfile
              : RoutingPropertySource.supplementalInput,
        'installationGroup': RoutingPropertySource.installationReference,
      },
    );
    final table = await _tableResolver.resolve(context);
    return AmpacityRoutingResult(
      status: table.status,
      cableProfile: profile,
      installationResolution: installation,
      context: context,
      ampacityTable: table.table,
      sourceColumnId: table.column?.columnId,
      sourceReferences: context.sourceReferences,
      reason: table.reason,
      missingDimensions: table.missingDimensions,
      ambiguityCandidates: table.candidates,
    );
  }

  CoreType? _resolveCoreType(
    CableTypeProfile profile,
    AmpacityRoutingRequest request,
  ) => profile.coreTypes.length == 1
      ? profile.coreTypes.single
      : request.cableProperties.coreType;
  String? _profileMismatch(
    CableTypeProfile profile,
    AmpacityRoutingRequest request,
  ) {
    if (profile.hasOuterSheath != null &&
        profile.hasOuterSheath != request.installationConditions.hasOuterSheath)
      return 'Cable profile outer-sheath fact conflicts with installation conditions.';
    if (profile.hasOuterSheath != null &&
        request.cableProperties.hasOuterSheath != null &&
        profile.hasOuterSheath != request.cableProperties.hasOuterSheath)
      return 'Cable profile outer-sheath fact conflicts with supplied cable properties.';
    if (profile.cableShape != null &&
        request.cableProperties.cableShape != null &&
        profile.cableShape != request.cableProperties.cableShape)
      return 'Cable profile shape conflicts with supplied cable properties.';
    if (profile.insulation != null &&
        request.cableProperties.insulation != null &&
        profile.insulation != request.cableProperties.insulation)
      return 'Cable profile insulation conflicts with supplied cable properties.';
    if (profile.conductorTemperatureClass != null &&
        request.cableProperties.conductorTemperatureClass != null &&
        profile.conductorTemperatureClass !=
            request.cableProperties.conductorTemperatureClass)
      return 'Cable profile temperature class conflicts with supplied cable properties.';
    if (profile.coreTypes.length == 1 &&
        profile.coreTypes.single != request.installationConditions.coreType)
      return 'Cable profile core type conflicts with installation conditions.';
    if (request.cableProperties.coreType != null &&
        request.cableProperties.coreType !=
            request.installationConditions.coreType)
      return 'Supplied cable core type conflicts with installation conditions.';
    if (request.installationConditions.environments.any(
          profile.prohibitedEnvironments.contains,
        ) ||
        request.installationConditions.supports.any(
          profile.prohibitedSupports.contains,
        ))
      return 'Cable profile prohibits the supplied installation use.';
    final suppliedClass = request.cableProperties.conductorTemperatureClass;
    if (profile.conductorTemperatureC != null &&
        suppliedClass != null &&
        suppliedClass.temperatureC != profile.conductorTemperatureC)
      return 'Cable profile temperature conflicts with supplied temperature class.';
    return null;
  }

  AmpacityRoutingStatus _mapInstallationStatus(
    InstallationReferenceResolutionStatus status,
  ) => switch (status) {
    InstallationReferenceResolutionStatus.resolved =>
      AmpacityRoutingStatus.resolved,
    InstallationReferenceResolutionStatus.insufficient =>
      AmpacityRoutingStatus.insufficient,
    InstallationReferenceResolutionStatus.ambiguous =>
      AmpacityRoutingStatus.ambiguous,
    InstallationReferenceResolutionStatus.noMatch =>
      AmpacityRoutingStatus.noMatch,
  };
  AmpacityRoutingResult _failure({
    required AmpacityRoutingStatus status,
    required CableTypeProfile profile,
    required InstallationReferenceResolution installation,
    required String reason,
    required List<String> missing,
  }) => AmpacityRoutingResult(
    status: status,
    cableProfile: profile,
    installationResolution: installation,
    context: null,
    ampacityTable: null,
    sourceColumnId: null,
    sourceReferences: profile.sourceReferences,
    reason: reason,
    missingDimensions: missing,
    ambiguityCandidates: installation.matches
        .map((reference) => 'Group ${reference.group}')
        .toList(),
  );
}
