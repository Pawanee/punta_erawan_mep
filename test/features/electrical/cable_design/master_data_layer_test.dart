import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/models/table_5_27_row.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/installation_method.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_27_repository.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_43_repository.dart';
import 'package:mep_project/features/electrical/cable_design/models/table_5_43_temperature_factor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Table 5-27 loads Master XLPE ampacity data without calculation', () async {
    final rows = await Table527Repository().loadTable();

    expect(rows.length, 140);
    expect(Table527Row.reference, 'Table 5-27');

    final row = rows.firstWhere(
      (item) =>
          item.cableSizeSqmm == 4 &&
          item.installationMethod == InstallationMethod.group1 &&
          item.loadedConductors == 3 &&
          item.coreType == CoreType.singleCore,
    );

    expect(row.ampacity, 28);
  });

  test('Table 5-27 preserves 400/500 sq.mm null cells', () async {
    final rows = await Table527Repository().loadTable();

    expect(
      rows.any((row) =>
          row.cableSizeSqmm == 400 &&
          row.installationMethod == InstallationMethod.group2 &&
          row.loadedConductors == 2 &&
          row.coreType == CoreType.singleCore &&
          row.ampacity == 622),
      isTrue,
    );

    expect(
      rows.any((row) => row.cableSizeSqmm == 400 &&
          row.installationMethod == InstallationMethod.group1),
      isFalse,
    );
  });

  test('Table 5-43 returns the 36-40C reference row', () async {
    final row = await Table543Repository().findByAmbientTemperature(40);

    expect(row, isNotNull);
    expect(Table543TemperatureFactor.reference, 'Table 5-43');
    expect(row!.ambientMinC, 36);
    expect(row.ambientMaxC, 40);
    expect(row.factorFor(ConductorTemperatureClass.pvc70), 1.0);
    expect(row.factorFor(ConductorTemperatureClass.xlpeEpr90), 1.0);
  });

  test('Table 5-43 preserves unavailable factor cells as null', () async {
    final row = await Table543Repository().findByAmbientTemperature(15);

    expect(row, isNotNull);
    expect(row!.factorFor(ConductorTemperatureClass.pvc90), isNull);
  });

  test('Table 5-43 does not interpolate outside the published ranges', () async {
    expect(
      await Table543Repository().findByAmbientTemperature(10),
      isNull,
    );
    expect(
      await Table543Repository().findByAmbientTemperature(95),
      isNotNull,
    );
    expect(
      await Table543Repository().findByAmbientTemperature(96),
      isNull,
    );
  });
}
