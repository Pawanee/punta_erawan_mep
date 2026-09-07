import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
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
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/resolved_correction_state_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/routing_electrical_system.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_request_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/active_ampacity_orchestrator_v2.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final orchestrator = ActiveAmpacityOrchestratorV2();

  CableDesignRequestV2 request({
    required CableRoutingIdentity identity,
    required CoreType coreType,
    required int loadedConductors,
    required double loadCurrent,
    required double ambient,
    required EngineeringInstallationInput installation,
    required SupplementalCablePropertiesInput supplemental,
    RoutingElectricalSystem? electricalSystem,
  }) => CableDesignRequestV2(
    loadCurrent: loadCurrent,
    phaseSystem: loadedConductors == 3
        ? PhaseSystem.threePhase
        : PhaseSystem.singlePhase,
    routingElectricalSystem: electricalSystem,
    loadedConductors: loadedConductors,
    coreType: coreType,
    ambientTemperature: ambient,
    routingMode: CableDesignRoutingMode.routingV2,
    identity: identity,
    engineeringInstallation: installation,
    supplementalCableProperties: supplemental,
  );

  const pvc = SupplementalCablePropertiesInput(
    cableShape: CableShape.round,
    insulation: CableInsulation.pvc,
    conductorTemperatureClass: ConductorTemperatureClass.pvc70,
  );
  const xlpe = SupplementalCablePropertiesInput(
    cableShape: CableShape.round,
    insulation: CableInsulation.xlpe,
    conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
  );

  test('NYY in underground conduit selects Table 5-23 Group 5', () async {
    final result = await orchestrator.prepare(
      request(
        identity: CableRoutingIdentity.nyy,
        coreType: CoreType.multiCore,
        loadedConductors: 3,
        loadCurrent: 50,
        ambient: 30,
        installation: const EngineeringInstallationInput(
          environments: {InstallationEnvironment.underground},
          supports: {InstallationSupport.conduit},
          hasOuterSheath: true,
          groupedCircuitCount: 1,
        ),
        supplemental: pvc,
      ),
    );

    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(result.routingResult!.ampacityTable, AmpacityTable.table523);
    expect(result.selected!.candidate.sourceTableId, '5-23');
    expect(result.selected!.candidate.installationGroupNumber, 5);
    expect(result.selected!.candidate.sizeSqmm, 10);
    expect(result.selected!.candidate.baseAmpacity, 55);
    expect(
      result.selected!.groupingApplication.state,
      ResolvedCorrectionStateV2.notRequired,
    );
  });

  test('direct-buried IEC 60502-1 XLPE selects Table 5-29 Group 6', () async {
    final result = await orchestrator.prepare(
      request(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.multiCore,
        loadedConductors: 3,
        loadCurrent: 100,
        ambient: 30,
        electricalSystem: RoutingElectricalSystem.threePhaseAc,
        installation: const EngineeringInstallationInput(
          environments: {InstallationEnvironment.directBuried},
          supports: {InstallationSupport.directBurial},
          hasOuterSheath: true,
          groupedCircuitCount: 1,
        ),
        supplemental: xlpe,
      ),
    );

    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(result.routingResult!.ampacityTable, AmpacityTable.table529);
    expect(result.selected!.candidate.sourceTableId, '5-29');
    expect(result.selected!.candidate.installationGroupNumber, 6);
    expect(result.selected!.candidate.sizeSqmm, 16);
    expect(result.selected!.candidate.baseAmpacity, 119);
  });

  test(
    'IEC 60502-1 XLPE in air conduit executes existing Table 5-27',
    () async {
      final result = await orchestrator.prepare(
        request(
          identity: CableRoutingIdentity.iec605021,
          coreType: CoreType.multiCore,
          loadedConductors: 3,
          loadCurrent: 70,
          ambient: 40,
          electricalSystem: RoutingElectricalSystem.threePhaseAc,
          installation: const EngineeringInstallationInput(
            environments: {InstallationEnvironment.embeddedInConcreteWall},
            supports: {InstallationSupport.wiringEnclosure},
            hasOuterSheath: true,
            groupedCircuitCount: 1,
          ),
          supplemental: xlpe,
        ),
      );

      expect(result.status, AmpacityRoutingStatus.resolved);
      expect(result.routingResult!.ampacityTable, AmpacityTable.table527);
      expect(result.selected!.candidate.sourceTableId, '5-27');
      expect(result.selected!.candidate.installationGroupNumber, 2);
      expect(result.selected!.candidate.sizeSqmm, 16);
      expect(result.selected!.candidate.baseAmpacity, 73);
    },
  );

  test(
    'underground execution fails closed when circuit count is unknown',
    () async {
      final result = await orchestrator.prepare(
        request(
          identity: CableRoutingIdentity.nyy,
          coreType: CoreType.singleCore,
          loadedConductors: 2,
          loadCurrent: 20,
          ambient: 30,
          installation: const EngineeringInstallationInput(
            environments: {InstallationEnvironment.underground},
            supports: {InstallationSupport.conduit},
            hasOuterSheath: true,
          ),
          supplemental: pvc,
        ),
      );

      expect(result.status, AmpacityRoutingStatus.insufficient);
      expect(result.selected, isNull);
      expect(result.candidates, isNotEmpty);
      expect(result.reason, contains('correction context is unresolved'));
    },
  );

  test('Table 5-44 dependency fails closed away from 30C', () async {
    final result = await orchestrator.prepare(
      request(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        loadedConductors: 2,
        loadCurrent: 20,
        ambient: 35,
        electricalSystem: RoutingElectricalSystem.singlePhaseAc,
        installation: const EngineeringInstallationInput(
          environments: {InstallationEnvironment.underground},
          supports: {InstallationSupport.conduit},
          hasOuterSheath: true,
          groupedCircuitCount: 1,
        ),
        supplemental: xlpe,
      ),
    );

    expect(result.routingResult!.ampacityTable, AmpacityTable.table529);
    expect(result.status, AmpacityRoutingStatus.insufficient);
    expect(result.selected, isNull);
  });

  test('three loaded conductors reject DC without falling back', () async {
    final result = await orchestrator.prepare(
      request(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        loadedConductors: 3,
        loadCurrent: 20,
        ambient: 30,
        electricalSystem: RoutingElectricalSystem.dc,
        installation: const EngineeringInstallationInput(
          environments: {InstallationEnvironment.directBuried},
          supports: {InstallationSupport.directBurial},
          hasOuterSheath: true,
          groupedCircuitCount: 1,
        ),
        supplemental: xlpe,
      ),
    );

    expect(result.routingResult!.ampacityTable, AmpacityTable.table529);
    expect(result.status, AmpacityRoutingStatus.noMatch);
    expect(result.selected, isNull);
    expect(result.candidates, isEmpty);
  });
}
