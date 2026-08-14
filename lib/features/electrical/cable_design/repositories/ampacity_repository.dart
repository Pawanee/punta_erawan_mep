import '../enums/ampacity_table.dart';
import '../enums/cable_type.dart';
import '../models/cable_table_row.dart';
import 'table_5_20_repository.dart';
import 'table_5_27_repository.dart';
import 'table_527_candidate_adapter.dart';

/// Unified access point for approved ampacity reference tables.
///
/// Responsibilities:
/// - select the approved ampacity source table;
/// - delegate data loading to the corresponding repository;
/// - normalize Table 5-27 rows to CableTableRow for downstream consumers.
///
/// This class does not:
/// - decide CableType -> PVC/XLPE policy;
/// - apply grouping factors;
/// - apply ambient-temperature correction factors;
/// - calculate ampacity;
/// - sort or filter engineering candidates.
class AmpacityRepository {
  AmpacityRepository({
    Table520Repository? table520Repository,
    Table527Repository? table527Repository,
    Table527CandidateAdapter? table527Adapter,
  })  : _table520Repository =
            table520Repository ?? Table520Repository(),
        _table527Repository =
            table527Repository ?? Table527Repository(),
        _table527Adapter =
            table527Adapter ?? const Table527CandidateAdapter();

  final Table520Repository _table520Repository;
  final Table527Repository _table527Repository;
  final Table527CandidateAdapter _table527Adapter;

  /// Loads ampacity candidates from the requested reference table.
  ///
  /// [cableType] is preserved as candidate metadata.
  /// It does not determine which ampacity table is selected.
  Future<List<CableTableRow>> loadTable({
    required AmpacityTable table,
    required CableType cableType,
  }) async {
    switch (table) {
      case AmpacityTable.table520:
        return _table520Repository.loadTable(
          cableType: cableType,
        );

      case AmpacityTable.table527:
        final rows = await _table527Repository.loadTable();

        return _table527Adapter.adapt(
          rows: rows,
          cableType: cableType,
        );
    }
  }
}