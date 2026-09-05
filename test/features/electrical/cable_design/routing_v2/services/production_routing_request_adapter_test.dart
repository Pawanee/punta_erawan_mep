import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/models/supplemental_cable_properties_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/routing_electrical_system.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_request_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/ampacity_routing_context_builder.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/production_routing_request_adapter.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final adapter = ProductionRoutingRequestAdapter();
  final builder = AmpacityRoutingContextBuilder();

  CableDesignRequestV2 request({
    CableRoutingIdentity? identity,
    CoreType coreType = CoreType.multiCore,
    EngineeringInstallationInput? installation,
    SupplementalCablePropertiesInput? supplemental,
    RoutingElectricalSystem? routingElectricalSystem,
  }) => CableDesignRequestV2(
    loadCurrent: 10,
    phaseSystem: PhaseSystem.singlePhase,
    routingElectricalSystem: routingElectricalSystem,
    loadedConductors: 2,
    coreType: coreType,
    ambientTemperature: 40,
    engineeringInstallation: installation,
    identity: identity,
    supplementalCableProperties: supplemental,
  );

  EngineeringInstallationInput surfaceWall({bool? hasOuterSheath}) =>
      EngineeringInstallationInput(
        environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
        supports: {InstallationSupport.surfaceMount},
        hasOuterSheath: hasOuterSheath,
      );

  test(
    'native V2 request leaves routing facts unresolved without defaults',
    () {
      final native = request();

      expect(native.engineeringInstallation, isNull);
      expect(native.supplementalCableProperties, isNull);
      expect(native.identity, isNull);
    },
  );

  test('VAF wall and VAF-G ceiling conditions are representable', () async {
    final vaf = await adapter.adapt(
      request(identity: CableRoutingIdentity.vaf, installation: surfaceWall()),
    );
    final vafG = await adapter.adapt(
      request(identity: CableRoutingIdentity.vafG, installation: surfaceWall()),
    );

    expect(vaf.isComplete, isTrue);
    expect(vaf.request!.cableType.code, 'VAF');
    expect(vafG.isComplete, isTrue);
    expect(vafG.request!.cableType.code, 'VAF-G');
  });

  test('NYY underground conduit and direct burial are representable', () async {
    final conduit = await adapter.adapt(
      request(
        identity: CableRoutingIdentity.nyy,
        installation: const EngineeringInstallationInput(
          environments: {InstallationEnvironment.underground},
          supports: {InstallationSupport.conduit},
        ),
      ),
    );
    final burial = await adapter.adapt(
      request(
        identity: CableRoutingIdentity.nyy,
        installation: const EngineeringInstallationInput(
          environments: {InstallationEnvironment.directBuried},
          supports: {InstallationSupport.directBurial},
        ),
      ),
    );

    expect(conduit.isComplete, isTrue);
    expect(burial.isComplete, isTrue);
  });

  test(
    'approved compatibility bridge is limited to VAF VAF-G IEC 10 and NYY',
    () async {
      for (final identity in [
        CableRoutingIdentity.vaf,
        CableRoutingIdentity.vafG,
        CableRoutingIdentity.iec10,
        CableRoutingIdentity.nyy,
      ]) {
        final adapted = await adapter.adapt(
          request(identity: identity, installation: surfaceWall()),
        );
        expect(adapted.isComplete, isTrue, reason: identity.code);
        expect(
          adapted.request!.electricalSystem,
          RoutingElectricalSystem.singlePhaseAc,
        );
      }

      final nonAllowlisted = await adapter.adapt(
        request(
          identity: CableRoutingIdentity.iec01,
          coreType: CoreType.singleCore,
          installation: surfaceWall(hasOuterSheath: false),
        ),
      );
      expect(nonAllowlisted.status, AmpacityRoutingStatus.insufficient);
      expect(nonAllowlisted.request, isNull);
      expect(nonAllowlisted.missingFields, contains('routingElectricalSystem'));
    },
  );

  test('IEC 60502-1 supplemental intrinsic facts remain explicit', () async {
    final adapted = await adapter.adapt(
      request(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        routingElectricalSystem: RoutingElectricalSystem.dc,
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
    expect(adapted.request!.electricalSystem, RoutingElectricalSystem.dc);
    expect(adapted.request!.installationConditions.hasOuterSheath, isTrue);
    expect(adapted.request!.cableProperties.hasOuterSheath, isTrue);
    expect(adapted.request!.cableProperties.insulation, CableInsulation.xlpe);
    expect(
      adapted.request!.cableProperties.conductorTemperatureClass,
      ConductorTemperatureClass.xlpeEpr90,
    );
  });

  test('missing IEC 60502-1 intrinsic facts are not defaulted', () async {
    final adapted = await adapter.adapt(
      request(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        routingElectricalSystem: RoutingElectricalSystem.singlePhaseAc,
        installation: surfaceWall(hasOuterSheath: true),
      ),
    );
    final route = await builder.build(adapted.request!);

    expect(adapted.isComplete, isTrue);
    expect(route.status, AmpacityRoutingStatus.insufficient);
  });

  test(
    'IEC 60502-1 requires an explicit system at the adapter boundary',
    () async {
      final adapted = await adapter.adapt(
        request(
          identity: CableRoutingIdentity.iec605021,
          coreType: CoreType.singleCore,
          installation: surfaceWall(hasOuterSheath: true),
          supplemental: const SupplementalCablePropertiesInput(
            cableShape: CableShape.round,
            insulation: CableInsulation.xlpe,
            conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
          ),
        ),
      );
      expect(adapted.status, AmpacityRoutingStatus.insufficient);
      expect(adapted.request, isNull);
      expect(adapted.missingFields, contains('routingElectricalSystem'));
    },
  );

  test('explicit IEC 60502-1 AC and DC systems take precedence', () async {
    for (final system in [
      RoutingElectricalSystem.threePhaseAc,
      RoutingElectricalSystem.dc,
    ]) {
      final adapted = await adapter.adapt(
        request(
          identity: CableRoutingIdentity.iec605021,
          coreType: CoreType.singleCore,
          routingElectricalSystem: system,
          installation: surfaceWall(hasOuterSheath: true),
        ),
      );
      expect(adapted.isComplete, isTrue);
      expect(adapted.request!.electricalSystem, system);
    }
  });

  test(
    'missing tray ventilation and insulator spacing remain incomplete',
    () async {
      final tray = await adapter.adapt(
        request(
          identity: CableRoutingIdentity.nyy,
          installation: const EngineeringInstallationInput(
            environments: {InstallationEnvironment.air},
            supports: {InstallationSupport.ventilatedCableTray},
          ),
        ),
      );
      final insulator = await adapter.adapt(
        request(
          identity: CableRoutingIdentity.nyy,
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
