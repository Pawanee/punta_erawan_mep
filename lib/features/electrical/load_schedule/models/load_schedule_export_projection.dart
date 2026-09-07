import 'dart:collection';

class LoadScheduleExportProjection {
  LoadScheduleExportProjection({
    required this.snapshotId,
    required Map<String, Object?> panelHeader,
    required List<String> columns,
    required List<Map<String, Object?>> rows,
    required Map<String, Object?> summary,
  }) : panelHeader = UnmodifiableMapView(Map.of(panelHeader)),
       columns = List.unmodifiable(columns),
       rows = List.unmodifiable(
         rows.map((row) => UnmodifiableMapView(Map.of(row))),
       ),
       summary = UnmodifiableMapView(Map.of(summary)) {
    if (snapshotId.trim().isEmpty || columns.isEmpty) {
      throw ArgumentError(
        'An export projection requires a snapshot and columns.',
      );
    }
  }

  final String snapshotId;
  final Map<String, Object?> panelHeader;
  final List<String> columns;
  final List<Map<String, Object?>> rows;
  final Map<String, Object?> summary;

  Map<String, Object?> toJson() => {
    'snapshotId': snapshotId,
    'panelHeader': Map<String, Object?>.of(panelHeader),
    'columns': columns,
    'rows': rows.map((row) => Map<String, Object?>.of(row)).toList(),
    'summary': Map<String, Object?>.of(summary),
  };

  factory LoadScheduleExportProjection.fromJson(Map<String, Object?> json) =>
      LoadScheduleExportProjection(
        snapshotId: json['snapshotId'] as String,
        panelHeader: Map<String, Object?>.from(json['panelHeader'] as Map),
        columns: (json['columns'] as List).cast<String>(),
        rows: (json['rows'] as List)
            .map((row) => Map<String, Object?>.from(row as Map))
            .toList(),
        summary: Map<String, Object?>.from(json['summary'] as Map),
      );
}
