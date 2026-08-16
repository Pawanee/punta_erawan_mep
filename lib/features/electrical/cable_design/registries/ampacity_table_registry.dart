import '../enums/ampacity_table.dart';
import '../enums/ampacity_table_schema.dart';
import '../enums/cable_type.dart';
import '../enums/conductor_temperature_class.dart';
import '../enums/installation_method.dart';
import '../models/ampacity_table_metadata.dart';
import '../../voltage_drop/enums/cable_insulation.dart';

/// Registry of ampacity reference-table metadata available to the application.
///
/// The registry does not load or calculate ampacity values. It only describes
/// which existing repository is being used and preserves its engineering
/// traceability metadata.
class AmpacityTableRegistry {
  const AmpacityTableRegistry();

  static const _pvcCableTypes = <CableType>[
    CableType.iec01,
    CableType.iec02,
    CableType.iec05,
    CableType.iec06,
    CableType.iec10,
    CableType.nyy,
    CableType.nyyG,
    CableType.vct,
    CableType.vctG,
  ];

  static const _groupCoreLoadedConductors =
      AmpacityTableSchema.groupCoreLoadedConductors;

  static const tables = <AmpacityTableMetadata>[
    AmpacityTableMetadata(
      table: AmpacityTable.table520,
      tableId: '5-20',
      displayName: 'Table 5-20',
      category: 'Copper insulated cable ampacity',
      conductorMaterial: 'Copper',
      insulationTypes: [CableInsulation.pvc],
      conductorTemperatureClasses: [ConductorTemperatureClass.pvc70],
      referenceAmbientTemperatureC: 40,
      installationGroups: [
        InstallationMethod.group1,
        InstallationMethod.group2,
      ],
      installationGroupNumbers: [1, 2],
      applicableCableTypes: _pvcCableTypes,
      schemaType: _groupCoreLoadedConductors,
      correctionTableReferences: ['Table 5-8', 'Table 5-43'],
    ),
    AmpacityTableMetadata(
      table: AmpacityTable.table521,
      tableId: '5-21',
      displayName: 'Table 5-21',
      category: 'Copper PVC/XLPE sheathed cable ampacity',
      conductorMaterial: 'Copper',
      insulationTypes: [CableInsulation.pvc, CableInsulation.xlpe],
      conductorTemperatureClasses: [
        ConductorTemperatureClass.pvc70,
        ConductorTemperatureClass.xlpeEpr90,
      ],
      referenceAmbientTemperatureC: 40,
      installationGroups: [],
      installationGroupNumbers: [3],
      applicableCableTypes: [],
      schemaType: AmpacityTableSchema.surfaceMountedCable,
      correctionTableReferences: ['Table 5-43'],
    ),
    AmpacityTableMetadata(
      table: AmpacityTable.table527,
      tableId: '5-27',
      displayName: 'Table 5-27',
      category: 'Copper insulated cable ampacity',
      conductorMaterial: 'Copper',
      insulationTypes: [CableInsulation.xlpe],
      conductorTemperatureClasses: [ConductorTemperatureClass.xlpeEpr90],
      referenceAmbientTemperatureC: 40,
      installationGroups: [
        InstallationMethod.group1,
        InstallationMethod.group2,
      ],
      installationGroupNumbers: [1, 2],
      applicableCableTypes: [CableType.iec605021],
      schemaType: _groupCoreLoadedConductors,
      correctionTableReferences: ['Table 5-8', 'Table 5-43'],
    ),
  ];

  AmpacityTableMetadata metadataFor(AmpacityTable table) {
    return tables.firstWhere((metadata) => metadata.table == table);
  }
}
