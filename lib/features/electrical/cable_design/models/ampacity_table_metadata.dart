import '../enums/ampacity_table.dart';
import '../enums/ampacity_table_schema.dart';
import '../enums/cable_type.dart';
import '../enums/conductor_temperature_class.dart';
import '../enums/installation_method.dart';
import '../../voltage_drop/enums/cable_insulation.dart';

/// Describes the applicability and structure of a published ampacity table.
///
/// This model deliberately contains no ampacity values. Engineering values
/// remain in the table-specific JSON assets and repositories.
class AmpacityTableMetadata {
  const AmpacityTableMetadata({
    required this.table,
    required this.tableId,
    required this.displayName,
    required this.category,
    required this.conductorMaterial,
    required this.insulationTypes,
    required this.conductorTemperatureClasses,
    required this.referenceAmbientTemperatureC,
    required this.installationGroups,
    required this.applicableCableTypes,
    required this.schemaType,
    required this.correctionTableReferences,
  });

  final AmpacityTable table;
  final String tableId;
  final String displayName;
  final String category;
  final String conductorMaterial;
  final List<CableInsulation> insulationTypes;
  final List<ConductorTemperatureClass> conductorTemperatureClasses;
  final int referenceAmbientTemperatureC;
  final List<InstallationMethod> installationGroups;
  final List<CableType> applicableCableTypes;
  final AmpacityTableSchema schemaType;
  final List<String> correctionTableReferences;
}
