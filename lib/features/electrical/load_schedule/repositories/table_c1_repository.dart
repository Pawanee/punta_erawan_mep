enum TableC1CellStatus { publishedCapacity, dash, blank }

class TableC1Cell {
  const TableC1Cell.capacity(int value)
    : status = TableC1CellStatus.publishedCapacity,
      capacity = value,
      assert(value > 0);
  const TableC1Cell.dash() : status = TableC1CellStatus.dash, capacity = null;
  const TableC1Cell.blank() : status = TableC1CellStatus.blank, capacity = null;
  final TableC1CellStatus status;
  final int? capacity;
}

class TableC1Column {
  const TableC1Column(this.nominalMm, this.inchLabel);
  final int nominalMm;
  final String inchLabel;
  String get id => 'nominalMm:$nominalMm';
}

class TableC1Row {
  TableC1Row(this.conductorSizeSqmm, List<TableC1Cell> cells)
    : cells = List.unmodifiable(cells);
  final double conductorSizeSqmm;
  final List<TableC1Cell> cells;
  String get id => 'conductorSqmm:$conductorSizeSqmm';
}

class TableC1Selection {
  const TableC1Selection(
    this.row,
    this.column,
    this.requestedCount,
    this.capacity,
  );
  final TableC1Row row;
  final TableC1Column column;
  final int requestedCount;
  final int capacity;
}

/// Transcription of the approved source. Dash and blank are not capacities.
class TableC1Repository {
  const TableC1Repository();
  static const tableId = 'C1';
  static const version = 'table-c1-v1';
  static const title =
      'ตารางที่ C1 จำนวนสายไฟฟ้าขนาดเดียวกันในท่อร้อยสาย สำหรับสายไฟฟ้าตาม มอก. 11-2553 รหัสชนิด 60227 IEC 01';
  static const documentTitle = 'คู่มือการติดตั้งระบบไฟฟ้าอย่างมืออาชีพ';
  static const cableStandard = 'มอก. 11-2553';
  static const cableCode = '60227 IEC 01';
  static const page = 259;
  static const source =
      'มาตรฐานการติดตั้งทางไฟฟ้าสำหรับประเทศไทย พ.ศ.2564 ภาคผนวก ฎ';
  static const sourceSha256 =
      '52ac8423e4a8541e3e2a2fb3d7cb008b4d716d8cd72953f7c6805a616f118558';
  static const resultLabel = 'Table C1 nominal conduit size';
  static const materialScope =
      'Conduit material is not certified by Table C1 lookup.';
  static const columns = [
    TableC1Column(15, '1/2'),
    TableC1Column(20, '3/4'),
    TableC1Column(25, '1'),
    TableC1Column(32, '1 1/4'),
    TableC1Column(40, '1 1/2'),
    TableC1Column(50, '2'),
    TableC1Column(65, '2 1/2'),
    TableC1Column(80, '3'),
    TableC1Column(90, '3 1/2'),
    TableC1Column(100, '4'),
    TableC1Column(125, '5'),
    TableC1Column(150, '6'),
  ];
  // '-' is a printed dash; '_' is an empty source cell.
  static final rows = List<TableC1Row>.unmodifiable([
    _row(1.5, '8 14 22 37 - - - - - - - -'),
    _row(2.5, '5 10 15 25 _ - - - - - - -'),
    _row(4, '4 7 11 19 30 - - - - - - -'),
    _row(6, '3 5 9 15 23 37 - - - - - -'),
    _row(10, '1 3 5 9 14 22 _ - - - - -'),
    _row(16, '1 2 4 6 10 16 27 42 - - - -'),
    _row(25, '1 2 2 4 6 10 17 27 34 - - -'),
    _row(35, '1 1 2 3 5 8 14 21 27 33 _ _'),
    _row(50, '- 1 1 1 3 6 10 15 19 24 38 _'),
    _row(70, '- - 1 1 3 4 7 12 15 18 29 42'),
    _row(95, '- - 1 1 1 3 5 8 11 13 21 30'),
    _row(120, '- - - 1 1 2 4 7 9 11 17 25'),
    _row(150, '- - - 1 1 1 3 5 7 9 14 20'),
    _row(185, '- - - 1 1 1 3 4 6 7 11 16'),
    _row(240, '- - - - 1 1 1 3 4 5 8 12'),
    _row(300, '- - - - - 1 1 2 3 4 7 10'),
    _row(400, '- - - - - 1 1 1 2 3 5 8'),
  ]);
  static TableC1Row _row(double size, String data) => TableC1Row(
    size,
    data
        .split(' ')
        .map(
          (s) => switch (s) {
            '-' => const TableC1Cell.dash(),
            '_' => const TableC1Cell.blank(),
            _ => TableC1Cell.capacity(int.parse(s)),
          },
        )
        .toList(),
  );

  TableC1Selection? select(double sizeSqmm, int physicalCount) {
    if (!sizeSqmm.isFinite || sizeSqmm <= 0 || physicalCount <= 0) {
      throw ArgumentError('Size and physical count must be positive.');
    }
    for (final row in rows) {
      if (row.conductorSizeSqmm != sizeSqmm) continue;
      for (var i = 0; i < columns.length; i++) {
        final cell = row.cells[i];
        if (cell.status == TableC1CellStatus.publishedCapacity &&
            physicalCount <= cell.capacity!) {
          return TableC1Selection(
            row,
            columns[i],
            physicalCount,
            cell.capacity!,
          );
        }
      }
    }
    return null;
  }
}
