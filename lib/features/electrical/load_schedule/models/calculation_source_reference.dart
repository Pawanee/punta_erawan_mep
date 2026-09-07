class CalculationSourceReference {
  CalculationSourceReference({
    required this.sourceId,
    required this.label,
    this.tableId,
    this.columnId,
    this.rowId,
    this.sourceVersion,
  }) {
    _requireNonBlank(sourceId, 'sourceId');
    _requireNonBlank(label, 'label');
    _requireOptionalNonBlank(tableId, 'tableId');
    _requireOptionalNonBlank(columnId, 'columnId');
    _requireOptionalNonBlank(rowId, 'rowId');
    _requireOptionalNonBlank(sourceVersion, 'sourceVersion');
  }

  final String sourceId;
  final String label;
  final String? tableId;
  final String? columnId;
  final String? rowId;
  final String? sourceVersion;

  static void _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Must not be blank.');
    }
  }

  static void _requireOptionalNonBlank(String? value, String name) {
    if (value != null) {
      _requireNonBlank(value, name);
    }
  }

  Map<String, Object?> toJson() => {
    'sourceId': sourceId,
    'label': label,
    if (tableId != null) 'tableId': tableId,
    if (columnId != null) 'columnId': columnId,
    if (rowId != null) 'rowId': rowId,
    if (sourceVersion != null) 'sourceVersion': sourceVersion,
  };

  factory CalculationSourceReference.fromJson(Map<String, Object?> json) =>
      CalculationSourceReference(
        sourceId: json['sourceId'] as String,
        label: json['label'] as String,
        tableId: json['tableId'] as String?,
        columnId: json['columnId'] as String?,
        rowId: json['rowId'] as String?,
        sourceVersion: json['sourceVersion'] as String?,
      );
}
