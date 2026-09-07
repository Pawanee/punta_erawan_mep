import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table.dart';
import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table_schema.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/registries/ampacity_table_registry.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  const registry = AmpacityTableRegistry();

  test('registers all five approved ampacity tables', () {
    expect(AmpacityTableRegistry.tables, hasLength(5));

    final table520 = registry.metadataFor(AmpacityTable.table520);
    expect(table520.tableId, '5-20');
    expect(table520.insulationTypes, [CableInsulation.pvc]);
    expect(table520.conductorTemperatureClasses, [
      ConductorTemperatureClass.pvc70,
    ]);
    expect(table520.applicableCableTypes, contains(CableType.iec01));
    expect(table520.schemaType, AmpacityTableSchema.groupCoreLoadedConductors);
    expect(table520.correctionTableReferences, ['Table 5-8', 'Table 5-43']);

    final table521 = registry.metadataFor(AmpacityTable.table521);
    expect(table521.tableId, '5-21');
    expect(table521.referenceAmbientTemperatureC, 40);
    expect(table521.insulationTypes, [
      CableInsulation.pvc,
      CableInsulation.xlpe,
    ]);
    expect(table521.installationGroups, isEmpty);
    expect(table521.installationGroupNumbers, [3]);
    expect(table521.schemaType, AmpacityTableSchema.surfaceMountedCable);
    expect(table521.correctionTableReferences, ['Table 5-43']);

    final table523 = registry.metadataFor(AmpacityTable.table523);
    expect(table523.tableId, '5-23');
    expect(table523.referenceAmbientTemperatureC, 30);
    expect(table523.insulationTypes, [CableInsulation.pvc]);
    expect(table523.installationGroupNumbers, [5, 6]);
    expect(table523.schemaType, AmpacityTableSchema.underground);
    expect(table523.applicableCableTypes, contains(CableType.nyy));
    expect(table523.applicableCableTypes, contains(CableType.iec605021));
    expect(table523.correctionTableReferences, [
      'Table 5-8',
      'Table 5-44',
      'Table 5-45',
      'Table 5-46',
    ]);

    final table527 = registry.metadataFor(AmpacityTable.table527);
    expect(table527.tableId, '5-27');
    expect(table527.insulationTypes, [CableInsulation.xlpe]);
    expect(table527.conductorTemperatureClasses, [
      ConductorTemperatureClass.xlpeEpr90,
    ]);
    expect(table527.applicableCableTypes, [CableType.iec605021]);
    expect(table527.schemaType, AmpacityTableSchema.groupCoreLoadedConductors);

    final table529 = registry.metadataFor(AmpacityTable.table529);
    expect(table529.tableId, '5-29');
    expect(table529.referenceAmbientTemperatureC, 30);
    expect(table529.insulationTypes, [CableInsulation.xlpe]);
    expect(table529.installationGroupNumbers, [5, 6]);
    expect(table529.applicableCableTypes, [CableType.iec605021]);
    expect(table529.schemaType, AmpacityTableSchema.underground);
  });
}
