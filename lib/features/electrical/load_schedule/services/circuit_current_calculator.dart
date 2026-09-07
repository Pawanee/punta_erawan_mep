import 'dart:math' as math;

import '../enums/circuit_phase_configuration.dart';
import '../enums/circuit_status.dart';
import '../enums/current_formula_id.dart';
import '../enums/panel_phase_system.dart';
import '../enums/voltage_basis.dart';
import '../models/calculation_source_reference.dart';
import '../models/circuit_definition.dart';
import '../models/current_calculation_result.dart';
import '../models/load_input.dart';
import '../models/panel_electrical_system.dart';

class CircuitCurrentCalculator {
  const CircuitCurrentCalculator();

  CurrentCalculationResult calculate(
    CircuitDefinition circuit,
    PanelElectricalSystem electricalSystem,
  ) {
    if (circuit.status != CircuitStatus.active) {
      return CurrentCalculationResult.notCalculated(
        reason: '${circuit.status.name.toUpperCase()} circuits have no load.',
      );
    }
    if (electricalSystem.phaseSystem == PanelPhaseSystem.singlePhase &&
        circuit.phaseConfiguration == CircuitPhaseConfiguration.threePhase) {
      return CurrentCalculationResult.invalid(
        reason: 'A single-phase panel cannot supply a three-phase circuit.',
      );
    }

    final load = circuit.loadInput;
    if (load == null) {
      return CurrentCalculationResult.insufficient(
        reason: 'ACTIVE circuit is missing LoadInput.',
      );
    }

    final isSinglePhase =
        circuit.phaseConfiguration == CircuitPhaseConfiguration.singlePhase;
    final voltageBasis = isSinglePhase
        ? VoltageBasis.lineToNeutral
        : VoltageBasis.lineToLine;
    final voltageUsedV = isSinglePhase
        ? electricalSystem.lineToNeutralVoltageV
        : electricalSystem.lineToLineVoltageV;
    final phaseDivisor = isSinglePhase
        ? voltageUsedV
        : math.sqrt(3) * voltageUsedV;
    final references = [
      CalculationSourceReference(
        sourceId: 'load-schedule-current-formula-v1',
        label: 'LOAD-SCHEDULE-V1 CP2 approved current formula',
        rowId: '${load.kind.name}:${circuit.phaseConfiguration.name}',
        sourceVersion: 'cp2-v1',
      ),
    ];

    return switch (load.kind) {
      LoadInputKind.directVa => CurrentCalculationResult.calculated(
        designCurrentA: load.apparentPowerVa! / phaseDivisor,
        apparentPowerVa: load.apparentPowerVa!,
        voltageBasis: voltageBasis,
        voltageUsedV: voltageUsedV,
        formulaId: isSinglePhase
            ? CurrentFormulaId.directVaSinglePhase
            : CurrentFormulaId.directVaThreePhase,
        sourceReferences: references,
      ),
      LoadInputKind.quantityTimesWatts => _calculateQuantityWatts(
        load: load,
        isSinglePhase: isSinglePhase,
        voltageBasis: voltageBasis,
        voltageUsedV: voltageUsedV,
        phaseDivisor: phaseDivisor,
        references: references,
      ),
      LoadInputKind.directCurrentA => CurrentCalculationResult.calculated(
        designCurrentA: load.currentA!,
        apparentPowerVa: load.currentA! * phaseDivisor,
        voltageBasis: voltageBasis,
        voltageUsedV: voltageUsedV,
        formulaId: isSinglePhase
            ? CurrentFormulaId.directCurrentSinglePhase
            : CurrentFormulaId.directCurrentThreePhase,
        sourceReferences: references,
      ),
    };
  }

  CurrentCalculationResult _calculateQuantityWatts({
    required LoadInput load,
    required bool isSinglePhase,
    required VoltageBasis voltageBasis,
    required double voltageUsedV,
    required double phaseDivisor,
    required List<CalculationSourceReference> references,
  }) {
    final realPowerW = load.quantity! * load.wattsPerUnit!;
    final apparentPowerVa = realPowerW / load.powerFactor!;
    return CurrentCalculationResult.calculated(
      designCurrentA: apparentPowerVa / phaseDivisor,
      apparentPowerVa: apparentPowerVa,
      realPowerW: realPowerW,
      powerFactorUsed: load.powerFactor,
      voltageBasis: voltageBasis,
      voltageUsedV: voltageUsedV,
      formulaId: isSinglePhase
          ? CurrentFormulaId.quantityWattsPfSinglePhase
          : CurrentFormulaId.quantityWattsPfThreePhase,
      sourceReferences: references,
    );
  }
}
