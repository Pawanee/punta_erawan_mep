import 'package:flutter_test/flutter_test.dart';

import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_design_request.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_cable_selection_request.dart';
import 'package:mep_project/features/electrical/voltage_drop/services/voltage_drop_cable_design_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final engine = VoltageDropCableDesignEngine();

  VoltageDropCableSelectionRequest request({
    required double current,
    required double length,
    required VoltageDropInstallationGroup group,
  }) {
    return VoltageDropCableSelectionRequest(
      cableRequest: CableDesignRequest(
        loadCurrent: current,
        phaseSystem: PhaseSystem.threePhase,
        cableType: CableType.iec01,
        installationMethod: InstallationMethod.group1,
        loadedConductors: 3,
        coreType: CoreType.singleCore,
        ambientTemperature: 30,
        groupingCircuits: 1,
        allowableVoltageDrop: 3,
      ),
      insulation: CableInsulation.pvc,
      phase: VoltagePhase.threePhase,
      lengthM: length,
      systemVoltage: 400,
      allowableVoltageDropPercent: 3,
      installationGroup: group,
    );
  }

  group('PART 6 - Auto Cable Selection', () {
    test('250 A / 100 m selects 1 x 240 sq.mm', () async {
      final result = await engine.design(
        request(
          current: 250,
          length: 100,
          group: VoltageDropInstallationGroup.group1,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.cableSizeSqmm, 240);
      expect(result.runs, 1);
      expect(result.cableArrangement, '1 × 240 sq.mm');
      expect(result.ampacity, 249);
      expect(result.requiredCurrent, 250);
      expect(result.baseAmpacityPerRun, closeTo(249, 0.000001));
      expect(result.groupingFactor, closeTo(1.0, 0.000001));
      expect(result.temperatureFactor, closeTo(1.15, 0.000001));
      expect(result.correctedAmpacityPerRun, closeTo(286.35, 0.000001));
      expect(result.voltageDropV, closeTo(6.75, 0.000001));
      expect(result.voltageDropPercent, closeTo(1.6875, 0.000001));
    });

    test('250 A / 300 m increases cable to 2 x 185 sq.mm', () async {
      final result = await engine.design(
        request(
          current: 250,
          length: 300,
          group: VoltageDropInstallationGroup.group1,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.cableSizeSqmm, 185);
      expect(result.runs, 2);
      expect(result.cableArrangement, '2 × 185 sq.mm');
      expect(result.ampacity, 213);
      expect(result.voltageDropV, closeTo(11.625, 0.000001));
      expect(result.voltageDropPercent, closeTo(2.90625, 0.000001));
    });

    test('100 A / 100 m / 10 grouped circuits selects 1 x 185 sq.mm', () async {
      final req = VoltageDropCableSelectionRequest(
        cableRequest: CableDesignRequest(
          loadCurrent: 100,
          phaseSystem: PhaseSystem.threePhase,
          cableType: CableType.iec01,
          installationMethod: InstallationMethod.group1,
          loadedConductors: 3,
          coreType: CoreType.singleCore,
          ambientTemperature: 30,
          groupingCircuits: 10,
          allowableVoltageDrop: 3,
        ),
        insulation: CableInsulation.pvc,
        phase: VoltagePhase.threePhase,
        lengthM: 100,
        systemVoltage: 400,
        allowableVoltageDropPercent: 3,
        installationGroup: VoltageDropInstallationGroup.group1,
      );

      final result = await engine.design(req);

      expect(result.isSuccess, isTrue);
      expect(result.cableSizeSqmm, 185);
      expect(result.runs, 1);
      expect(result.requiredCurrent, closeTo(222.222222, 0.000001));
      expect(result.baseAmpacityPerRun, closeTo(213, 0.000001));
      expect(result.groupingFactor, closeTo(0.45, 0.000001));
      expect(result.temperatureFactor, closeTo(1.15, 0.000001));
      expect(result.correctedAmpacityPerRun, closeTo(110.2275, 0.000001));
      expect(result.voltageDropPercent, closeTo(0.775, 0.000001));
    });

    test('returns error when no cable can satisfy both conditions', () async {
      final result = await engine.design(
        request(
          current: 1000,
          length: 1000,
          group: VoltageDropInstallationGroup.group1,
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'ไม่พบขนาดสายที่ผ่านทั้ง Ampacity และ Voltage Drop',
      );
    });
  });
}
