import 'circuit_calculation_result.dart';
import 'panel_calculated_totals.dart';
import 'panel_definition.dart';

class PanelCalculationSnapshot {
  PanelCalculationSnapshot({
    required this.snapshotId,
    required this.panelDefinition,
    required this.revision,
    required this.schemaVersion,
    required this.engineVersion,
    required this.calculatedAt,
    required List<CircuitCalculationResult> circuitResults,
    required this.calculatedTotals,
  }) : circuitResults = List.unmodifiable(circuitResults) {
    if (snapshotId.trim().isEmpty ||
        schemaVersion.trim().isEmpty ||
        engineVersion.trim().isEmpty) {
      throw ArgumentError('Snapshot identity and versions are required.');
    }
    if (revision <= 0) {
      throw ArgumentError.value(revision, 'revision', 'Must be positive.');
    }
    final expected = panelDefinition.circuits
        .map((circuit) => circuit.circuitNo)
        .toSet();
    final actual = circuitResults.map((result) => result.circuitNo).toSet();
    if (actual.length != circuitResults.length ||
        expected.length != actual.length ||
        !expected.containsAll(actual)) {
      throw ArgumentError(
        'Snapshot circuit results must match the panel definition exactly.',
      );
    }
    for (final definition in panelDefinition.circuits) {
      final result = circuitResults.singleWhere(
        (candidate) => candidate.circuitNo == definition.circuitNo,
      );
      if (result.circuitStatus != definition.status ||
          result.phaseConfiguration != definition.phaseConfiguration) {
        throw ArgumentError(
          'Snapshot results must preserve circuit status and phase configuration.',
        );
      }
    }
  }

  final String snapshotId;
  final PanelDefinition panelDefinition;
  final int revision;
  final String schemaVersion;
  final String engineVersion;
  final DateTime calculatedAt;
  final List<CircuitCalculationResult> circuitResults;
  final PanelCalculatedTotals calculatedTotals;

  Map<String, Object?> toJson() => {
    'snapshotId': snapshotId,
    'panelDefinition': panelDefinition.toJson(),
    'revision': revision,
    'schemaVersion': schemaVersion,
    'engineVersion': engineVersion,
    'calculatedAt': calculatedAt.toUtc().toIso8601String(),
    'circuitResults': circuitResults.map((result) => result.toJson()).toList(),
    'calculatedTotals': calculatedTotals.toJson(),
  };

  factory PanelCalculationSnapshot.fromJson(Map<String, Object?> json) =>
      PanelCalculationSnapshot(
        snapshotId: json['snapshotId'] as String,
        panelDefinition: PanelDefinition.fromJson(
          Map<String, Object?>.from(json['panelDefinition'] as Map),
        ),
        revision: json['revision'] as int,
        schemaVersion: json['schemaVersion'] as String,
        engineVersion: json['engineVersion'] as String,
        calculatedAt: DateTime.parse(json['calculatedAt'] as String),
        circuitResults: (json['circuitResults'] as List)
            .map(
              (item) => CircuitCalculationResult.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
        calculatedTotals: PanelCalculatedTotals.fromJson(
          Map<String, Object?>.from(json['calculatedTotals'] as Map),
        ),
      );
}
