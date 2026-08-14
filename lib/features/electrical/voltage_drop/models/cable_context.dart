 import '../../cable_design/enums/ampacity_table.dart';
import '../../cable_design/enums/cable_type.dart';
import '../../cable_design/enums/conductor_temperature_class.dart';
import '../enums/cable_insulation.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module  : Electrical
/// Feature : Voltage Drop
/// File    : cable_context.dart
///
/// OFOR-007C.7A
///
/// Description
/// ----------------------------------------------------------------------------
///
/// Engineering context for a selected cable.
///
/// This model contains reference-selection metadata only.
///
/// It does NOT:
/// - calculate ampacity;
/// - calculate voltage drop;
/// - apply grouping factors;
/// - apply ambient-temperature correction;
/// - decide CableType -> insulation mapping.
///
/// The actual CableType policy belongs to a separate policy layer.
/// ============================================================================

class CableContext {
  const CableContext({
    required this.cableType,
    required this.insulation,
    required this.temperatureClass,
    required this.ampacityTable,
  });

  /// Selected cable type.
  final CableType cableType;

  /// Insulation used by the voltage-drop reference tables.
  final CableInsulation insulation;

  /// Conductor temperature class used by the temperature-factor reference.
  final ConductorTemperatureClass temperatureClass;

  /// Ampacity reference table used for cable selection.
  final AmpacityTable ampacityTable;
}