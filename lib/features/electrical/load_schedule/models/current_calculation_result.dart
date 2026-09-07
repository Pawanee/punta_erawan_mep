import 'dart:math' as math;

import '../enums/calculation_status.dart';
import '../enums/current_formula_id.dart';
import '../enums/voltage_basis.dart';
import 'calculation_source_reference.dart';

class CurrentCalculationResult {
  static const double formulaRelativeTolerance = 1e-9;

  CurrentCalculationResult._({
    required this.status,
    this.reason,
    this.designCurrentA,
    this.apparentPowerVa,
    this.realPowerW,
    this.powerFactorUsed,
    this.voltageBasis,
    this.voltageUsedV,
    this.formulaId,
    List<CalculationSourceReference> sourceReferences = const [],
  }) : sourceReferences = List.unmodifiable(sourceReferences) {
    _validate();
  }

  factory CurrentCalculationResult.calculated({
    required double designCurrentA,
    required double apparentPowerVa,
    required VoltageBasis voltageBasis,
    required double voltageUsedV,
    required CurrentFormulaId formulaId,
    double? realPowerW,
    double? powerFactorUsed,
    List<CalculationSourceReference> sourceReferences = const [],
  }) => CurrentCalculationResult._(
    status: CalculationStatus.calculated,
    designCurrentA: designCurrentA,
    apparentPowerVa: apparentPowerVa,
    realPowerW: realPowerW,
    powerFactorUsed: powerFactorUsed,
    voltageBasis: voltageBasis,
    voltageUsedV: voltageUsedV,
    formulaId: formulaId,
    sourceReferences: sourceReferences,
  );

  factory CurrentCalculationResult.notCalculated({
    String? reason,
    List<CalculationSourceReference> sourceReferences = const [],
  }) => CurrentCalculationResult._(
    status: CalculationStatus.notCalculated,
    reason: reason,
    sourceReferences: sourceReferences,
  );

  factory CurrentCalculationResult.insufficient({
    required String reason,
    List<CalculationSourceReference> sourceReferences = const [],
  }) => CurrentCalculationResult._(
    status: CalculationStatus.insufficient,
    reason: reason,
    sourceReferences: sourceReferences,
  );

  factory CurrentCalculationResult.invalid({
    required String reason,
    List<CalculationSourceReference> sourceReferences = const [],
  }) => CurrentCalculationResult._(
    status: CalculationStatus.invalid,
    reason: reason,
    sourceReferences: sourceReferences,
  );

  final CalculationStatus status;
  final String? reason;
  final double? designCurrentA;
  final double? apparentPowerVa;
  final double? realPowerW;
  final double? powerFactorUsed;
  final VoltageBasis? voltageBasis;
  final double? voltageUsedV;
  final CurrentFormulaId? formulaId;
  final List<CalculationSourceReference> sourceReferences;

  void _validate() {
    final numericValues = [
      ?designCurrentA,
      ?apparentPowerVa,
      ?realPowerW,
      ?powerFactorUsed,
      ?voltageUsedV,
    ];
    if (numericValues.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError('Current result values must be finite and positive.');
    }
    if (powerFactorUsed != null && powerFactorUsed! > 1) {
      throw ArgumentError.value(powerFactorUsed, 'powerFactorUsed');
    }

    final hasRequiredCalculatedValues =
        designCurrentA != null &&
        apparentPowerVa != null &&
        voltageBasis != null &&
        voltageUsedV != null &&
        formulaId != null;
    final hasAnyCalculatedValue =
        numericValues.isNotEmpty || voltageBasis != null || formulaId != null;
    if (status == CalculationStatus.calculated) {
      if (!hasRequiredCalculatedValues || reason != null) {
        throw ArgumentError(
          'Calculated current requires a complete typed payload and no reason.',
        );
      }
      final isQuantityFormula =
          formulaId == CurrentFormulaId.quantityWattsPfSinglePhase ||
          formulaId == CurrentFormulaId.quantityWattsPfThreePhase;
      final hasIncompleteQuantityPayload =
          realPowerW == null || powerFactorUsed == null;
      final hasUnexpectedQuantityPayload =
          realPowerW != null || powerFactorUsed != null;
      if ((isQuantityFormula && hasIncompleteQuantityPayload) ||
          (!isQuantityFormula && hasUnexpectedQuantityPayload)) {
        throw ArgumentError(
          'Real power and power factor are allowed only for quantity × watts.',
        );
      }
      final singlePhaseFormula = switch (formulaId!) {
        CurrentFormulaId.directVaSinglePhase ||
        CurrentFormulaId.quantityWattsPfSinglePhase ||
        CurrentFormulaId.directCurrentSinglePhase => true,
        CurrentFormulaId.directVaThreePhase ||
        CurrentFormulaId.quantityWattsPfThreePhase ||
        CurrentFormulaId.directCurrentThreePhase => false,
      };
      if (singlePhaseFormula != (voltageBasis == VoltageBasis.lineToNeutral)) {
        throw ArgumentError('Formula and voltage basis are inconsistent.');
      }
      if (sourceReferences.isEmpty) {
        throw ArgumentError(
          'Calculated current requires at least one source reference.',
        );
      }
      _validateFormulaRelationship();
      return;
    }
    if (hasAnyCalculatedValue) {
      throw ArgumentError(
        'An unresolved current result cannot contain values.',
      );
    }
    if ((status == CalculationStatus.insufficient ||
            status == CalculationStatus.invalid) &&
        (reason == null || reason!.trim().isEmpty)) {
      throw ArgumentError('Fail-closed current results require a reason.');
    }
  }

  void _validateFormulaRelationship() {
    final phaseMultiplier = voltageBasis == VoltageBasis.lineToNeutral
        ? 1.0
        : math.sqrt(3);
    final voltageDivisor = phaseMultiplier * voltageUsedV!;
    switch (formulaId!) {
      case CurrentFormulaId.directVaSinglePhase:
      case CurrentFormulaId.directVaThreePhase:
        _requireClose(
          actual: designCurrentA!,
          expected: apparentPowerVa! / voltageDivisor,
          relationship: 'I = S / voltage divisor',
        );
      case CurrentFormulaId.quantityWattsPfSinglePhase:
      case CurrentFormulaId.quantityWattsPfThreePhase:
        _requireClose(
          actual: apparentPowerVa!,
          expected: realPowerW! / powerFactorUsed!,
          relationship: 'S = P / PF',
        );
        _requireClose(
          actual: designCurrentA!,
          expected: apparentPowerVa! / voltageDivisor,
          relationship: 'I = S / voltage divisor',
        );
      case CurrentFormulaId.directCurrentSinglePhase:
      case CurrentFormulaId.directCurrentThreePhase:
        _requireClose(
          actual: apparentPowerVa!,
          expected: designCurrentA! * voltageDivisor,
          relationship: 'S = I × voltage divisor',
        );
    }
  }

  void _requireClose({
    required double actual,
    required double expected,
    required String relationship,
  }) {
    if (!expected.isFinite || expected <= 0) {
      throw ArgumentError(
        'Expected value for $relationship must be finite and positive.',
      );
    }
    final scale = math.max(1.0, math.max(actual.abs(), expected.abs()));
    if ((actual - expected).abs() > formulaRelativeTolerance * scale) {
      throw ArgumentError(
        'Calculated current violates $relationship within relative tolerance '
        '$formulaRelativeTolerance.',
      );
    }
  }

  Map<String, Object?> toJson() => {
    'status': status.name,
    if (reason != null) 'reason': reason,
    if (designCurrentA != null) 'designCurrentA': designCurrentA,
    if (apparentPowerVa != null) 'apparentPowerVa': apparentPowerVa,
    if (realPowerW != null) 'realPowerW': realPowerW,
    if (powerFactorUsed != null) 'powerFactorUsed': powerFactorUsed,
    if (voltageBasis != null) 'voltageBasis': voltageBasis!.name,
    if (voltageUsedV != null) 'voltageUsedV': voltageUsedV,
    if (formulaId != null) 'formulaId': formulaId!.name,
    'sourceReferences': sourceReferences
        .map((reference) => reference.toJson())
        .toList(),
  };

  factory CurrentCalculationResult.fromJson(Map<String, Object?> json) {
    final status = CalculationStatus.values.byName(json['status'] as String);
    const engineeringKeys = [
      'designCurrentA',
      'apparentPowerVa',
      'realPowerW',
      'powerFactorUsed',
      'voltageBasis',
      'voltageUsedV',
      'formulaId',
    ];
    final hasEngineeringPayload = engineeringKeys.any(
      (key) => json[key] != null,
    );
    if (status != CalculationStatus.calculated && hasEngineeringPayload) {
      throw ArgumentError(
        'Unresolved current JSON cannot contain engineering values.',
      );
    }
    if (status == CalculationStatus.calculated && json['reason'] != null) {
      throw ArgumentError('Calculated current JSON cannot contain a reason.');
    }
    final references = (json['sourceReferences'] as List)
        .map(
          (item) => CalculationSourceReference.fromJson(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList();
    return switch (status) {
      CalculationStatus.calculated => CurrentCalculationResult.calculated(
        designCurrentA: (json['designCurrentA'] as num).toDouble(),
        apparentPowerVa: (json['apparentPowerVa'] as num).toDouble(),
        realPowerW: (json['realPowerW'] as num?)?.toDouble(),
        powerFactorUsed: (json['powerFactorUsed'] as num?)?.toDouble(),
        voltageBasis: VoltageBasis.values.byName(
          json['voltageBasis'] as String,
        ),
        voltageUsedV: (json['voltageUsedV'] as num).toDouble(),
        formulaId: CurrentFormulaId.values.byName(json['formulaId'] as String),
        sourceReferences: references,
      ),
      CalculationStatus.notCalculated => CurrentCalculationResult.notCalculated(
        reason: json['reason'] as String?,
        sourceReferences: references,
      ),
      CalculationStatus.insufficient => CurrentCalculationResult.insufficient(
        reason: json['reason'] as String,
        sourceReferences: references,
      ),
      CalculationStatus.invalid => CurrentCalculationResult.invalid(
        reason: json['reason'] as String,
        sourceReferences: references,
      ),
    };
  }
}
