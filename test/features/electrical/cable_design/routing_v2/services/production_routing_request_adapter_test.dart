import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_design_request.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/models/supplemental_cable_properties_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/ampacity_routing_context_builder.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/production_routing_request_adapter.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final adapter = ProductionRoutingRequestAdapter();
  final builder = AmpacityRoutingContextBuilder();

  CableDesignRequest request({
    CableType cableType = CableType.iec01,
    CableRoutingIdentity? routingCableIdentity,
    CoreType coreType = CoreType.multiCore,
    EngineeringInstallationInput? installation,
    SupplementalCablePropertiesInput? supplemental,
  }) => CableDesignRequest(
    loadCurrent: 10,
    phaseSystem: PhaseSystem.singlePhase,
    cableType: cableType,
    installationMethod: InstallationMethod.group1,
    loadedConductors: 2,
    coreType: coreType,
    engineeringInstallation: installation,
    routingCableIdentity: routingCableIdentity,
    supplementalCableProperties: supplemental,
  );

  EngineeringInstallationInput surfaceWall({bool? hasOuterSheath}) =>
      EngineeringInstallationInput(
        environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
        supports: {InstallationSupport.surfaceMount},
        hasOuterSheath: hasOuterSheath,
      );

  test('existing Group 1 and Group 2 requests need no routing fields', () {
    final group1 = request();
    final group2 = request().copyWith(
      installationMethod: InstallationMethod.group2,
    );

    expect(group1.engineeringInstallation, isNull);
    expect(group1.supplementalCableProperties, isNull);
    expect(group1.routingCableIdentity, isNull);
    expect(group2.installationMethod, InstallationMethod.group2);
  });

  test('VAF wall and VAF-G ceiling conditions are representable', () async {
    final vaf = await adapter.adapt(
      request(
        routingCableIdentity: CableRoutingIdentity.vaf,
        installation: surfaceWall(),
      ),
    );
    final vafG = await adapter.adapt(
      request(
        routingCableIdentity: CableRoutingIdentity.vafG,
        installation: surfaceWall(),
      ),
    );

    expect(vaf.isComplete, isTrue);
    expect(vaf.request!.cableType.code, 'VAF');
    expect(vafG.isComplete, isTrue);
    expect(vafG.request!.cableType.code, 'VAF-G');
  });

  test('NYY underground conduit and direct burial are representable', () async {
    final conduit = await adapter.adapt(
      request(
        cableType: CableType.nyy,
        installation: const EngineeringInstallationInput(
          environments: {InstallationEnvironment.underground},
          supports: {InstallationSupport.conduit},
        ),
      ),
    );
    final burial = await adapter.adapt(
      request(
        cableType: CableType.nyy,
        installation: const EngineeringInstallationInput(
          environments: {InstallationEnvironment.directBuried},
          supports: {InstallationSupport.directBurial},
        ),
      ),
    );

    expect(conduit.isComplete, isTrue);
    expect(burial.isComplete, isTrue);
  });

  test('IEC 60502-1 supplemental intrinsic facts remain explicit', () async {
    final adapted = await adapter.adapt(
      request(
        cableType: CableType.iec605021,
        coreType: CoreType.singleCore,
        installation: surfaceWall(hasOuterSheath: true),
        supplemental: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          coreType: CoreType.singleCore,
          insulation: CableInsulation.xlpe,
          conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
        ),
      ),
    );

    expect(adapted.isComplete, isTrue);
    expect(adapted.request!.cableProperties.insulation, CableInsulation.xlpe);
    expect(
      adapted.request!.cableProperties.conductorTemperatureClass,
      ConductorTemperatureClass.xlpeEpr90,
    );
  });

  test('missing IEC 60502-1 intrinsic facts are not defaulted', () async {
    final adapted = await adapter.adapt(
      request(
        cableType: CableType.iec605021,
        coreType: CoreType.singleCore,
        installation: surfaceWall(hasOuterSheath: true),
      ),
    );
    final route = await builder.build(adapted.request!);

    expect(adapted.isComplete, isTrue);
    expect(route.status, AmpacityRoutingStatus.insufficient);
  });

  test(
    'missing tray ventilation and insulator spacing remain incomplete',
    () async {
      final tray = await adapter.adapt(
        request(
          cableType: CableType.nyy,
          installation: const EngineeringInstallationInput(
            environments: {InstallationEnvironment.air},
            supports: {InstallationSupport.ventilatedCableTray},
          ),
        ),
      );
      final insulator = await adapter.adapt(
        request(
          cableType: CableType.nyy,
          coreType: CoreType.singleCore,
          installation: const EngineeringInstallationInput(
            environments: {InstallationEnvironment.air},
            supports: {InstallationSupport.insulators},
          ),
        ),
      );

      expect(
        (await builder.build(tray.request!)).status,
        AmpacityRoutingStatus.insufficient,
      );
      expect(
        (await builder.build(insulator.request!)).status,
        AmpacityRoutingStatus.insufficient,
      );
    },
  );

  test(
    'missing production physical installation remains insufficient',
    () async {
      final adapted = await adapter.adapt(request());

      expect(adapted.status, AmpacityRoutingStatus.insufficient);
      expect(adapted.request, isNull);
      expect(adapted.missingFields, ['engineeringInstallation']);
    },
  );
}
