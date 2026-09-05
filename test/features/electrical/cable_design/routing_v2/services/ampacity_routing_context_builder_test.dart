import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_profile_type.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/routing_electrical_system.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/routing_property_source.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_routing_request.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/installation_conditions.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/routing_cable_properties_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/ampacity_routing_context_builder.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_21_repository.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final builder = AmpacityRoutingContextBuilder();

  AmpacityRoutingRequest request({
    required CableProfileType cableType,
    required RoutingElectricalSystem system,
    required int loaded,
    required CoreType installationCore,
    CableShape? shape,
    CoreType? core,
    CableInsulation? insulation,
    ConductorTemperatureClass? temperature,
    Set<InstallationEnvironment>? environments,
    Set<InstallationSupport>? supports,
  }) => AmpacityRoutingRequest(
    cableType: cableType,
    installationConditions: InstallationConditions(
      environments:
          environments ?? {InstallationEnvironment.surfaceMountedWallOrCeiling},
      supports: supports ?? {InstallationSupport.surfaceMount},
      coreType: installationCore,
      hasOuterSheath: true,
    ),
    electricalSystem: system,
    loadedConductors: loaded,
    cableProperties: RoutingCablePropertiesInput(
      cableShape: shape,
      coreType: core,
      insulation: insulation,
      conductorTemperatureClass: temperature,
    ),
  );

  Future<void> expectRoute({
    required CableProfileType cableType,
    required RoutingElectricalSystem system,
    required int loaded,
    required CoreType core,
    required String column,
  }) async {
    final result = await builder.build(
      request(
        cableType: cableType,
        system: system,
        loaded: loaded,
        installationCore: core,
        core: core,
        shape:
            cableType == CableProfileType.vaf ||
                cableType == CableProfileType.vafG
            ? null
            : CableShape.round,
        insulation: CableInsulation.pvc,
        temperature: ConductorTemperatureClass.pvc70,
      ),
    );
    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(result.ampacityTable!.name, 'table521');
    expect(result.sourceColumnId, column);
    expect(result.installationResolution.reference!.group, 3);
  }

  test('resolves approved Table 5-21 dry-run routes', () async {
    await expectRoute(
      cableType: CableProfileType.vaf,
      system: RoutingElectricalSystem.singlePhaseAc,
      loaded: 2,
      core: CoreType.multiCore,
      column: 'C1',
    );
    await expectRoute(
      cableType: CableProfileType.vafG,
      system: RoutingElectricalSystem.singlePhaseAc,
      loaded: 2,
      core: CoreType.multiCore,
      column: 'C1',
    );
    await expectRoute(
      cableType: CableProfileType.nyy,
      system: RoutingElectricalSystem.singlePhaseAc,
      loaded: 2,
      core: CoreType.singleCore,
      column: 'C2',
    );
    await expectRoute(
      cableType: CableProfileType.nyy,
      system: RoutingElectricalSystem.threePhaseAc,
      loaded: 3,
      core: CoreType.singleCore,
      column: 'C3',
    );
    await expectRoute(
      cableType: CableProfileType.nyy,
      system: RoutingElectricalSystem.dc,
      loaded: 2,
      core: CoreType.singleCore,
      column: 'C2',
    );
    await expectRoute(
      cableType: CableProfileType.iec10,
      system: RoutingElectricalSystem.singlePhaseAc,
      loaded: 2,
      core: CoreType.multiCore,
      column: 'C6',
    );
    await expectRoute(
      cableType: CableProfileType.iec10,
      system: RoutingElectricalSystem.threePhaseAc,
      loaded: 3,
      core: CoreType.multiCore,
      column: 'C7',
    );
    await expectRoute(
      cableType: CableProfileType.vct,
      system: RoutingElectricalSystem.singlePhaseAc,
      loaded: 2,
      core: CoreType.multiCore,
      column: 'C6',
    );
    await expectRoute(
      cableType: CableProfileType.vct,
      system: RoutingElectricalSystem.threePhaseAc,
      loaded: 3,
      core: CoreType.multiCore,
      column: 'C7',
    );
  });

  test('keeps unresolved and invalid routes explicit', () async {
    final dcThree = await builder.build(
      request(
        cableType: CableProfileType.nyy,
        system: RoutingElectricalSystem.dc,
        loaded: 3,
        installationCore: CoreType.singleCore,
        core: CoreType.singleCore,
        shape: CableShape.round,
        insulation: CableInsulation.pvc,
        temperature: ConductorTemperatureClass.pvc70,
      ),
    );
    expect(dcThree.status, AmpacityRoutingStatus.noMatch);
    final iec10C7Dc = await builder.build(
      request(
        cableType: CableProfileType.iec10,
        system: RoutingElectricalSystem.dc,
        loaded: 3,
        installationCore: CoreType.multiCore,
        shape: CableShape.round,
        insulation: CableInsulation.pvc,
        temperature: ConductorTemperatureClass.pvc70,
      ),
    );
    expect(iec10C7Dc.status, AmpacityRoutingStatus.noMatch);
    expect(iec10C7Dc.sourceColumnId, isNull);
    final iec = await builder.build(
      request(
        cableType: CableProfileType.iec605021,
        system: RoutingElectricalSystem.singlePhaseAc,
        loaded: 2,
        installationCore: CoreType.singleCore,
      ),
    );
    expect(iec.status, AmpacityRoutingStatus.insufficient);
    final vafBuried = await builder.build(
      request(
        cableType: CableProfileType.vaf,
        system: RoutingElectricalSystem.singlePhaseAc,
        loaded: 2,
        installationCore: CoreType.multiCore,
        insulation: CableInsulation.pvc,
        temperature: ConductorTemperatureClass.pvc70,
        environments: {InstallationEnvironment.directBuried},
        supports: {InstallationSupport.directBurial},
      ),
    );
    expect(vafBuried.status, AmpacityRoutingStatus.noMatch);
    final missingSupport = await builder.build(
      request(
        cableType: CableProfileType.vaf,
        system: RoutingElectricalSystem.singlePhaseAc,
        loaded: 2,
        installationCore: CoreType.multiCore,
        insulation: CableInsulation.pvc,
        temperature: ConductorTemperatureClass.pvc70,
        supports: {},
      ),
    );
    expect(missingSupport.status, AmpacityRoutingStatus.insufficient);
  });

  test('uses Table521Repository for final dry-run source lookup', () async {
    final repository = Table521Repository();
    final route = await builder.build(
      request(
        cableType: CableProfileType.vaf,
        system: RoutingElectricalSystem.singlePhaseAc,
        loaded: 2,
        installationCore: CoreType.multiCore,
        core: CoreType.multiCore,
        insulation: CableInsulation.pvc,
        temperature: ConductorTemperatureClass.pvc70,
      ),
    );
    expect(route.status, AmpacityRoutingStatus.resolved);
    expect(
      await repository.lookupByColumnId(
        sizeSqmm: 10,
        columnId: route.sourceColumnId!,
      ),
      56,
    );
    expect(await repository.lookupByColumnId(sizeSqmm: 10, columnId: 'C2'), 57);
    expect(await repository.lookupByColumnId(sizeSqmm: 10, columnId: 'C3'), 51);
    expect(await repository.lookupByColumnId(sizeSqmm: 10, columnId: 'C6'), 55);
    expect(await repository.lookupByColumnId(sizeSqmm: 10, columnId: 'C7'), 50);
    expect(
      await repository.lookupByColumnId(sizeSqmm: 400, columnId: 'C1'),
      isNull,
    );
  });

  test(
    'rejects known-profile overrides and traces IEC supplementation',
    () async {
      final vafRound = await builder.build(
        request(
          cableType: CableProfileType.vaf,
          system: RoutingElectricalSystem.singlePhaseAc,
          loaded: 2,
          installationCore: CoreType.multiCore,
          core: CoreType.multiCore,
          shape: CableShape.round,
          insulation: CableInsulation.pvc,
          temperature: ConductorTemperatureClass.pvc70,
        ),
      );
      expect(vafRound.status, AmpacityRoutingStatus.noMatch);
      final vafXlpe = await builder.build(
        request(
          cableType: CableProfileType.vaf,
          system: RoutingElectricalSystem.singlePhaseAc,
          loaded: 2,
          installationCore: CoreType.multiCore,
          core: CoreType.multiCore,
          insulation: CableInsulation.xlpe,
          temperature: ConductorTemperatureClass.xlpeEpr90,
        ),
      );
      expect(vafXlpe.status, AmpacityRoutingStatus.noMatch);
      final iec10Single = await builder.build(
        request(
          cableType: CableProfileType.iec10,
          system: RoutingElectricalSystem.singlePhaseAc,
          loaded: 2,
          installationCore: CoreType.singleCore,
          core: CoreType.singleCore,
          shape: CableShape.round,
          insulation: CableInsulation.pvc,
          temperature: ConductorTemperatureClass.pvc70,
        ),
      );
      expect(iec10Single.status, AmpacityRoutingStatus.noMatch);
      final iecSupplemented = await builder.build(
        request(
          cableType: CableProfileType.iec605021,
          system: RoutingElectricalSystem.singlePhaseAc,
          loaded: 2,
          installationCore: CoreType.singleCore,
          core: CoreType.singleCore,
          shape: CableShape.round,
          insulation: CableInsulation.xlpe,
          temperature: ConductorTemperatureClass.xlpeEpr90,
        ),
      );
      expect(iecSupplemented.status, AmpacityRoutingStatus.resolved);
      expect(iecSupplemented.sourceColumnId, 'C4');
      expect(
        iecSupplemented.context!.propertySources['insulation'],
        RoutingPropertySource.supplementalInput,
      );
      for (final values in [
        (2, RoutingElectricalSystem.singlePhaseAc, 'C8'),
        (2, RoutingElectricalSystem.dc, 'C8'),
        (3, RoutingElectricalSystem.threePhaseAc, 'C9'),
      ]) {
        final routed = await builder.build(
          request(
            cableType: CableProfileType.iec605021,
            system: values.$2,
            loaded: values.$1,
            installationCore: CoreType.multiCore,
            core: CoreType.multiCore,
            shape: CableShape.round,
            insulation: CableInsulation.xlpe,
            temperature: ConductorTemperatureClass.xlpeEpr90,
          ),
        );
        expect(routed.status, AmpacityRoutingStatus.resolved);
        expect(routed.sourceColumnId, values.$3);
      }
      final c9Dc = await builder.build(
        request(
          cableType: CableProfileType.iec605021,
          system: RoutingElectricalSystem.dc,
          loaded: 3,
          installationCore: CoreType.multiCore,
          core: CoreType.multiCore,
          shape: CableShape.round,
          insulation: CableInsulation.xlpe,
          temperature: ConductorTemperatureClass.xlpeEpr90,
        ),
      );
      expect(c9Dc.status, AmpacityRoutingStatus.noMatch);
      expect(c9Dc.sourceColumnId, isNull);
    },
  );
}
