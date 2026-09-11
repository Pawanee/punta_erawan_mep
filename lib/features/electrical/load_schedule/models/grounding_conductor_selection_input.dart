import '../enums/protective_device_current_basis.dart';

class GroundingConductorSelectionInput {
  GroundingConductorSelectionInput({
    required this.basis,
    required this.ratedCurrentA,
    this.adjustableTripSettingA,
    this.phaseConductorSizeSqmm,
  }) {
    _requirePositive(ratedCurrentA, 'ratedCurrentA');
    if (phaseConductorSizeSqmm != null) {
      _requirePositive(phaseConductorSizeSqmm!, 'phaseConductorSizeSqmm');
    }
    if (basis == ProtectiveDeviceCurrentBasis.ratedCurrent) {
      if (adjustableTripSettingA != null) {
        throw ArgumentError(
          'Rated-current basis cannot contain an adjustable trip setting.',
        );
      }
    } else {
      final setting = adjustableTripSettingA;
      if (setting == null) {
        throw ArgumentError(
          'Adjustable-trip basis requires the actual trip setting.',
        );
      }
      _requirePositive(setting, 'adjustableTripSettingA');
      if (setting > ratedCurrentA) {
        throw ArgumentError(
          'Adjustable trip setting cannot exceed breaker rated current.',
        );
      }
    }
  }

  final ProtectiveDeviceCurrentBasis basis;
  final double ratedCurrentA;
  final double? adjustableTripSettingA;
  final double? phaseConductorSizeSqmm;

  double get protectiveDeviceValueA =>
      basis == ProtectiveDeviceCurrentBasis.ratedCurrent
      ? ratedCurrentA
      : adjustableTripSettingA!;

  static void _requirePositive(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, name, 'Must be finite and positive.');
    }
  }

  Map<String, Object?> toJson() => {
    'basis': basis.name,
    'ratedCurrentA': ratedCurrentA,
    if (adjustableTripSettingA != null)
      'adjustableTripSettingA': adjustableTripSettingA,
    if (phaseConductorSizeSqmm != null)
      'phaseConductorSizeSqmm': phaseConductorSizeSqmm,
  };

  factory GroundingConductorSelectionInput.fromJson(
    Map<String, Object?> json,
  ) => GroundingConductorSelectionInput(
    basis: ProtectiveDeviceCurrentBasis.values.byName(json['basis'] as String),
    ratedCurrentA: (json['ratedCurrentA'] as num).toDouble(),
    adjustableTripSettingA: (json['adjustableTripSettingA'] as num?)
        ?.toDouble(),
    phaseConductorSizeSqmm: (json['phaseConductorSizeSqmm'] as num?)
        ?.toDouble(),
  );
}
