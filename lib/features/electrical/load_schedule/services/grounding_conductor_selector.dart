import '../enums/circuit_breaker_selection_status.dart';
import '../enums/circuit_status.dart';
import '../models/calculation_source_reference.dart';
import '../models/circuit_breaker_selection_result.dart';
import '../models/grounding_conductor_selection_input.dart';
import '../models/grounding_conductor_selection_result.dart';
import '../repositories/table_4_2_grounding_repository.dart';

class GroundingConductorSelector {
  const GroundingConductorSelector()
    : _repository = const Table42GroundingRepository();

  final Table42GroundingRepository _repository;

  GroundingConductorSelectionResult select({
    required CircuitStatus circuitStatus,
    required CircuitBreakerSelectionResult circuitBreaker,
    GroundingConductorSelectionInput? input,
  }) {
    if (circuitStatus != CircuitStatus.active) {
      return GroundingConductorSelectionResult.notCalculated(
        reason: 'SPARE and SPACE circuits do not select a grounding conductor.',
      );
    }
    if (input == null) {
      return GroundingConductorSelectionResult.insufficient(
        reason: 'ACTIVE grounding selection requires explicit device input.',
      );
    }
    final value = input.protectiveDeviceValueA;
    final row = _repository.selectCeiling(value);
    if (row == null) {
      return GroundingConductorSelectionResult.unsupported(
        reason: 'Protective-device value exceeds the 6000 A Table 4-2 limit.',
      );
    }
    if (circuitBreaker.status != CircuitBreakerSelectionStatus.selected ||
        circuitBreaker.ratedCurrentA == null) {
      return GroundingConductorSelectionResult.insufficient(
        reason: 'ACTIVE grounding selection requires a selected breaker.',
      );
    }
    if (!_close(input.ratedCurrentA, circuitBreaker.ratedCurrentA!)) {
      return GroundingConductorSelectionResult.invalid(
        reason:
            'Grounding input rated current does not match breaker snapshot.',
      );
    }
    return GroundingConductorSelectionResult.selected(
      basis: input.basis,
      ratedCurrentA: input.ratedCurrentA,
      adjustableTripSettingA: input.adjustableTripSettingA,
      protectiveDeviceValueA: value,
      selectedTableThresholdA: row.protectiveDeviceThresholdA,
      groundingConductorSizeSqmm: row.minimumGroundingConductorSizeSqmm,
      phaseConductorSizeSqmm: input.phaseConductorSizeSqmm,
      sourceReferences: [
        CalculationSourceReference(
          sourceId: 'table-4-2-page-113',
          label:
              '${Table42GroundingRepository.documentTitle} - '
              '${Table42GroundingRepository.title}',
          tableId: Table42GroundingRepository.tableId,
          rowId: row.rowId,
          sourceVersion: Table42GroundingRepository.version,
        ),
      ],
    );
  }

  static bool _close(double left, double right) {
    final scale = left.abs() > right.abs() ? left.abs() : right.abs();
    return (left - right).abs() <= 1e-9 * (scale < 1 ? 1 : scale);
  }
}
