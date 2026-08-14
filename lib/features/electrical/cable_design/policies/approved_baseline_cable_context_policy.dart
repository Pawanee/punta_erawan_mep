import '../enums/ampacity_table.dart';
import '../enums/cable_type.dart';
import '../enums/conductor_temperature_class.dart';
import '../../voltage_drop/enums/cable_insulation.dart';
import '../../voltage_drop/models/cable_context.dart';
import 'cable_context_policy.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module  : Electrical
/// Feature : Cable Design
/// File    : approved_baseline_cable_context_policy.dart
///
/// OFOR-007C.7C.1
///
/// Description
/// ----------------------------------------------------------------------------
///
/// Approved baseline Cable Context Policy.
///
/// Current approved baseline:
///
///   CableType
///       ↓
///   PVC
///       ↓
///   70°C
///       ↓
///   Table 5-20
///
/// This policy intentionally does NOT:
/// - calculate ampacity;
/// - calculate voltage drop;
/// - apply grouping factors;
/// - apply ambient-temperature correction;
/// - select Table 5-27;
/// - infer XLPE from cable naming.
///
/// Table 5-27 / XLPE policy remains outside this implementation until the
/// corresponding CableType mapping is explicitly approved.
/// ============================================================================

class ApprovedBaselineCableContextPolicy
    implements CableContextPolicy {
  const ApprovedBaselineCableContextPolicy();

  /// Resolves the currently approved baseline context.
  ///
  /// The approved baseline defines all currently supported CableType values
  /// in the active baseline as PVC 70°C using Table 5-20.
  @override
  CableContext resolve(CableType cableType) {
    return CableContext(
      cableType: cableType,
      insulation: CableInsulation.pvc,
      temperatureClass: ConductorTemperatureClass.pvc70,
      ampacityTable: AmpacityTable.table520,
    );
  }
}