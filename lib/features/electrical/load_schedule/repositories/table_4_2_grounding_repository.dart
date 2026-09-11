import '../models/table_4_2_grounding_row.dart';

class Table42GroundingRepository {
  const Table42GroundingRepository();

  static const tableId = '4-2';
  static const version = 'table-4-2-v1';
  static const title = 'ขนาดสายดินเล็กสุดของบริภัณฑ์ไฟฟ้า';
  static const documentTitle = 'คู่มือการติดตั้งระบบไฟฟ้าอย่างมืออาชีพ';
  static const page = 113;

  static const rows = <Table42GroundingRow>[
    Table42GroundingRow(
      protectiveDeviceThresholdA: 20,
      minimumGroundingConductorSizeSqmm: 2.5,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 40,
      minimumGroundingConductorSizeSqmm: 4,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 70,
      minimumGroundingConductorSizeSqmm: 6,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 100,
      minimumGroundingConductorSizeSqmm: 10,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 200,
      minimumGroundingConductorSizeSqmm: 16,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 400,
      minimumGroundingConductorSizeSqmm: 25,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 500,
      minimumGroundingConductorSizeSqmm: 35,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 800,
      minimumGroundingConductorSizeSqmm: 50,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 1000,
      minimumGroundingConductorSizeSqmm: 70,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 1250,
      minimumGroundingConductorSizeSqmm: 95,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 2000,
      minimumGroundingConductorSizeSqmm: 120,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 2500,
      minimumGroundingConductorSizeSqmm: 185,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 4000,
      minimumGroundingConductorSizeSqmm: 240,
    ),
    Table42GroundingRow(
      protectiveDeviceThresholdA: 6000,
      minimumGroundingConductorSizeSqmm: 400,
    ),
  ];

  List<Table42GroundingRow> loadRows() => rows;

  Table42GroundingRow? selectCeiling(double protectiveDeviceValueA) {
    if (!protectiveDeviceValueA.isFinite || protectiveDeviceValueA <= 0) {
      throw ArgumentError.value(
        protectiveDeviceValueA,
        'protectiveDeviceValueA',
        'Must be finite and positive.',
      );
    }
    if (protectiveDeviceValueA > rows.last.protectiveDeviceThresholdA) {
      return null;
    }
    return rows.firstWhere(
      (row) => row.protectiveDeviceThresholdA >= protectiveDeviceValueA,
    );
  }
}
