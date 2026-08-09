import 'package:flutter_test/flutter_test.dart';

import 'package:mep_project/features/electrical/voltage_drop/enums/cable_arrangement.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_core_type.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_request.dart';
import 'package:mep_project/features/electrical/voltage_drop/repositories/voltage_drop_repository.dart';
import 'package:mep_project/features/electrical/voltage_drop/services/voltage_drop_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repository = VoltageDropRepository();
  const service = VoltageDropCalculationService();

  group('PART 5 - Real Engineering Tests', () {
    test('Case 1: PVC Single Core / Group 1 / 3-Phase / 95 sq.mm', () async {
      final rows = await repository.loadTable(
        insulation: CableInsulation.pvc,
        coreType: VoltageDropCoreType.singleCore,
      );

      final result = service.calculate(
        request: const VoltageDropRequest(
          insulation: CableInsulation.pvc,
          coreType: VoltageDropCoreType.singleCore,
          phase: VoltagePhase.threePhase,
          sizeSqmm: 95,
          currentA: 100,
          lengthM: 100,
          systemVoltage: 400,
          allowableVoltageDropPercent: 3,
          installationGroup: VoltageDropInstallationGroup.group1,
        ),
        rows: rows,
      );

      expect(result.isSuccess, isTrue);
      expect(result.table, '9.1');
      expect(result.mvPerAperM, 0.48);
      expect(result.voltageDropV, closeTo(4.8, 0.000001));
      expect(result.voltageDropPercent, closeTo(1.2, 0.000001));
      expect(result.isWithinLimit, isTrue);
    });

    test('Case 2: Group 2 and Group 5 must use the same column as Group 1', () async {
      final rows = await repository.loadTable(
        insulation: CableInsulation.pvc,
        coreType: VoltageDropCoreType.singleCore,
      );

      VoltageDropResultLike calc(VoltageDropInstallationGroup group) {
        final r = service.calculate(
          request: VoltageDropRequest(
            insulation: CableInsulation.pvc,
            coreType: VoltageDropCoreType.singleCore,
            phase: VoltagePhase.threePhase,
            sizeSqmm: 95,
            currentA: 100,
            lengthM: 100,
            systemVoltage: 400,
            allowableVoltageDropPercent: 3,
            installationGroup: group,
          ),
          rows: rows,
        );
        return VoltageDropResultLike(r.mvPerAperM, r.voltageDropPercent);
      }

      final g1 = calc(VoltageDropInstallationGroup.group1);
      final g2 = calc(VoltageDropInstallationGroup.group2);
      final g5 = calc(VoltageDropInstallationGroup.group5);

      expect(g1.mvPerAperM, 0.48);
      expect(g2.mvPerAperM, 0.48);
      expect(g5.mvPerAperM, 0.48);
      expect(g1.voltageDropPercent, closeTo(1.2, 0.000001));
      expect(g2.voltageDropPercent, closeTo(1.2, 0.000001));
      expect(g5.voltageDropPercent, closeTo(1.2, 0.000001));
    });

    test('Case 3: PVC Single Core / Group 3 / 3-Phase Trefoil', () async {
      final rows = await repository.loadTable(
        insulation: CableInsulation.pvc,
        coreType: VoltageDropCoreType.singleCore,
      );

      final result = service.calculate(
        request: const VoltageDropRequest(
          insulation: CableInsulation.pvc,
          coreType: VoltageDropCoreType.singleCore,
          phase: VoltagePhase.threePhase,
          sizeSqmm: 95,
          currentA: 100,
          lengthM: 100,
          systemVoltage: 400,
          allowableVoltageDropPercent: 3,
          installationGroup: VoltageDropInstallationGroup.group3,
          arrangement: CableArrangement.trefoil,
        ),
        rows: rows,
      );

      expect(result.isSuccess, isTrue);
      expect(result.mvPerAperM, 0.44);
      expect(result.voltageDropV, closeTo(4.4, 0.000001));
      expect(result.voltageDropPercent, closeTo(1.1, 0.000001));
      expect(result.isWithinLimit, isTrue);
    });

    test('Case 4: PVC Multi Core / 3-Phase / 50 sq.mm', () async {
      final rows = await repository.loadTable(
        insulation: CableInsulation.pvc,
        coreType: VoltageDropCoreType.multiCore,
      );

      final result = service.calculate(
        request: const VoltageDropRequest(
          insulation: CableInsulation.pvc,
          coreType: VoltageDropCoreType.multiCore,
          phase: VoltagePhase.threePhase,
          sizeSqmm: 50,
          currentA: 100,
          lengthM: 100,
          systemVoltage: 400,
          allowableVoltageDropPercent: 3,
          installationGroup: VoltageDropInstallationGroup.group7,
        ),
        rows: rows,
      );

      expect(result.isSuccess, isTrue);
      expect(result.table, '9.2');
      expect(result.mvPerAperM, 0.8);
      expect(result.voltageDropV, closeTo(8.0, 0.000001));
      expect(result.voltageDropPercent, closeTo(2.0, 0.000001));
      expect(result.isWithinLimit, isTrue);
    });

    test('Case 5: Same cable becomes NOT acceptable when distance increases', () async {
      final rows = await repository.loadTable(
        insulation: CableInsulation.pvc,
        coreType: VoltageDropCoreType.singleCore,
      );

      final result = service.calculate(
        request: const VoltageDropRequest(
          insulation: CableInsulation.pvc,
          coreType: VoltageDropCoreType.singleCore,
          phase: VoltagePhase.threePhase,
          sizeSqmm: 95,
          currentA: 100,
          lengthM: 300,
          systemVoltage: 400,
          allowableVoltageDropPercent: 3,
          installationGroup: VoltageDropInstallationGroup.group1,
        ),
        rows: rows,
      );

      expect(result.isSuccess, isTrue);
      expect(result.voltageDropV, closeTo(14.4, 0.000001));
      expect(result.voltageDropPercent, closeTo(3.6, 0.000001));
      expect(result.isWithinLimit, isFalse);
    });
  });
}

// Small adapter keeps the Group 1/2/5 comparison test concise.
class VoltageDropResultLike {
  const VoltageDropResultLike(this.mvPerAperM, this.voltageDropPercent);

  final double? mvPerAperM;
  final double? voltageDropPercent;
}