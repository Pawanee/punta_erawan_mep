import 'package:flutter_test/flutter_test.dart';

import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_design_request.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_cable_selection_request.dart';
import 'package:mep_project/features/electrical/voltage_drop/services/voltage_drop_cable_design_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final engine = VoltageDropCableDesignEngine();

  VoltageDropCableSelectionRequest request({
    required CableType cableType,
    required double ambientTemperature,
    int groupingCircuits = 1,
  }) {
    final insulation = cableType == CableType.iec605021
        ? CableInsulation.xlpe
        : CableInsulation.pvc;

    return VoltageDropCableSelectionRequest(
      cableRequest: CableDesignRequest(
        loadCurrent: 20,
        phaseSystem: PhaseSystem.threePhase,
        cableType: cableType,
        installationMethod: InstallationMethod.group1,
        loadedConductors: 3,
        coreType: CoreType.singleCore,
        ambientTemperature: ambientTemperature,
        groupingCircuits: groupingCircuits,
      ),
      insulation: insulation,
      phase: VoltagePhase.threePhase,
      lengthM: 30,
      systemVoltage: 400,
      allowableVoltageDropPercent: 3,
      installationGroup: VoltageDropInstallationGroup.group1,
    );
  }

  test('PVC Table 5-20 applies grouping and temperature factors per run',
      () async {
    final result = await engine.design(
      request(cableType: CableType.iec01, ambientTemperature: 40),
    );

    expect(result.isSuccess, isTrue);
    expect(result.ampacityReference, 'Table 5-20');
    expect(result.conductorTemperatureClass, ConductorTemperatureClass.pvc70);
    expect(result.groupingFactor, 1.0);
    expect(result.temperatureFactor, 1.0);
    expect(result.baseAmpacityPerRun, result.ampacity);
    expect(result.correctedAmpacityPerRun, result.baseAmpacityPerRun);
    expect(result.runs, 1);
  });

  test('IEC 60502-1 selects Table 5-27 and XLPE/EPR 90C factor', () async {
    final result = await engine.design(
      request(cableType: CableType.iec605021, ambientTemperature: 40),
    );

    expect(result.isSuccess, isTrue);
    expect(result.ampacityReference, 'Table 5-27');
    expect(
      result.conductorTemperatureClass,
      ConductorTemperatureClass.xlpeEpr90,
    );
    expect(result.temperatureFactor, 1.0);
  });

  test('higher ambient temperature lowers corrected ampacity', () async {
    final at40 = await engine.design(
      request(cableType: CableType.iec01, ambientTemperature: 40),
    );
    final at45 = await engine.design(
      request(cableType: CableType.iec01, ambientTemperature: 45),
    );

    expect(at40.isSuccess, isTrue);
    expect(at45.isSuccess, isTrue);
    expect(at40.temperatureFactor, 1.0);
    expect(at45.temperatureFactor, 0.91);
    expect(
      at45.correctedAmpacityPerRun!,
      lessThan(at45.baseAmpacityPerRun!),
    );
  });

  test('missing temperature factor returns an engineering error', () async {
    final result = await engine.design(
      request(cableType: CableType.iec01, ambientTemperature: 65),
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('Table 5-43'));
  });

  test('unsupported grouping circuit count does not fall back to 1.0',
      () async {
    final result = await engine.design(
      request(
        cableType: CableType.iec01,
        ambientTemperature: 40,
        groupingCircuits: 21,
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('Table 5-8'));
  });
}
