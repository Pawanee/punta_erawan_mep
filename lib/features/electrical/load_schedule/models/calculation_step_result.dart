import '../enums/calculation_status.dart';
import 'calculation_source_reference.dart';

class CalculationStepResult {
  CalculationStepResult({
    required this.status,
    this.reason,
    List<CalculationSourceReference> sourceReferences = const [],
  }) : sourceReferences = List.unmodifiable(sourceReferences) {
    if ((status == CalculationStatus.insufficient ||
            status == CalculationStatus.invalid) &&
        (reason == null || reason!.trim().isEmpty)) {
      throw ArgumentError('Fail-closed results require a reason.');
    }
  }

  final CalculationStatus status;
  final String? reason;
  final List<CalculationSourceReference> sourceReferences;

  Map<String, Object?> toJson() => {
    'status': status.name,
    if (reason != null) 'reason': reason,
    'sourceReferences': sourceReferences
        .map((reference) => reference.toJson())
        .toList(),
  };

  factory CalculationStepResult.fromJson(Map<String, Object?> json) =>
      CalculationStepResult(
        status: CalculationStatus.values.byName(json['status'] as String),
        reason: json['reason'] as String?,
        sourceReferences: (json['sourceReferences'] as List)
            .map(
              (item) => CalculationSourceReference.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
      );
}

class PendingEngineeringResult {
  const PendingEngineeringResult.notCalculated({this.reason})
    : status = PendingEngineeringStatus.notCalculated;

  PendingEngineeringResult.insufficient({required this.reason})
    : status = PendingEngineeringStatus.insufficient {
    if (reason == null || reason!.trim().isEmpty) {
      throw ArgumentError('An insufficient result requires a reason.');
    }
  }

  final PendingEngineeringStatus status;
  final String? reason;

  Map<String, Object?> toJson() => {
    'status': status.name,
    if (reason != null) 'reason': reason,
  };

  factory PendingEngineeringResult.fromJson(Map<String, Object?> json) {
    final status = PendingEngineeringStatus.values.byName(
      json['status'] as String,
    );
    return switch (status) {
      PendingEngineeringStatus.notCalculated =>
        PendingEngineeringResult.notCalculated(
          reason: json['reason'] as String?,
        ),
      PendingEngineeringStatus.insufficient =>
        PendingEngineeringResult.insufficient(
          reason: json['reason'] as String?,
        ),
    };
  }
}
