import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_23_repository.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_29_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Table 5-23 preserves every published size and Group 5 value', () async {
    final rows = await const Table523Repository().loadTable();
    expect(rows, hasLength(19 * 8));
    final row = rows.singleWhere(
      (row) =>
          row.sizeSqmm == 10 &&
          row.installationGroupNumber == 5 &&
          row.loadedConductors == 3 &&
          row.coreType == CoreType.multiCore,
    );
    expect(row.ampacity, 55);
    expect(row.sourceReference, 'Table 5-23');
  });

  test('Table 5-23 expands Group 6 up-to-three source faithfully', () async {
    final rows = await const Table523Repository().loadTable();
    for (final loaded in const [2, 3]) {
      for (final coreType in CoreType.values) {
        expect(
          rows
              .singleWhere(
                (row) =>
                    row.sizeSqmm == 500 &&
                    row.installationGroupNumber == 6 &&
                    row.loadedConductors == loaded &&
                    row.coreType == coreType,
              )
              .ampacity,
          654,
        );
      }
    }
  });

  test('Table 5-29 starts at 1.5 sq.mm and preserves end values', () async {
    final rows = await const Table529Repository().loadTable();
    expect(rows, hasLength(18 * 8));
    expect(rows.any((row) => row.sizeSqmm == 1), isFalse);
    expect(
      rows
          .singleWhere(
            (row) =>
                row.sizeSqmm == 500 &&
                row.installationGroupNumber == 5 &&
                row.loadedConductors == 3 &&
                row.coreType == CoreType.singleCore,
          )
          .ampacity,
      623,
    );
    expect(
      rows
          .singleWhere(
            (row) =>
                row.sizeSqmm == 500 &&
                row.installationGroupNumber == 6 &&
                row.loadedConductors == 2 &&
                row.coreType == CoreType.multiCore,
          )
          .ampacity,
      777,
    );
  });
}
