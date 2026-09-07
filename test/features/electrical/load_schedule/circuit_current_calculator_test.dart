import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/load_schedule/load_schedule.dart';

void main() {
  const tolerance = 1e-10;
  const calculator = CircuitCurrentCalculator();
  final system = PanelElectricalSystem(
    phaseSystem: PanelPhaseSystem.threePhase,
    lineToNeutralVoltageV: 230,
    lineToLineVoltageV: 400,
    frequencyHz: 50,
  );

  CircuitDefinition active({
    required CircuitPhaseConfiguration phaseConfiguration,
    required LoadInput load,
  }) => CircuitDefinition(
    circuitNo: 1,
    description: 'Test load',
    status: CircuitStatus.active,
    phaseConfiguration: phaseConfiguration,
    loadInput: load,
    phaseAssignmentMode:
        phaseConfiguration == CircuitPhaseConfiguration.singlePhase
        ? PhaseAssignmentMode.automatic
        : PhaseAssignmentMode.manual,
    phaseAssignment: phaseConfiguration == CircuitPhaseConfiguration.threePhase
        ? PhaseAssignment.rst
        : null,
  );

  test('direct VA single-phase uses S / V_LN', () {
    final result = calculator.calculate(
      active(
        phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
        load: LoadInput.directVa(2300),
      ),
      system,
    );
    expect(result.designCurrentA, closeTo(10, tolerance));
    expect(result.apparentPowerVa, 2300);
    expect(result.realPowerW, isNull);
    expect(result.powerFactorUsed, isNull);
    expect(result.voltageBasis, VoltageBasis.lineToNeutral);
    expect(result.voltageUsedV, 230);
    expect(result.formulaId, CurrentFormulaId.directVaSinglePhase);
  });

  test('direct VA three-phase treats VA as total three-phase VA', () {
    final result = calculator.calculate(
      active(
        phaseConfiguration: CircuitPhaseConfiguration.threePhase,
        load: LoadInput.directVa(12000),
      ),
      system,
    );
    expect(
      result.designCurrentA,
      closeTo(12000 / (math.sqrt(3) * 400), tolerance),
    );
    expect(result.apparentPowerVa, 12000);
    expect(result.voltageBasis, VoltageBasis.lineToLine);
    expect(result.voltageUsedV, 400);
    expect(result.formulaId, CurrentFormulaId.directVaThreePhase);
  });

  test('quantity × watts + PF single-phase calculates P, S, and I', () {
    final result = calculator.calculate(
      active(
        phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
        load: LoadInput.quantityTimesWatts(
          quantity: 10,
          wattsPerUnit: 100,
          powerFactor: 0.8,
        ),
      ),
      system,
    );
    expect(result.realPowerW, 1000);
    expect(result.apparentPowerVa, 1250);
    expect(result.designCurrentA, closeTo(1250 / 230, tolerance));
    expect(result.powerFactorUsed, 0.8);
    expect(result.formulaId, CurrentFormulaId.quantityWattsPfSinglePhase);
  });

  test('quantity × watts + PF three-phase calculates total S and line I', () {
    final result = calculator.calculate(
      active(
        phaseConfiguration: CircuitPhaseConfiguration.threePhase,
        load: LoadInput.quantityTimesWatts(
          quantity: 12,
          wattsPerUnit: 250,
          powerFactor: 0.75,
        ),
      ),
      system,
    );
    expect(result.realPowerW, 3000);
    expect(result.apparentPowerVa, 4000);
    expect(
      result.designCurrentA,
      closeTo(4000 / (math.sqrt(3) * 400), tolerance),
    );
    expect(result.powerFactorUsed, 0.75);
    expect(result.formulaId, CurrentFormulaId.quantityWattsPfThreePhase);
  });

  test('direct current single-phase preserves raw current and derives S', () {
    const rawCurrent = 7.1234567890123;
    final result = calculator.calculate(
      active(
        phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
        load: LoadInput.directCurrentA(rawCurrent),
      ),
      system,
    );
    expect(result.designCurrentA, rawCurrent);
    expect(result.apparentPowerVa, rawCurrent * 230);
    expect(result.formulaId, CurrentFormulaId.directCurrentSinglePhase);
  });

  test('direct current three-phase treats input as line current', () {
    const rawCurrent = 8.7654321098765;
    final result = calculator.calculate(
      active(
        phaseConfiguration: CircuitPhaseConfiguration.threePhase,
        load: LoadInput.directCurrentA(rawCurrent),
      ),
      system,
    );
    expect(result.designCurrentA, rawCurrent);
    expect(
      result.apparentPowerVa,
      closeTo(math.sqrt(3) * 400 * rawCurrent, tolerance),
    );
    expect(result.formulaId, CurrentFormulaId.directCurrentThreePhase);
  });

  test('calculated result JSON round-trip preserves typed raw values', () {
    final original = calculator.calculate(
      active(
        phaseConfiguration: CircuitPhaseConfiguration.threePhase,
        load: LoadInput.quantityTimesWatts(
          quantity: 7,
          wattsPerUnit: 123.456789,
          powerFactor: 0.91,
        ),
      ),
      system,
    );
    final restored = CurrentCalculationResult.fromJson(original.toJson());
    expect(restored.toJson(), original.toJson());
    expect(restored.sourceReferences, isNotEmpty);
    expect(original.toJson().containsKey('vol'), isFalse);
  });

  test('SPARE and SPACE are not calculated and contain no numeric payload', () {
    for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
      final circuit = CircuitDefinition(
        circuitNo: status == CircuitStatus.spare ? 2 : 3,
        description: status.name,
        status: status,
        phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
        phaseAssignmentMode: PhaseAssignmentMode.automatic,
      );
      final result = calculator.calculate(circuit, system);
      expect(result.status, CalculationStatus.notCalculated);
      expect(result.designCurrentA, isNull);
      expect(result.apparentPowerVa, isNull);
      expect(result.voltageUsedV, isNull);
      expect(result.formulaId, isNull);
    }
  });

  test('LoadInput rejects zero, negative, NaN, infinity, and invalid PF', () {
    for (final invalid in [
      0.0,
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(() => LoadInput.directVa(invalid), throwsArgumentError);
      expect(() => LoadInput.directCurrentA(invalid), throwsArgumentError);
      expect(
        () => LoadInput.quantityTimesWatts(
          quantity: 1,
          wattsPerUnit: invalid,
          powerFactor: 0.8,
        ),
        throwsArgumentError,
      );
    }
    for (final invalidPf in [0.0, -0.1, 1.01, double.nan, double.infinity]) {
      expect(
        () => LoadInput.quantityTimesWatts(
          quantity: 1,
          wattsPerUnit: 100,
          powerFactor: invalidPf,
        ),
        throwsArgumentError,
      );
    }
    for (final invalidQuantity in [0, -1]) {
      expect(
        () => LoadInput.quantityTimesWatts(
          quantity: invalidQuantity,
          wattsPerUnit: 100,
          powerFactor: 0.8,
        ),
        throwsArgumentError,
      );
    }
  });

  test('PanelElectricalSystem rejects non-finite and non-positive values', () {
    for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => PanelElectricalSystem(
          phaseSystem: PanelPhaseSystem.threePhase,
          lineToNeutralVoltageV: invalid,
          lineToLineVoltageV: 400,
          frequencyHz: 50,
        ),
        throwsArgumentError,
      );
      expect(
        () => PanelElectricalSystem(
          phaseSystem: PanelPhaseSystem.threePhase,
          lineToNeutralVoltageV: 230,
          lineToLineVoltageV: invalid,
          frequencyHz: 50,
        ),
        throwsArgumentError,
      );
      expect(
        () => PanelElectricalSystem(
          phaseSystem: PanelPhaseSystem.threePhase,
          lineToNeutralVoltageV: 230,
          lineToLineVoltageV: 400,
          frequencyHz: invalid,
        ),
        throwsArgumentError,
      );
    }
  });

  test(
    'typed result rejects non-finite, non-positive, and invalid PF values',
    () {
      CurrentCalculationResult build({
        double current = 10,
        double apparentPower = 2300,
        double voltage = 230,
        double? realPower,
        double? powerFactor,
        CurrentFormulaId formula = CurrentFormulaId.directVaSinglePhase,
      }) => CurrentCalculationResult.calculated(
        designCurrentA: current,
        apparentPowerVa: apparentPower,
        realPowerW: realPower,
        powerFactorUsed: powerFactor,
        voltageBasis: VoltageBasis.lineToNeutral,
        voltageUsedV: voltage,
        formulaId: formula,
      );

      for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
        expect(() => build(current: invalid), throwsArgumentError);
        expect(() => build(apparentPower: invalid), throwsArgumentError);
        expect(() => build(voltage: invalid), throwsArgumentError);
      }
      expect(
        () => build(
          realPower: 1000,
          powerFactor: 1.1,
          formula: CurrentFormulaId.quantityWattsPfSinglePhase,
        ),
        throwsArgumentError,
      );
      expect(() => build(powerFactor: 0.8), throwsArgumentError);
      expect(() => build(realPower: 1000), throwsArgumentError);
    },
  );

  test('panel compatibility remains fail-closed for three-phase circuit', () {
    final threePhaseCircuit = active(
      phaseConfiguration: CircuitPhaseConfiguration.threePhase,
      load: LoadInput.directVa(1000),
    );
    expect(
      () => PanelDefinition(
        panelId: 'panel-1p',
        panelNo: 'LP-1P',
        electricalSystem: PanelElectricalSystem(
          phaseSystem: PanelPhaseSystem.singlePhase,
          lineToNeutralVoltageV: 230,
          lineToLineVoltageV: 230,
          frequencyHz: 50,
        ),
        circuits: [threePhaseCircuit],
      ),
      throwsArgumentError,
    );
    final incompatibleResult = calculator.calculate(
      threePhaseCircuit,
      PanelElectricalSystem(
        phaseSystem: PanelPhaseSystem.singlePhase,
        lineToNeutralVoltageV: 230,
        lineToLineVoltageV: 230,
        frequencyHz: 50,
      ),
    );
    expect(incompatibleResult.status, CalculationStatus.invalid);
    expect(incompatibleResult.designCurrentA, isNull);
  });

  test(
    'engine has no rounding, demand, efficiency, or phase balancing output',
    () {
      const rawCurrent = 1.23456789012345;
      final result = calculator.calculate(
        active(
          phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
          load: LoadInput.directCurrentA(rawCurrent),
        ),
        system,
      );
      expect(result.designCurrentA, rawCurrent);
      final json = result.toJson();
      expect(json.containsKey('efficiency'), isFalse);
      expect(json.containsKey('demandFactor'), isFalse);
      expect(json.containsKey('phaseAssignment'), isFalse);
      expect(json.containsKey('phaseR'), isFalse);
      expect(json.containsKey('phaseS'), isFalse);
      expect(json.containsKey('phaseT'), isFalse);
    },
  );
}
