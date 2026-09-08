import '../enums/breaker_pole_configuration.dart';
import '../enums/breaker_selection_mode.dart';
import '../enums/breaker_type.dart';
import '../enums/circuit_breaker_selection_status.dart';
import 'calculation_source_reference.dart';
import 'circuit_breaker_catalog.dart';

class CircuitBreakerSelectionResult {
  CircuitBreakerSelectionResult._({
    required this.status,
    this.reason,
    this.breakerType,
    this.ratedCurrentA,
    this.poleConfiguration,
    this.selectionMode,
    this.designCurrentIbA,
    this.currentMarginA,
    this.breakingCapacityKa,
    this.tripCurveDesignation,
    this.manualOverrideReason,
    List<CalculationSourceReference> sourceReferences = const [],
    this.catalogVersion,
    this.cableCoordinationStatus,
  }) : sourceReferences = List.unmodifiable(sourceReferences) {
    _validate();
  }

  factory CircuitBreakerSelectionResult.selected({
    required BreakerType breakerType,
    required double ratedCurrentA,
    required BreakerPoleConfiguration poleConfiguration,
    required BreakerSelectionMode selectionMode,
    required List<CalculationSourceReference> sourceReferences,
    required String catalogVersion,
    double? designCurrentIbA,
    double? currentMarginA,
    double? breakingCapacityKa,
    String? tripCurveDesignation,
    String? manualOverrideReason,
    bool cableCoordinated = false,
  }) => CircuitBreakerSelectionResult._(
    status: CircuitBreakerSelectionStatus.selected,
    breakerType: breakerType,
    ratedCurrentA: ratedCurrentA,
    poleConfiguration: poleConfiguration,
    selectionMode: selectionMode,
    designCurrentIbA: designCurrentIbA,
    currentMarginA: currentMarginA,
    breakingCapacityKa: breakingCapacityKa,
    tripCurveDesignation: tripCurveDesignation,
    manualOverrideReason: manualOverrideReason,
    sourceReferences: sourceReferences,
    catalogVersion: catalogVersion,
    cableCoordinationStatus: designCurrentIbA == null
        ? null
        : cableCoordinated
        ? CableCoordinationStatus.coordinated
        : CableCoordinationStatus.pendingCableSelection,
  );

  factory CircuitBreakerSelectionResult.notCalculated({String? reason}) =>
      CircuitBreakerSelectionResult._(
        status: CircuitBreakerSelectionStatus.notCalculated,
        reason: reason,
      );

  factory CircuitBreakerSelectionResult.insufficient({
    required String reason,
  }) => CircuitBreakerSelectionResult._(
    status: CircuitBreakerSelectionStatus.insufficient,
    reason: reason,
  );

  factory CircuitBreakerSelectionResult.invalid({required String reason}) =>
      CircuitBreakerSelectionResult._(
        status: CircuitBreakerSelectionStatus.invalid,
        reason: reason,
      );

  factory CircuitBreakerSelectionResult.noMatch({required String reason}) =>
      CircuitBreakerSelectionResult._(
        status: CircuitBreakerSelectionStatus.noMatch,
        reason: reason,
      );

  final CircuitBreakerSelectionStatus status;
  final String? reason;
  final BreakerType? breakerType;
  final double? ratedCurrentA;
  final BreakerPoleConfiguration? poleConfiguration;
  final BreakerSelectionMode? selectionMode;
  final double? designCurrentIbA;
  final double? currentMarginA;
  final double? breakingCapacityKa;
  final String? tripCurveDesignation;
  final String? manualOverrideReason;
  final List<CalculationSourceReference> sourceReferences;
  final String? catalogVersion;
  final CableCoordinationStatus? cableCoordinationStatus;

  CircuitBreakerSelectionResult markCableCoordinated() {
    if (status != CircuitBreakerSelectionStatus.selected ||
        designCurrentIbA == null) {
      throw StateError('Only an ACTIVE selected breaker can be coordinated.');
    }
    return CircuitBreakerSelectionResult.selected(
      breakerType: breakerType!,
      ratedCurrentA: ratedCurrentA!,
      poleConfiguration: poleConfiguration!,
      selectionMode: selectionMode!,
      sourceReferences: sourceReferences,
      catalogVersion: catalogVersion!,
      designCurrentIbA: designCurrentIbA,
      currentMarginA: currentMarginA,
      breakingCapacityKa: breakingCapacityKa,
      tripCurveDesignation: tripCurveDesignation,
      manualOverrideReason: manualOverrideReason,
      cableCoordinated: true,
    );
  }

  void _validate() {
    final isSelected = status == CircuitBreakerSelectionStatus.selected;
    final positiveValues = [
      ?ratedCurrentA,
      ?designCurrentIbA,
      ?breakingCapacityKa,
    ];
    if (positiveValues.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError('Breaker values must be finite and positive.');
    }
    if (currentMarginA != null && !currentMarginA!.isFinite) {
      throw ArgumentError('Current margin must be finite.');
    }
    final hasSelectedValues =
        breakerType != null ||
        ratedCurrentA != null ||
        poleConfiguration != null ||
        selectionMode != null ||
        designCurrentIbA != null ||
        currentMarginA != null ||
        breakingCapacityKa != null ||
        tripCurveDesignation != null ||
        manualOverrideReason != null ||
        catalogVersion != null ||
        cableCoordinationStatus != null;
    if (!isSelected) {
      if (hasSelectedValues || sourceReferences.isNotEmpty) {
        throw ArgumentError(
          'Unresolved breaker result cannot contain engineering values.',
        );
      }
      if (status != CircuitBreakerSelectionStatus.notCalculated &&
          (reason == null || reason!.trim().isEmpty)) {
        throw ArgumentError('Fail-closed breaker result requires a reason.');
      }
      return;
    }
    if (reason != null ||
        breakerType == null ||
        ratedCurrentA == null ||
        poleConfiguration == null ||
        selectionMode == null ||
        catalogVersion != CircuitBreakerCatalog.version ||
        sourceReferences.isEmpty) {
      throw ArgumentError(
        'Selected breaker requires a complete typed payload.',
      );
    }
    if (!CircuitBreakerCatalog.contains(breakerType!, ratedCurrentA!)) {
      throw ArgumentError('Selected rating is not in the approved catalog.');
    }
    if (tripCurveDesignation != null && tripCurveDesignation!.trim().isEmpty) {
      throw ArgumentError('Trip curve/designation cannot be blank.');
    }
    if (selectionMode == BreakerSelectionMode.manual &&
        (manualOverrideReason == null ||
            manualOverrideReason!.trim().isEmpty)) {
      throw ArgumentError('Manual selection requires a non-empty reason.');
    }
    if (selectionMode == BreakerSelectionMode.automatic &&
        manualOverrideReason != null) {
      throw ArgumentError(
        'Automatic selection cannot have an override reason.',
      );
    }
    final hasActivePayload = designCurrentIbA != null || currentMarginA != null;
    if (selectionMode == BreakerSelectionMode.automatic && !hasActivePayload) {
      throw ArgumentError(
        'Automatic selection requires an ACTIVE breaker payload.',
      );
    }
    if (hasActivePayload) {
      if (designCurrentIbA == null ||
          currentMarginA == null ||
          cableCoordinationStatus == null) {
        throw ArgumentError('ACTIVE breaker payload is incomplete.');
      }
      final expectedMargin = ratedCurrentA! - designCurrentIbA!;
      final marginScale = expectedMargin.abs() > 1 ? expectedMargin.abs() : 1.0;
      if ((expectedMargin - currentMarginA!).abs() > 1e-9 * marginScale) {
        throw ArgumentError('Current margin must equal In - Ib.');
      }
      if (currentMarginA! < 0) {
        throw ArgumentError('Selected breaker rating cannot be below Ib.');
      }
    } else if (cableCoordinationStatus != null) {
      throw ArgumentError(
        'SPARE breaker cannot have cable coordination status.',
      );
    }
  }

  Map<String, Object?> toJson() => {
    'status': status.name,
    if (reason != null) 'reason': reason,
    if (breakerType != null) 'breakerType': breakerType!.name,
    if (ratedCurrentA != null) 'ratedCurrentA': ratedCurrentA,
    if (poleConfiguration != null) 'poleConfiguration': poleConfiguration!.name,
    if (selectionMode != null) 'selectionMode': selectionMode!.name,
    if (designCurrentIbA != null) 'designCurrentIbA': designCurrentIbA,
    if (currentMarginA != null) 'currentMarginA': currentMarginA,
    if (breakingCapacityKa != null) 'breakingCapacityKa': breakingCapacityKa,
    if (tripCurveDesignation != null)
      'tripCurveDesignation': tripCurveDesignation,
    if (manualOverrideReason != null)
      'manualOverrideReason': manualOverrideReason,
    'sourceReferences': sourceReferences.map((item) => item.toJson()).toList(),
    if (catalogVersion != null) 'catalogVersion': catalogVersion,
    if (cableCoordinationStatus != null)
      'cableCoordinationStatus': cableCoordinationStatus!.name,
  };

  factory CircuitBreakerSelectionResult.fromJson(Map<String, Object?> json) {
    final status = CircuitBreakerSelectionStatus.values.byName(
      json['status'] as String,
    );
    if (status != CircuitBreakerSelectionStatus.selected) {
      const selectedKeys = [
        'breakerType',
        'ratedCurrentA',
        'poleConfiguration',
        'selectionMode',
        'designCurrentIbA',
        'currentMarginA',
        'breakingCapacityKa',
        'tripCurveDesignation',
        'manualOverrideReason',
        'catalogVersion',
        'cableCoordinationStatus',
      ];
      if (selectedKeys.any((key) => json[key] != null) ||
          (json['sourceReferences'] as List).isNotEmpty) {
        throw ArgumentError(
          'Unresolved breaker JSON cannot contain engineering values.',
        );
      }
      return switch (status) {
        CircuitBreakerSelectionStatus.notCalculated =>
          CircuitBreakerSelectionResult.notCalculated(
            reason: json['reason'] as String?,
          ),
        CircuitBreakerSelectionStatus.insufficient =>
          CircuitBreakerSelectionResult.insufficient(
            reason: json['reason'] as String,
          ),
        CircuitBreakerSelectionStatus.invalid =>
          CircuitBreakerSelectionResult.invalid(
            reason: json['reason'] as String,
          ),
        CircuitBreakerSelectionStatus.noMatch =>
          CircuitBreakerSelectionResult.noMatch(
            reason: json['reason'] as String,
          ),
        CircuitBreakerSelectionStatus.selected => throw StateError(
          'unreachable',
        ),
      };
    }
    final coordinationName = json['cableCoordinationStatus'] as String?;
    final hasActivePayload = json['designCurrentIbA'] != null;
    if ((hasActivePayload && coordinationName == null) ||
        (!hasActivePayload && coordinationName != null)) {
      throw ArgumentError(
        'Breaker JSON has inconsistent cable coordination status.',
      );
    }
    final coordination = coordinationName == null
        ? null
        : CableCoordinationStatus.values.byName(coordinationName);
    return CircuitBreakerSelectionResult.selected(
      breakerType: BreakerType.values.byName(json['breakerType'] as String),
      ratedCurrentA: (json['ratedCurrentA'] as num).toDouble(),
      poleConfiguration: BreakerPoleConfiguration.values.byName(
        json['poleConfiguration'] as String,
      ),
      selectionMode: BreakerSelectionMode.values.byName(
        json['selectionMode'] as String,
      ),
      designCurrentIbA: (json['designCurrentIbA'] as num?)?.toDouble(),
      currentMarginA: (json['currentMarginA'] as num?)?.toDouble(),
      breakingCapacityKa: (json['breakingCapacityKa'] as num?)?.toDouble(),
      tripCurveDesignation: json['tripCurveDesignation'] as String?,
      manualOverrideReason: json['manualOverrideReason'] as String?,
      sourceReferences: (json['sourceReferences'] as List)
          .map(
            (item) => CalculationSourceReference.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
      catalogVersion: json['catalogVersion'] as String,
      cableCoordinated: coordination == CableCoordinationStatus.coordinated,
    );
  }
}
