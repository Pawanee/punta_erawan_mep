import '../enums/core_type.dart';

/// One published ampacity cell from an underground Group 5/6 table.
///
/// Group 6 publishes one value for not more than three loaded conductors. The
/// repository expands that source cell into explicit 2- and 3-loaded rows so
/// downstream matching never has to infer the meaning of "not more than 3".
class UndergroundAmpacityRow {
  const UndergroundAmpacityRow({
    required this.tableId,
    required this.sizeSqmm,
    required this.installationGroupNumber,
    required this.loadedConductors,
    required this.coreType,
    required this.ampacity,
  });

  final String tableId;
  final double sizeSqmm;
  final int installationGroupNumber;
  final int loadedConductors;
  final CoreType coreType;
  final double ampacity;

  String get sourceReference => 'Table $tableId';
}
