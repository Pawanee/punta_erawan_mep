import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table.dart';
import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table_schema.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/registries/ampacity_table_registry.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  const registry = AmpacityTableRegistry();

  test('registers only the currently implemented Table 5-20 and Table 5-27',
      () {
    expect(AmpacityTableRegistry.tables, hasLength(2));

    final table520 = registry.metadataFor(AmpacityTable.table520);
    expect(table520.tableId, '5-20');
    expect(table520.insulationTypes, [CableInsulation.pvc]);
    expect(
      table520.conductorTemperatureClasses,
      [ConductorTemperatureClass.pvc70],
    );
    expect(table520.applicableCableTypes, contains(CableType.iec01));
    expect(table520.schemaType, AmpacityTableSchema.groupCoreLoadedConductors);
    expect(table520.correctionTableReferences, ['Table 5-8', 'Table 5-43']);

    final table527 = registry.metadataFor(AmpacityTable.table527);
    expect(table527.tableId, '5-27');
    expect(table527.insulationTypes, [CableInsulation.xlpe]);
    expect(
      table527.conductorTemperatureClasses,
      [ConductorTemperatureClass.xlpeEpr90],
    );
    expect(table527.applicableCableTypes, [CableType.iec605021]);
    expect(table527.schemaType, AmpacityTableSchema.groupCoreLoadedConductors);
  });
}
