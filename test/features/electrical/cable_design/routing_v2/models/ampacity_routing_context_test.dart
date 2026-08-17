import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_profile_type.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/routing_electrical_system.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/routing_property_source.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_routing_context.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/installation_conditions.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/installation_reference.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/installation_reference_resolution.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/repositories/cable_type_profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'keeps user conditions, derived properties, and resolved references separate',
    () async {
      const profiles = CableTypeProfileRepository();
      final profile = await profiles.profileFor(CableProfileType.vaf);
      final context = AmpacityRoutingContext(
        cableType: CableProfileType.vaf,
        userInstallationConditions: const InstallationConditions(
          environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
          supports: {InstallationSupport.surfaceMount},
          coreType: CoreType.multiCore,
          hasOuterSheath: true,
        ),
        electricalSystem: RoutingElectricalSystem.singlePhaseAc,
        loadedConductors: 2,
        cableProfile: profile,
        cableShape: profile.cableShape,
        coreType: CoreType.multiCore,
        insulation: null,
        conductorTemperatureClass: null,
        hasOuterSheath: profile.hasOuterSheath,
        installationResolution: const InstallationReferenceResolution(
          status: InstallationReferenceResolutionStatus.resolved,
          matches: [
            InstallationReference(
              group: 3,
              coreTypes: {CoreType.singleCore, CoreType.multiCore},
              outerSheathRequired: true,
              environments: {
                InstallationEnvironment.surfaceMountedWallOrCeiling,
              },
              supports: {InstallationSupport.surfaceMount},
              minimumCableDiameterSpacing: false,
              minimumVentilationOpeningPercent: null,
              notes: [],
              sourceReference: 'Table 5-47',
            ),
          ],
        ),
        sourceReferences: const ['Table 5-47', 'Table 5-48'],
        propertySources: const {
          'installationGroup': RoutingPropertySource.installationReference,
        },
      );

      expect(context.userInstallationConditions.coreType, CoreType.multiCore);
      expect(context.cableShape, profile.cableShape);
      expect(context.installationResolution.reference!.group, 3);
      expect(context.sourceReferences, contains('Table 5-47'));
    },
  );
}
