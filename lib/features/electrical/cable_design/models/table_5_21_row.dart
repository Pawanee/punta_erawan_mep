/// One cable-size row in Master Table 5-21.
///
/// Each map entry is a published source cell keyed by its independent column
/// identifier (C1 through C9). A null value is an unavailable "-" cell.
class Table521Row {
  const Table521Row({required this.sizeSqmm, required this.ampacityByColumnId});

  final double sizeSqmm;
  final Map<String, double?> ampacityByColumnId;

  double? ampacityForColumn(String columnId) => ampacityByColumnId[columnId];
}
