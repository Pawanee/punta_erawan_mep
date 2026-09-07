import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_23_repository.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_29_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> expectPublishedColumns({
    required Future<List<dynamic>> rowsFuture,
    required String tableId,
    required List<double> sizes,
    required List<double> group5TwoLoaded,
    required List<double> group5ThreeLoaded,
    required List<double> group6UpToThreeLoaded,
  }) async {
    final rows = await rowsFuture;
    expect(rows, hasLength(sizes.length * 8));

    for (var index = 0; index < sizes.length; index++) {
      final expectedColumns = <(int, int, double)>[
        (5, 2, group5TwoLoaded[index]),
        (5, 3, group5ThreeLoaded[index]),
        (6, 2, group6UpToThreeLoaded[index]),
        (6, 3, group6UpToThreeLoaded[index]),
      ];

      for (final (group, loaded, expectedAmpacity) in expectedColumns) {
        for (final coreType in CoreType.values) {
          final row = rows.singleWhere(
            (row) =>
                row.sizeSqmm == sizes[index] &&
                row.installationGroupNumber == group &&
                row.loadedConductors == loaded &&
                row.coreType == coreType,
          );
          expect(
            row.ampacity,
            expectedAmpacity,
            reason:
                'Table $tableId ${sizes[index]} sq.mm Group $group, '
                '$loaded loaded, ${coreType.name}',
          );
          expect(row.sourceReference, 'Table $tableId');
        }
      }
    }
  }

  test('Table 5-23 preserves every published size and column', () async {
    await expectPublishedColumns(
      rowsFuture: const Table523Repository().loadTable(),
      tableId: '5-23',
      sizes: const [
        1,
        1.5,
        2.5,
        4,
        6,
        10,
        16,
        25,
        35,
        50,
        70,
        95,
        120,
        150,
        185,
        240,
        300,
        400,
        500,
      ],
      group5TwoLoaded: const [
        17,
        21,
        28,
        36,
        46,
        62,
        81,
        106,
        129,
        153,
        190,
        232,
        265,
        303,
        344,
        404,
        462,
        529,
        605,
      ],
      group5ThreeLoaded: const [
        15,
        19,
        25,
        33,
        41,
        55,
        72,
        94,
        114,
        136,
        168,
        204,
        234,
        266,
        303,
        361,
        404,
        462,
        527,
      ],
      group6UpToThreeLoaded: const [
        21,
        26,
        35,
        45,
        57,
        76,
        99,
        128,
        154,
        181,
        223,
        267,
        304,
        342,
        386,
        448,
        507,
        577,
        654,
      ],
    );
  });

  test('Table 5-29 preserves every published size and column', () async {
    await expectPublishedColumns(
      rowsFuture: const Table529Repository().loadTable(),
      tableId: '5-29',
      sizes: const [
        1.5,
        2.5,
        4,
        6,
        10,
        16,
        25,
        35,
        50,
        70,
        95,
        120,
        150,
        185,
        240,
        300,
        400,
        500,
      ],
      group5TwoLoaded: const [
        25,
        33,
        43,
        54,
        71,
        94,
        124,
        150,
        180,
        223,
        271,
        313,
        355,
        406,
        477,
        543,
        625,
        717,
      ],
      group5ThreeLoaded: const [
        22,
        29,
        38,
        47,
        63,
        83,
        109,
        132,
        159,
        196,
        238,
        275,
        312,
        356,
        418,
        475,
        545,
        623,
      ],
      group6UpToThreeLoaded: const [
        33,
        43,
        55,
        70,
        92,
        119,
        152,
        184,
        217,
        266,
        318,
        362,
        406,
        459,
        533,
        601,
        684,
        777,
      ],
    );
  });

  test('Table 5-29 does not synthesize the unpublished 1 sq.mm row', () async {
    final rows = await const Table529Repository().loadTable();
    expect(rows.any((row) => row.sizeSqmm == 1), isFalse);
  });
}
