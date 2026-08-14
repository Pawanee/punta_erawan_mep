import '../enums/cable_type.dart';
import '../models/cable_table_row.dart';
import '../models/table_5_27_row.dart';

/// Converts Master Table 5-27 rows into the common cable candidate model.
///
/// Table 5-27 is an XLPE ampacity reference table, while [Table527Row]
/// intentionally does not contain CableType metadata.
///
/// The adapter adds only candidate metadata required by the common
/// downstream model:
/// - CableType
/// - reference name
///
/// No engineering calculation or correction factor is applied here.
class Table527CandidateAdapter {
  const Table527CandidateAdapter();

  /// Converts Table 5-27 rows into [CableTableRow] candidates.
  List<CableTableRow> adapt({
    required List<Table527Row> rows,
    required CableType cableType,
  }) {
    return rows
        .map(
          (row) => CableTableRow(
            cableType: cableType,
            installationMethod: row.installationMethod,
            loadedConductors: row.loadedConductors,
            coreType: row.coreType,
            cableSizeSqmm: row.cableSizeSqmm,
            ampacity: row.ampacity,
            remark: '',
            reference: Table527Row.reference,
          ),
        )
        .toList();
  }
}