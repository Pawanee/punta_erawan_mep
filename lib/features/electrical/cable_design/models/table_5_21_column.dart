import '../enums/cable_shape.dart';
import '../enums/conductor_temperature_class.dart';
import '../enums/core_type.dart';
import '../enums/electrical_system_applicability.dart';
import '../../voltage_drop/enums/cable_insulation.dart';

/// One independently published source column in Master Table 5-21.
class Table521Column {
  const Table521Column({
    required this.id,
    required this.cableShape,
    required this.coreType,
    required this.insulation,
    required this.conductorTemperatureClass,
    required this.loadedConductors,
    required this.systemApplicability,
    required this.applicableCableTypeCodes,
  });

  final String id;
  final CableShape cableShape;
  final CoreType coreType;
  final CableInsulation insulation;
  final ConductorTemperatureClass conductorTemperatureClass;
  final int loadedConductors;
  final ElectricalSystemApplicability systemApplicability;

  /// Exact cable-type codes stated by the source column, if any.
  final List<String> applicableCableTypeCodes;
}
