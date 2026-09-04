import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/voltage_drop/models/voltage_drop_cable_selection_result.dart';
import 'package:mep_project/features/electrical/voltage_drop/services/voltage_drop_result_integration_service.dart';

void main() {
  const service = VoltageDropResultIntegrationService();

  test('PART 7: integrates parallel run result correctly', () {
    const selection = VoltageDropCableSelectionResult(
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
    );

    final result = service.integrate(
      selectionResult: selection,
      loadCurrent: 250,
      cableLengthM: 100,
    );

    expect(result.isSuccess, isTrue);
    expect(result.loadCurrent, 250);
    expect(result.requiredCurrent, 250);
    expect(result.runs, 2);
    expect(result.currentPerRun, 125);
    expect(result.ampacityPerRun, 143);
    expect(result.totalAmpacity, 286);
    expect(result.cableSizeSqmm, 95);
    expect(result.cableLengthM, 100);
    expect(result.voltageDropV, 6);
    expect(result.voltageDropPercent, 1.5);
    expect(result.cableArrangement, '2 × 95 sq.mm');
  });

  test('PART 7: does not calculate a result from failed selection', () {
    final selection = VoltageDropCableSelectionResult.error(
      'ไม่พบขนาดสายที่ผ่านทั้ง Ampacity และ Voltage Drop',
    );

    final result = service.integrate(
      selectionResult: selection,
      loadCurrent: 250,
      cableLengthM: 100,
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('ไม่พบขนาดสาย'));
  });

  test('VD disabled is presented as not considered, never calculated zero', () {
    final selection = VoltageDropCableSelectionResult.ampacityOnly(
      cableSizeSqmm: 240,
      ampacity: 249,
      cableArrangement: '1 × 240 sq.mm',
      ampacityReference: 'Table 5-20',
      groupingFactor: 1,
      temperatureFactor: 1.15,
      baseAmpacityPerRun: 249,
      correctedAmpacityPerRun: 286.35,
      sourceTableId: '5-20',
      sourceTableDisplayName: 'Table 5-20',
      installationMethod: InstallationMethod.group1,
      loadedConductors: 3,
      coreType: CoreType.singleCore,
      cableType: CableType.iec01,
      conductorTemperatureClass: ConductorTemperatureClass.pvc70,
      ambientTemperatureC: 30,
      groupingCircuits: 1,
      groupingReference: 'Table 5-8',
      temperatureReference: 'Table 5-43',
      requiredCurrent: 250,
      runs: 1,
    );

    final result = service.integrate(
      selectionResult: selection,
      loadCurrent: 250,
      cableLengthM: 0,
    );

    expect(result.isSuccess, isTrue);
    expect(result.voltageDropConsidered, isFalse);
    expect(result.message, contains('voltage drop not considered'));
    expect(result.voltageDropV, isNull);
    expect(result.voltageDropPercent, isNull);
    expect(result.mvPerAperM, isNull);
    expect(result.voltageDropReference, isNull);
  });
}
