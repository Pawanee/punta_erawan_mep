import 'package:flutter_test/flutter_test.dart';

import 'package:mep_project/features/electrical/voltage_drop/enums/cable_arrangement.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_core_type.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_request.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_table_entry.dart';
import 'package:mep_project/features/electrical/voltage_drop/services/voltage_drop_calculation_service.dart';

void main() {
  const service = VoltageDropCalculationService();

  VoltageDropTableEntry singleCorePvc50() {
    return const VoltageDropTableEntry(
      table: '9.1',
      insulation: CableInsulation.pvc,
      coreType: VoltageDropCoreType.singleCore,
      temperatureC: 70,
      sizeSqmm: 50,
      singlePhaseGroup1_2_5: 1.00,
      singlePhaseTouching: 0.94,
      singlePhaseSpaced: 0.97,
      threePhaseGroup1_2_5: 0.85,
      threePhaseTrefoil: 0.81,
      threePhaseFlat: 0.84,
      threePhaseSpaced: 0.86,
    );
  }

  test('Group 1, Group 2 and Group 5 must use the same table value', () {
    const groups = <VoltageDropInstallationGroup>[
      VoltageDropInstallationGroup.group1,
      VoltageDropInstallationGroup.group2,
      VoltageDropInstallationGroup.group5,
    ];

    for (final group in groups) {
      final result = service.calculate(
        request: VoltageDropRequest(
          insulation: CableInsulation.pvc,
          coreType: VoltageDropCoreType.singleCore,
          phase: VoltagePhase.singlePhase,
          sizeSqmm: 50,
          currentA: 100,
          lengthM: 50,
          systemVoltage: 230,
          allowableVoltageDropPercent: 3,
          installationGroup: group,
        ),
        rows: [singleCorePvc50()],
      );

      expect(result.isSuccess, isTrue);
      expect(result.mvPerAperM, 1.00);
      expect(result.voltageDropV, 5.0);
    }
  });

  test('Voltage drop formula must be mV/A/m x I x L / 1000', () {
    final result = service.calculate(
      request: const VoltageDropRequest(
        insulation: CableInsulation.pvc,
        coreType: VoltageDropCoreType.singleCore,
        phase: VoltagePhase.singlePhase,
        sizeSqmm: 50,
        currentA: 100,
        lengthM: 50,
        systemVoltage: 230,
        allowableVoltageDropPercent: 3,
        installationGroup: VoltageDropInstallationGroup.group1,
      ),
      rows: [singleCorePvc50()],
    );

    expect(result.isSuccess, isTrue);
    expect(result.voltageDropV, closeTo(5.0, 0.000001));
    expect(result.voltageDropPercent, closeTo(2.173913, 0.000001));
    expect(result.isWithinLimit, isTrue);
  });

  test('Group 3 single-phase Touching must use Touching column', () {
    final result = service.calculate(
      request: const VoltageDropRequest(
        insulation: CableInsulation.pvc,
        coreType: VoltageDropCoreType.singleCore,
        phase: VoltagePhase.singlePhase,
        sizeSqmm: 50,
        currentA: 100,
        lengthM: 50,
        systemVoltage: 230,
        allowableVoltageDropPercent: 3,
        installationGroup: VoltageDropInstallationGroup.group3,
        arrangement: CableArrangement.touching,
      ),
      rows: [singleCorePvc50()],
    );

    expect(result.isSuccess, isTrue);
    expect(result.mvPerAperM, 0.94);
    expect(result.voltageDropV, closeTo(4.7, 0.000001));
    expect(result.voltageDropPercent, closeTo(2.043478, 0.000001));
  });

  test('Group 3 single-phase without arrangement must fail', () {
    final result = service.calculate(
      request: const VoltageDropRequest(
        insulation: CableInsulation.pvc,
        coreType: VoltageDropCoreType.singleCore,
        phase: VoltagePhase.singlePhase,
        sizeSqmm: 50,
        currentA: 100,
        lengthM: 50,
        systemVoltage: 230,
        allowableVoltageDropPercent: 3,
        installationGroup: VoltageDropInstallationGroup.group3,
      ),
      rows: [singleCorePvc50()],
    );

    expect(result.isSuccess, isFalse);
  });

  test('Three-phase Group 1/2/5 must use three-phase group column', () {
    final result = service.calculate(
      request: const VoltageDropRequest(
        insulation: CableInsulation.pvc,
        coreType: VoltageDropCoreType.singleCore,
        phase: VoltagePhase.threePhase,
        sizeSqmm: 50,
        currentA: 100,
        lengthM: 100,
        systemVoltage: 400,
        allowableVoltageDropPercent: 3,
        installationGroup: VoltageDropInstallationGroup.group2,
      ),
      rows: [singleCorePvc50()],
    );

    expect(result.isSuccess, isTrue);
    expect(result.mvPerAperM, 0.85);
    expect(result.voltageDropV, closeTo(8.5, 0.000001));
    expect(result.voltageDropPercent, closeTo(2.125, 0.000001));
  });
}
