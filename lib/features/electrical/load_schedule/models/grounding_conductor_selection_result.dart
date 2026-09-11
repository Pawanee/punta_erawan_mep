import '../enums/grounding_conductor_selection_status.dart';
import '../enums/protective_device_current_basis.dart';
import '../repositories/table_4_2_grounding_repository.dart';
import 'calculation_source_reference.dart';

class GroundingConductorSelectionResult {
  GroundingConductorSelectionResult._({
    required this.status,
    this.reason,
    this.basis,
    this.ratedCurrentA,
    this.adjustableTripSettingA,
    this.protectiveDeviceValueA,
    this.selectedTableThresholdA,
    this.groundingConductorSizeSqmm,
    this.phaseConductorSizeSqmm,
    this.tableId,
    this.tableVersion,
    List<CalculationSourceReference> sourceReferences = const [],
  }) : sourceReferences = List.unmodifiable(sourceReferences) {
    _validate();
  }

  factory GroundingConductorSelectionResult.selected({
    required ProtectiveDeviceCurrentBasis basis,
    required double ratedCurrentA,
    required double protectiveDeviceValueA,
    required double selectedTableThresholdA,
    required double groundingConductorSizeSqmm,
    required List<CalculationSourceReference> sourceReferences,
    double? adjustableTripSettingA,
    double? phaseConductorSizeSqmm,
  }) => GroundingConductorSelectionResult._(
    status: GroundingConductorSelectionStatus.selected,
    basis: basis,
    ratedCurrentA: ratedCurrentA,
    adjustableTripSettingA: adjustableTripSettingA,
    protectiveDeviceValueA: protectiveDeviceValueA,
    selectedTableThresholdA: selectedTableThresholdA,
    groundingConductorSizeSqmm: groundingConductorSizeSqmm,
    phaseConductorSizeSqmm: phaseConductorSizeSqmm,
    tableId: Table42GroundingRepository.tableId,
    tableVersion: Table42GroundingRepository.version,
    sourceReferences: sourceReferences,
  );

  factory GroundingConductorSelectionResult.notCalculated({String? reason}) =>
      GroundingConductorSelectionResult._(
        status: GroundingConductorSelectionStatus.notCalculated,
        reason: reason,
      );

  factory GroundingConductorSelectionResult.insufficient({
    required String reason,
  }) => GroundingConductorSelectionResult._(
    status: GroundingConductorSelectionStatus.insufficient,
    reason: reason,
  );

  factory GroundingConductorSelectionResult.invalid({required String reason}) =>
      GroundingConductorSelectionResult._(
        status: GroundingConductorSelectionStatus.invalid,
        reason: reason,
      );

  factory GroundingConductorSelectionResult.unsupported({
    required String reason,
  }) => GroundingConductorSelectionResult._(
    status: GroundingConductorSelectionStatus.unsupported,
    reason: reason,
  );

  final GroundingConductorSelectionStatus status;
  final String? reason;
  final ProtectiveDeviceCurrentBasis? basis;
  final double? ratedCurrentA;
  final double? adjustableTripSettingA;
  final double? protectiveDeviceValueA;
  final double? selectedTableThresholdA;
  final double? groundingConductorSizeSqmm;
  final double? phaseConductorSizeSqmm;
  final String? tableId;
  final String? tableVersion;
  final List<CalculationSourceReference> sourceReferences;

  void _validate() {
    final isSelected = status == GroundingConductorSelectionStatus.selected;
    final values = [
      ?ratedCurrentA,
      ?adjustableTripSettingA,
      ?protectiveDeviceValueA,
      ?selectedTableThresholdA,
      ?groundingConductorSizeSqmm,
      ?phaseConductorSizeSqmm,
    ];
    if (values.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError('Grounding values must be finite and positive.');
    }
    final hasEngineeringValues =
        basis != null ||
        values.isNotEmpty ||
        tableId != null ||
        tableVersion != null;
    if (!isSelected) {
      if (hasEngineeringValues || sourceReferences.isNotEmpty) {
        throw ArgumentError(
          'Unresolved grounding result cannot contain engineering values.',
        );
      }
      if (status != GroundingConductorSelectionStatus.notCalculated &&
          (reason == null || reason!.trim().isEmpty)) {
        throw ArgumentError('Fail-closed grounding result requires a reason.');
      }
      return;
    }
    if (reason != null ||
        basis == null ||
        ratedCurrentA == null ||
        protectiveDeviceValueA == null ||
        selectedTableThresholdA == null ||
        groundingConductorSizeSqmm == null ||
        tableId != Table42GroundingRepository.tableId ||
        tableVersion != Table42GroundingRepository.version ||
        sourceReferences.isEmpty) {
      throw ArgumentError(
        'Selected grounding result requires a complete payload.',
      );
    }
    if (basis == ProtectiveDeviceCurrentBasis.ratedCurrent) {
      if (adjustableTripSettingA != null ||
          !_close(protectiveDeviceValueA!, ratedCurrentA!)) {
        throw ArgumentError(
          'Rated-current grounding payload is contradictory.',
        );
      }
    } else {
      if (adjustableTripSettingA == null ||
          adjustableTripSettingA! > ratedCurrentA! ||
          !_close(protectiveDeviceValueA!, adjustableTripSettingA!)) {
        throw ArgumentError(
          'Adjustable-trip grounding payload is contradictory.',
        );
      }
    }
    if (protectiveDeviceValueA! >
        Table42GroundingRepository.rows.last.protectiveDeviceThresholdA) {
      throw ArgumentError('Selected grounding value exceeds Table 4-2.');
    }
    final matchingRows = Table42GroundingRepository.rows.where(
      (row) => _close(row.protectiveDeviceThresholdA, selectedTableThresholdA!),
    );
    if (matchingRows.length != 1 ||
        !_close(
          matchingRows.single.minimumGroundingConductorSizeSqmm,
          groundingConductorSizeSqmm!,
        ) ||
        protectiveDeviceValueA! > selectedTableThresholdA!) {
      throw ArgumentError('Selected grounding row does not match Table 4-2.');
    }
    final firstApplicable = Table42GroundingRepository.rows.firstWhere(
      (row) => row.protectiveDeviceThresholdA >= protectiveDeviceValueA!,
    );
    if (!_close(
      firstApplicable.protectiveDeviceThresholdA,
      selectedTableThresholdA!,
    )) {
      throw ArgumentError(
        'Grounding result must use the first applicable ceiling row.',
      );
    }
    if (!sourceReferences.any(
      (reference) =>
          reference.tableId == tableId &&
          reference.rowId == firstApplicable.rowId &&
          reference.sourceVersion == tableVersion,
    )) {
      throw ArgumentError(
        'Grounding result requires Table 4-2 row traceability.',
      );
    }
  }

  static bool _close(double left, double right) {
    final scale = left.abs() > right.abs() ? left.abs() : right.abs();
    return (left - right).abs() <= 1e-9 * (scale < 1 ? 1 : scale);
  }

  Map<String, Object?> toJson() => {
    'status': status.name,
    if (reason != null) 'reason': reason,
    if (basis != null) 'basis': basis!.name,
    if (ratedCurrentA != null) 'ratedCurrentA': ratedCurrentA,
    if (adjustableTripSettingA != null)
      'adjustableTripSettingA': adjustableTripSettingA,
    if (protectiveDeviceValueA != null)
      'protectiveDeviceValueA': protectiveDeviceValueA,
    if (selectedTableThresholdA != null)
      'selectedTableThresholdA': selectedTableThresholdA,
    if (groundingConductorSizeSqmm != null)
      'groundingConductorSizeSqmm': groundingConductorSizeSqmm,
    if (phaseConductorSizeSqmm != null)
      'phaseConductorSizeSqmm': phaseConductorSizeSqmm,
    if (tableId != null) 'tableId': tableId,
    if (tableVersion != null) 'tableVersion': tableVersion,
    'sourceReferences': sourceReferences.map((item) => item.toJson()).toList(),
  };

  factory GroundingConductorSelectionResult.fromJson(
    Map<String, Object?> json,
  ) {
    final status = GroundingConductorSelectionStatus.values.byName(
      json['status'] as String,
    );
    if (status != GroundingConductorSelectionStatus.selected) {
      final hasEngineeringValues = json.keys.any(
        (key) =>
            key != 'status' && key != 'reason' && key != 'sourceReferences',
      );
      if (hasEngineeringValues ||
          (json['sourceReferences'] as List).isNotEmpty) {
        throw ArgumentError(
          'Unresolved grounding JSON cannot contain engineering values.',
        );
      }
      final reason = json['reason'] as String?;
      return switch (status) {
        GroundingConductorSelectionStatus.notCalculated =>
          GroundingConductorSelectionResult.notCalculated(reason: reason),
        GroundingConductorSelectionStatus.insufficient =>
          GroundingConductorSelectionResult.insufficient(reason: reason!),
        GroundingConductorSelectionStatus.invalid =>
          GroundingConductorSelectionResult.invalid(reason: reason!),
        GroundingConductorSelectionStatus.unsupported =>
          GroundingConductorSelectionResult.unsupported(reason: reason!),
        GroundingConductorSelectionStatus.selected => throw StateError(
          'unreachable',
        ),
      };
    }
    if (json['tableId'] != Table42GroundingRepository.tableId ||
        json['tableVersion'] != Table42GroundingRepository.version ||
        json['reason'] != null) {
      throw ArgumentError(
        'Selected grounding JSON has invalid metadata or a reason.',
      );
    }
    return GroundingConductorSelectionResult.selected(
      basis: ProtectiveDeviceCurrentBasis.values.byName(
        json['basis'] as String,
      ),
      ratedCurrentA: (json['ratedCurrentA'] as num).toDouble(),
      adjustableTripSettingA: (json['adjustableTripSettingA'] as num?)
          ?.toDouble(),
      protectiveDeviceValueA: (json['protectiveDeviceValueA'] as num)
          .toDouble(),
      selectedTableThresholdA: (json['selectedTableThresholdA'] as num)
          .toDouble(),
      groundingConductorSizeSqmm: (json['groundingConductorSizeSqmm'] as num)
          .toDouble(),
      phaseConductorSizeSqmm: (json['phaseConductorSizeSqmm'] as num?)
          ?.toDouble(),
      sourceReferences: (json['sourceReferences'] as List)
          .map(
            (item) => CalculationSourceReference.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
