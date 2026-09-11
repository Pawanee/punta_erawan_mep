import '../../cable_design/enums/core_type.dart';
import '../../voltage_drop/enums/cable_arrangement.dart';
import '../../voltage_drop/enums/voltage_drop_core_type.dart';
import '../../voltage_drop/enums/voltage_phase.dart';
import '../../voltage_drop/models/voltage_drop_request.dart';
import '../../voltage_drop/repositories/voltage_drop_repository.dart';
import '../../voltage_drop/services/voltage_drop_calculation_service.dart';
import '../enums/cable_selection_status.dart';
import '../enums/calculation_status.dart';
import '../enums/circuit_phase_configuration.dart';
import '../enums/circuit_status.dart';
import '../enums/voltage_basis.dart';
import '../enums/panel_phase_system.dart';
import '../models/calculation_source_reference.dart';
import '../models/circuit_calculation_result.dart';
import '../models/circuit_definition.dart';
import '../models/panel_electrical_system.dart';
import '../models/voltage_drop_calculation_input.dart';
import '../models/voltage_drop_calculation_result.dart';

class LoadScheduleVoltageDropCalculator {
  LoadScheduleVoltageDropCalculator({
    VoltageDropRepository? repository,
    VoltageDropCalculationService? calculationService,
  }) : _repository = repository ?? const VoltageDropRepository(),
       _calculationService =
           calculationService ?? const VoltageDropCalculationService();

  final VoltageDropRepository _repository;
  final VoltageDropCalculationService _calculationService;

  Future<VoltageDropCalculationResult> calculate({
    required CircuitDefinition circuit,
    required CircuitCalculationResult calculation,
    required PanelElectricalSystem electricalSystem,
    required VoltageDropCalculationInput input,
  }) async {
    if (circuit.status != CircuitStatus.active) {
      return VoltageDropCalculationResult.notCalculated(
        reason: 'SPARE and SPACE circuits have no load cable voltage drop.',
      );
    }
    if (calculation.circuitStatus != circuit.status ||
        calculation.circuitNo != circuit.circuitNo ||
        calculation.phaseConfiguration != circuit.phaseConfiguration) {
      return VoltageDropCalculationResult.invalid(
        reason: 'Circuit definition and calculation result do not match.',
      );
    }
    if (calculation.current.status != CalculationStatus.calculated ||
        calculation.cable.status != CableSelectionStatus.coordinated) {
      return VoltageDropCalculationResult.insufficient(
        reason:
            'ACTIVE voltage drop requires calculated current and coordinated cable.',
      );
    }
    if (circuit.phaseConfiguration == CircuitPhaseConfiguration.threePhase &&
        electricalSystem.phaseSystem == PanelPhaseSystem.singlePhase) {
      return VoltageDropCalculationResult.invalid(
        reason: 'A single-phase panel cannot supply a three-phase circuit.',
      );
    }

    final cable = calculation.cable;
    final ib = calculation.current.designCurrentA!;
    if (!_finitePositive(ib) || !_close(cable.designCurrentIbA!, ib)) {
      return VoltageDropCalculationResult.invalid(
        reason: 'Cable design current does not match calculated Ib.',
      );
    }
    final runs = cable.runs!;
    final currentPerRun = ib / runs;
    final voltageBasis =
        circuit.phaseConfiguration == CircuitPhaseConfiguration.singlePhase
        ? VoltageBasis.lineToNeutral
        : VoltageBasis.lineToLine;
    final phase =
        circuit.phaseConfiguration == CircuitPhaseConfiguration.singlePhase
        ? VoltagePhase.singlePhase
        : VoltagePhase.threePhase;
    final voltage = voltageBasis == VoltageBasis.lineToNeutral
        ? electricalSystem.lineToNeutralVoltageV
        : electricalSystem.lineToLineVoltageV;
    final coreType = cable.coreType == CoreType.singleCore
        ? VoltageDropCoreType.singleCore
        : VoltageDropCoreType.multiCore;
    if (!_finitePositive(currentPerRun) || !_finitePositive(voltage)) {
      return VoltageDropCalculationResult.invalid(
        reason: 'Voltage-drop current or voltage is not finite and positive.',
      );
    }
    if (input.installationGroup.name !=
        'group${cable.installationGroupNumber}') {
      return VoltageDropCalculationResult.invalid(
        reason: 'Voltage-drop installation group does not match the CP4 cable.',
      );
    }
    if (coreType == VoltageDropCoreType.multiCore &&
        input.arrangement != null) {
      return VoltageDropCalculationResult.invalid(
        reason: 'Multi-core voltage-drop tables do not use arrangement.',
      );
    }
    if (coreType == VoltageDropCoreType.singleCore &&
        input.installationGroup.isGroup1_2_5 != (input.arrangement == null)) {
      return VoltageDropCalculationResult.insufficient(
        reason:
            'Single-core voltage-drop table requires the applicable arrangement context.',
      );
    }

    final rows = await _repository.loadTable(
      insulation: cable.insulation!,
      coreType: coreType,
    );
    final legacy = _calculationService.calculate(
      request: VoltageDropRequest(
        insulation: cable.insulation!,
        coreType: coreType,
        phase: phase,
        sizeSqmm: cable.sizeSqmm!,
        currentA: currentPerRun,
        lengthM: input.lengthOneWayM,
        systemVoltage: voltage,
        allowableVoltageDropPercent: input.allowableVoltageDropPercent,
        installationGroup: input.installationGroup,
        arrangement: input.arrangement,
      ),
      rows: rows,
    );
    if (!legacy.isSuccess) {
      return VoltageDropCalculationResult.insufficient(reason: legacy.message);
    }
    final numeric = [
      legacy.mvPerAperM!,
      legacy.voltageDropV!,
      legacy.voltageDropPercent!,
    ];
    if (numeric.any((value) => !_finitePositive(value))) {
      return VoltageDropCalculationResult.invalid(
        reason:
            'Voltage-drop calculation overflowed or produced a non-finite value.',
      );
    }

    final tableId = legacy.table!;
    final rowId = 'sizeSqmm:${cable.sizeSqmm}';
    final columnId = _columnId(
      phase: phase,
      coreType: coreType,
      arrangement: input.arrangement,
      groupedColumn: input.installationGroup.isGroup1_2_5,
    );
    return VoltageDropCalculationResult.calculated(
      identity: cable.identity!,
      insulation: cable.insulation!,
      coreType: coreType,
      phase: phase,
      sizeSqmm: cable.sizeSqmm!,
      runs: runs,
      designCurrentIbA: ib,
      currentPerRunA: currentPerRun,
      lengthOneWayM: input.lengthOneWayM,
      voltageBasis: voltageBasis,
      voltageUsedV: voltage,
      allowableVoltageDropPercent: input.allowableVoltageDropPercent,
      installationGroup: input.installationGroup,
      arrangement: input.arrangement,
      tableId: tableId,
      rowId: rowId,
      columnId: columnId,
      mvPerAperM: legacy.mvPerAperM!,
      voltageDropV: legacy.voltageDropV!,
      voltageDropPercent: legacy.voltageDropPercent!,
      isWithinLimit: legacy.isWithinLimit!,
      sourceReferences: [
        CalculationSourceReference(
          sourceId: 'voltage-drop-table-$tableId',
          label: 'Voltage drop Table $tableId',
          tableId: tableId,
          rowId: rowId,
          columnId: columnId,
          sourceVersion: 'voltage-drop-tables-v1',
        ),
      ],
    );
  }

  static bool _finitePositive(double value) => value.isFinite && value > 0;

  static bool _close(double left, double right) {
    final scale = left.abs() > right.abs() ? left.abs() : right.abs();
    return (left - right).abs() <= 1e-9 * (scale < 1 ? 1 : scale);
  }

  static String _columnId({
    required VoltagePhase phase,
    required VoltageDropCoreType coreType,
    required bool groupedColumn,
    required CableArrangement? arrangement,
  }) {
    final phaseId = phase == VoltagePhase.singlePhase
        ? 'singlePhase'
        : 'threePhase';
    if (coreType == VoltageDropCoreType.multiCore) return '${phaseId}All';
    if (groupedColumn) return '${phaseId}Group1_2_5';
    return '$phaseId${_capitalized(arrangement!.name)}';
  }

  static String _capitalized(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}
