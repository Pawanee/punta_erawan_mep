import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/engineering_installation_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_request_v2.dart';

void main() {
  const wallMounted = EngineeringInstallationInput(
    environments: {InstallationEnvironment.surfaceMountedWallOrCeiling},
    supports: {InstallationSupport.surfaceMount},
  );

  test('constructs a VAF request using only V2 engineering facts', () {
    const request = CableDesignRequestV2(
      loadCurrent: 10,
      phaseSystem: PhaseSystem.singlePhase,
      loadedConductors: 2,
      coreType: CoreType.multiCore,
      ambientTemperature: 40,
      identity: CableRoutingIdentity.vaf,
      engineeringInstallation: wallMounted,
    );

    expect(request.routingMode, CableDesignRoutingMode.routingV2);
    expect(request.identity, CableRoutingIdentity.vaf);
    expect(request.engineeringInstallation, same(wallMounted));
  });

  test('retains VAF-G as a V2-native identity', () {
    const request = CableDesignRequestV2(
      loadCurrent: 10,
      phaseSystem: PhaseSystem.singlePhase,
      loadedConductors: 2,
      coreType: CoreType.multiCore,
      ambientTemperature: 40,
      identity: CableRoutingIdentity.vafG,
      engineeringInstallation: wallMounted,
    );

    expect(request.identity, CableRoutingIdentity.vafG);
    expect(request.engineeringInstallation, same(wallMounted));
  });
}
