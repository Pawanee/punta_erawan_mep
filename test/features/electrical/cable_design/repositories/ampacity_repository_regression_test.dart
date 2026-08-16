import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/ampacity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = AmpacityRepository();

  Future<void> expectAmpacity({
    required AmpacityTable table,
    required CableType cableType,
    required InstallationMethod group,
    required int loadedConductors,
    required CoreType coreType,
    required double expectedAmpacity,
    required String tableId,
    required String displayName,
  }) async {
    final rows = await repository.loadTable(
      table: table,
      cableType: cableType,
    );
    final row = rows.firstWhere(
      (candidate) =>
          candidate.cableSizeSqmm == 4 &&
          candidate.installationMethod == group &&
          candidate.loadedConductors == loadedConductors &&
          candidate.coreType == coreType,
    );

    expect(row.ampacity, expectedAmpacity);
    expect(row.baseAmpacity, expectedAmpacity);
    expect(row.sourceTableId, tableId);
    expect(row.sourceTableDisplayName, displayName);
  }

  group('AmpacityRepository Table 5-20 regression', () {
    test('preserves all Group 1/2, 2/3 conductor, core combinations',
        () async {
      await expectAmpacity(
        table: AmpacityTable.table520,
        cableType: CableType.iec01,
        group: InstallationMethod.group1,
        loadedConductors: 2,
        coreType: CoreType.singleCore,
        expectedAmpacity: 23,
        tableId: '5-20',
        displayName: 'Table 5-20',
      );
      await expectAmpacity(
        table: AmpacityTable.table520,
        cableType: CableType.iec01,
        group: InstallationMethod.group1,
        loadedConductors: 2,
        coreType: CoreType.multiCore,
        expectedAmpacity: 22,
        tableId: '5-20',
        displayName: 'Table 5-20',
      );
      await expectAmpacity(
        table: AmpacityTable.table520,
        cableType: CableType.iec01,
        group: InstallationMethod.group1,
        loadedConductors: 3,
        coreType: CoreType.singleCore,
        expectedAmpacity: 21,
        tableId: '5-20',
        displayName: 'Table 5-20',
      );
      await expectAmpacity(
        table: AmpacityTable.table520,
        cableType: CableType.iec01,
        group: InstallationMethod.group1,
        loadedConductors: 3,
        coreType: CoreType.multiCore,
        expectedAmpacity: 20,
        tableId: '5-20',
        displayName: 'Table 5-20',
      );
      await expectAmpacity(
        table: AmpacityTable.table520,
        cableType: CableType.iec01,
        group: InstallationMethod.group2,
        loadedConductors: 2,
        coreType: CoreType.singleCore,
        expectedAmpacity: 28,
        tableId: '5-20',
        displayName: 'Table 5-20',
      );
      await expectAmpacity(
        table: AmpacityTable.table520,
        cableType: CableType.iec01,
        group: InstallationMethod.group2,
        loadedConductors: 2,
        coreType: CoreType.multiCore,
        expectedAmpacity: 26,
        tableId: '5-20',
        displayName: 'Table 5-20',
      );
      await expectAmpacity(
        table: AmpacityTable.table520,
        cableType: CableType.iec01,
        group: InstallationMethod.group2,
        loadedConductors: 3,
        coreType: CoreType.singleCore,
        expectedAmpacity: 24,
        tableId: '5-20',
        displayName: 'Table 5-20',
      );
      await expectAmpacity(
        table: AmpacityTable.table520,
        cableType: CableType.iec01,
        group: InstallationMethod.group2,
        loadedConductors: 3,
        coreType: CoreType.multiCore,
        expectedAmpacity: 23,
        tableId: '5-20',
        displayName: 'Table 5-20',
      );
    });

    test('does not create candidates for unavailable Table 5-20 cells',
        () async {
      final rows = await repository.loadTable(
        table: AmpacityTable.table520,
        cableType: CableType.iec01,
      );

      expect(
        rows.any(
          (row) =>
              row.cableSizeSqmm == 400 &&
              row.installationMethod == InstallationMethod.group1,
        ),
        isFalse,
      );
    });
  });

  group('AmpacityRepository Table 5-27 regression', () {
    test('preserves all Group 1/2, 2/3 conductor, core combinations',
        () async {
      await expectAmpacity(
        table: AmpacityTable.table527,
        cableType: CableType.iec605021,
        group: InstallationMethod.group1,
        loadedConductors: 2,
        coreType: CoreType.singleCore,
        expectedAmpacity: 32,
        tableId: '5-27',
        displayName: 'Table 5-27',
      );
      await expectAmpacity(
        table: AmpacityTable.table527,
        cableType: CableType.iec605021,
        group: InstallationMethod.group1,
        loadedConductors: 2,
        coreType: CoreType.multiCore,
        expectedAmpacity: 30,
        tableId: '5-27',
        displayName: 'Table 5-27',
      );
      await expectAmpacity(
        table: AmpacityTable.table527,
        cableType: CableType.iec605021,
        group: InstallationMethod.group1,
        loadedConductors: 3,
        coreType: CoreType.singleCore,
        expectedAmpacity: 28,
        tableId: '5-27',
        displayName: 'Table 5-27',
      );
      await expectAmpacity(
        table: AmpacityTable.table527,
        cableType: CableType.iec605021,
        group: InstallationMethod.group1,
        loadedConductors: 3,
        coreType: CoreType.multiCore,
        expectedAmpacity: 27,
        tableId: '5-27',
        displayName: 'Table 5-27',
      );
      await expectAmpacity(
        table: AmpacityTable.table527,
        cableType: CableType.iec605021,
        group: InstallationMethod.group2,
        loadedConductors: 2,
        coreType: CoreType.singleCore,
        expectedAmpacity: 38,
        tableId: '5-27',
        displayName: 'Table 5-27',
      );
      await expectAmpacity(
        table: AmpacityTable.table527,
        cableType: CableType.iec605021,
        group: InstallationMethod.group2,
        loadedConductors: 2,
        coreType: CoreType.multiCore,
        expectedAmpacity: 36,
        tableId: '5-27',
        displayName: 'Table 5-27',
      );
      await expectAmpacity(
        table: AmpacityTable.table527,
        cableType: CableType.iec605021,
        group: InstallationMethod.group2,
        loadedConductors: 3,
        coreType: CoreType.singleCore,
        expectedAmpacity: 34,
        tableId: '5-27',
        displayName: 'Table 5-27',
      );
      await expectAmpacity(
        table: AmpacityTable.table527,
        cableType: CableType.iec605021,
        group: InstallationMethod.group2,
        loadedConductors: 3,
        coreType: CoreType.multiCore,
        expectedAmpacity: 32,
        tableId: '5-27',
        displayName: 'Table 5-27',
      );
    });

    test('does not create candidates for unavailable Table 5-27 cells',
        () async {
      final rows = await repository.loadTable(
        table: AmpacityTable.table527,
        cableType: CableType.iec605021,
      );

      expect(
        rows.any(
          (row) =>
              row.cableSizeSqmm == 400 &&
              row.installationMethod == InstallationMethod.group1,
        ),
        isFalse,
      );
    });
  });
}
