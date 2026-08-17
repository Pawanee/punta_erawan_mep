import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/installation_conditions.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/installation_reference_resolution.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/repositories/installation_reference_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = InstallationReferenceRepository();

  InstallationConditions conditions({
    required Set<InstallationEnvironment> environments,
    required Set<InstallationSupport> supports,
    required bool hasOuterSheath,
    CoreType coreType = CoreType.multiCore,
    bool? spacingAtLeastCableDiameter,
    double? ventilationOpeningPercent,
  }) => InstallationConditions(
    environments: environments,
    supports: supports,
    coreType: coreType,
    hasOuterSheath: hasOuterSheath,
    spacingAtLeastCableDiameter: spacingAtLeastCableDiameter,
    ventilationOpeningPercent: ventilationOpeningPercent,
  );

  Future<void> expectGroup(int group, InstallationConditions input) async {
    final result = await repository.resolve(input);
    expect(result.status, InstallationReferenceResolutionStatus.resolved);
    expect(result.reference!.group, group);
  }

  test('loads all seven Table 5-47 installation references', () async {
    final references = await repository.loadReferences();
    expect(references.map((reference) => reference.group), [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);
    expect(references[6].minimumVentilationOpeningPercent, 30);
    expect(references[3].minimumCableDiameterSpacing, isTrue);
  });

  test('resolves approved installation examples', () async {
    await expectGroup(
      3,
      conditions(
        environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
        supports: {InstallationSupport.surfaceMount},
        hasOuterSheath: true,
      ),
    );
    await expectGroup(
      5,
      conditions(
        environments: {InstallationEnvironment.underground},
        supports: {InstallationSupport.conduit},
        hasOuterSheath: true,
      ),
    );
    await expectGroup(
      6,
      conditions(
        environments: {InstallationEnvironment.directBuried},
        supports: {InstallationSupport.directBurial},
        hasOuterSheath: true,
      ),
    );
    await expectGroup(
      7,
      conditions(
        environments: {InstallationEnvironment.air},
        supports: {InstallationSupport.ventilatedCableTray},
        hasOuterSheath: true,
        ventilationOpeningPercent: 30,
      ),
    );
    await expectGroup(
      4,
      conditions(
        environments: {InstallationEnvironment.air},
        supports: {InstallationSupport.insulators},
        hasOuterSheath: false,
        coreType: CoreType.singleCore,
        spacingAtLeastCableDiameter: true,
      ),
    );
    await expectGroup(
      2,
      conditions(
        environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
        supports: {InstallationSupport.wiringEnclosure},
        hasOuterSheath: false,
      ),
    );
    await expectGroup(
      1,
      conditions(
        environments: {InstallationEnvironment.thermallyInsulatedCeiling},
        supports: {InstallationSupport.wiringEnclosure},
        hasOuterSheath: false,
      ),
    );
  });

  test(
    'does not guess for insufficient, conflicting, or non-compliant conditions',
    () async {
      final insufficient = await repository.resolve(
        conditions(environments: {}, supports: {}, hasOuterSheath: true),
      );
      expect(
        insufficient.status,
        InstallationReferenceResolutionStatus.insufficient,
      );

      final conflicting = await repository.resolve(
        conditions(
          environments: {
            InstallationEnvironment.thermallyInsulatedCeiling,
            InstallationEnvironment.surfaceMountedWallOrCeiling,
          },
          supports: {InstallationSupport.wiringEnclosure},
          hasOuterSheath: true,
        ),
      );
      expect(
        conflicting.status,
        InstallationReferenceResolutionStatus.ambiguous,
      );
      expect(conflicting.matches.map((reference) => reference.group), [1, 2]);

      final inadequateVentilation = await repository.resolve(
        conditions(
          environments: {InstallationEnvironment.air},
          supports: {InstallationSupport.ventilatedCableTray},
          hasOuterSheath: true,
          ventilationOpeningPercent: 29,
        ),
      );
      expect(
        inadequateVentilation.status,
        InstallationReferenceResolutionStatus.noMatch,
      );

      final contradictoryComplete = await repository.resolve(
        conditions(
          environments: {InstallationEnvironment.directBuried},
          supports: {InstallationSupport.surfaceMount},
          hasOuterSheath: true,
        ),
      );
      expect(
        contradictoryComplete.status,
        InstallationReferenceResolutionStatus.noMatch,
      );

      final missingVentilation = await repository.resolve(
        conditions(
          environments: {InstallationEnvironment.air},
          supports: {InstallationSupport.ventilatedCableTray},
          hasOuterSheath: true,
        ),
      );
      expect(
        missingVentilation.status,
        InstallationReferenceResolutionStatus.insufficient,
      );
    },
  );
}
