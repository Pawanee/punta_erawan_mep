import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table.dart';
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
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/active_ampacity_orchestrator_v2.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('IEC 01 Group 2 resolves through Table 5-20 in Routing V2', () async {
    final result = await ActiveAmpacityOrchestratorV2().prepare(
      const CableDesignRequestV2(
        loadCurrent: 16,
        phaseSystem: PhaseSystem.singlePhase,
        routingElectricalSystem: RoutingElectricalSystem.singlePhaseAc,
        loadedConductors: 2,
        coreType: CoreType.singleCore,
        ambientTemperature: 40,
        identity: CableRoutingIdentity.iec01,
        engineeringInstallation: EngineeringInstallationInput(
          environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
          supports: {InstallationSupport.wiringEnclosure},
          hasOuterSheath: false,
          groupedCircuitCount: 1,
        ),
        supplementalCableProperties: SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          coreType: CoreType.singleCore,
          insulation: CableInsulation.pvc,
          conductorTemperatureClass: ConductorTemperatureClass.pvc70,
          hasOuterSheath: false,
        ),
      ),
    );

    expect(result.status, AmpacityRoutingStatus.resolved);
    expect(result.routingResult!.ampacityTable, AmpacityTable.table520);
    expect(result.selected!.candidate.sourceTableId, '5-20');
    expect(result.selected!.candidate.installationGroupNumber, 2);
    expect(
      result.selected!.candidate.applicableCableIdentities,
      contains(CableRoutingIdentity.iec01),
    );
  });

  test(
    'Table 5-20 grouping correction remains fail closed when unsupported',
    () async {
      final result = await ActiveAmpacityOrchestratorV2().prepare(
        const CableDesignRequestV2(
          loadCurrent: 16,
          phaseSystem: PhaseSystem.singlePhase,
          routingElectricalSystem: RoutingElectricalSystem.singlePhaseAc,
          loadedConductors: 2,
          coreType: CoreType.singleCore,
          ambientTemperature: 40,
          identity: CableRoutingIdentity.iec01,
          engineeringInstallation: EngineeringInstallationInput(
            environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
            supports: {InstallationSupport.wiringEnclosure},
            hasOuterSheath: false,
            groupedCircuitCount: 2,
          ),
          supplementalCableProperties: SupplementalCablePropertiesInput(
            cableShape: CableShape.round,
            coreType: CoreType.singleCore,
            insulation: CableInsulation.pvc,
            conductorTemperatureClass: ConductorTemperatureClass.pvc70,
            hasOuterSheath: false,
          ),
        ),
      );

      expect(result.status, AmpacityRoutingStatus.insufficient);
      expect(result.selected, isNull);
      expect(result.reason, contains('correction context'));
    },
  );
}
