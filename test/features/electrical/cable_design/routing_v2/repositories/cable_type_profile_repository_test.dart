import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_conductor_construction.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_profile_type.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/repositories/cable_type_profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repository = CableTypeProfileRepository();

  test('loads approved VAF and IEC profile facts from Table 5-48', () async {
    final vaf = await repository.profileFor(CableProfileType.vaf);
    expect(vaf.cableShape, CableShape.flat);
    expect(vaf.nominalCoreConfiguration, '2-core');
    expect(vaf.hasOuterSheath, isTrue);
    expect(vaf.conductorTemperatureC, 70);

    final iec01 = await repository.profileFor(CableProfileType.iec01);
    expect(iec01.coreTypes, {CoreType.singleCore});
    expect(iec01.hasOuterSheath, isFalse);
    expect(
      iec01.conductorConstructions,
      contains(CableConductorConstruction.solid),
    );

    final iec10 = await repository.profileFor(CableProfileType.iec10);
    expect(iec10.coreTypes, {CoreType.multiCore});
    expect(iec10.hasOuterSheath, isTrue);
  });

  test(
    'loads approved NYY and VCT/VCT-G installation facts from Table 5-48',
    () async {
      final nyy = await repository.profileFor(CableProfileType.nyy);
      expect(nyy.sizeRanges, {
        'singleCore': '1-500 sq.mm',
        'multiCore': '1-300 sq.mm',
      });
      expect(
        nyy.permittedEnvironments,
        contains(InstallationEnvironment.directBuried),
      );
      expect(
        nyy.permittedEnvironments,
        contains(InstallationEnvironment.underground),
      );

      for (final cableType in [CableProfileType.vct, CableProfileType.vctG]) {
        final profile = await repository.profileFor(cableType);
        expect(profile.conductorConstructions, {
          CableConductorConstruction.flexible,
        });
        expect(profile.hasOuterSheath, isTrue);
        expect(profile.conductorTemperatureC, 70);
        expect(
          profile.permittedEnvironments,
          contains(InstallationEnvironment.directBuried),
        );
      }
    },
  );

  test('keeps unverified IEC 60502-1 properties unresolved', () async {
    final profile = await repository.profileFor(CableProfileType.iec605021);
    expect(profile.conductorConstructions, isEmpty);
    expect(profile.coreTypes, isEmpty);
    expect(profile.conductorTemperatureC, isNull);
    expect(profile.hasOuterSheath, isNull);
    expect(profile.cableShape, isNull);
    expect(profile.ratedVoltage, isNull);
    expect(profile.sourceReferences, isEmpty);
  });
}
