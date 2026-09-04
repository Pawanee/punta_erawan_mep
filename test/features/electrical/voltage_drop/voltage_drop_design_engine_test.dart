import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_design_request.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_cable_selection_request.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_cable_selection_result.dart';
import 'package:mep_project/features/electrical/voltage_drop/services/voltage_drop_cable_design_engine.dart';
import 'package:mep_project/features/electrical/voltage_drop/services/voltage_drop_design_engine.dart';

class _FakeCableDesignEngine extends VoltageDropCableDesignEngine {
  _FakeCableDesignEngine(this.result);

  final VoltageDropCableSelectionResult result;
  VoltageDropCableSelectionRequest? receivedRequest;

  @override
  Future<VoltageDropCableSelectionResult> design(
    VoltageDropCableSelectionRequest request,
  ) async {
    receivedRequest = request;
    return result;
  }
}

class _ThrowingCableDesignEngine extends VoltageDropCableDesignEngine {
  @override
  Future<VoltageDropCableSelectionResult> design(
    VoltageDropCableSelectionRequest request,
  ) => throw StateError('internal detail');
}

VoltageDropCableSelectionRequest _request({
  double current = 250,
  double length = 100,
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
    installationGroup: VoltageDropInstallationGroup.group1,
  );
}

void main() {
  test(
    'PART 8: main engine integrates selection into final design result',
    () async {
      final fakeSelectionEngine = _FakeCableDesignEngine(
        const VoltageDropCableSelectionResult(
          isSuccess: true,
          message: 'ok',
          cableSizeSqmm: 95,
          ampacity: 143,
          cableArrangement: '2 × 95 sq.mm',
          reference: 'Table 5-20',
          groupingFactor: 1.0,
          requiredCurrent: 250,
          voltageDropV: 6.0,
          voltageDropPercent: 1.5,
          mvPerAperM: 0.48,
          runs: 2,
        ),
      );

      final engine = VoltageDropDesignEngine(
        cableDesignEngine: fakeSelectionEngine,
      );

      final request = _request();
      final result = await engine.design(request);

      expect(result.isSuccess, isTrue);
      expect(fakeSelectionEngine.receivedRequest, same(request));
      expect(result.loadCurrent, 250);
      expect(result.groupingFactor, 1.0);
      expect(result.requiredCurrent, 250);
      expect(result.runs, 2);
      expect(result.currentPerRun, 125);
      expect(result.ampacityPerRun, 143);
      expect(result.totalAmpacity, 286);
      expect(result.cableSizeSqmm, 95);
      expect(result.cableArrangement, '2 × 95 sq.mm');
      expect(result.cableLengthM, 100);
      expect(result.voltageDropV, 6.0);
      expect(result.voltageDropPercent, 1.5);
    },
  );

  test('PART 8: main engine propagates failed cable selection', () async {
    final fakeSelectionEngine = _FakeCableDesignEngine(
      VoltageDropCableSelectionResult.error(
        'ไม่พบขนาดสายที่ผ่านทั้ง Ampacity และ Voltage Drop',
      ),
    );

    final engine = VoltageDropDesignEngine(
      cableDesignEngine: fakeSelectionEngine,
    );

    final result = await engine.design(_request());

    expect(result.isSuccess, isFalse);
    expect(
      result.message,
      contains('ไม่พบขนาดสายที่ผ่านทั้ง Ampacity และ Voltage Drop'),
    );
  });

  test(
    'PART 8: rejects invalid load before calling selection engine',
    () async {
      final fakeSelectionEngine = _FakeCableDesignEngine(
        const VoltageDropCableSelectionResult(
          isSuccess: true,
          message: 'should not be called',
        ),
      );

      final engine = VoltageDropDesignEngine(
        cableDesignEngine: fakeSelectionEngine,
      );

      final result = await engine.design(_request(current: 0));

      expect(result.isSuccess, isFalse);
      expect(result.message, 'Load Current ต้องมากกว่า 0 A');
      expect(fakeSelectionEngine.receivedRequest, isNull);
    },
  );

  test(
    'unexpected implementation errors use customer-facing wording',
    () async {
      final engine = VoltageDropDesignEngine(
        cableDesignEngine: _ThrowingCableDesignEngine(),
      );

      final result = await engine.design(_request());

      expect(result.isSuccess, isFalse);
      expect(result.message, 'ไม่สามารถคำนวณได้ กรุณาตรวจสอบข้อมูลที่ป้อน');
      expect(result.message, isNot(contains('internal detail')));
    },
  );
}
