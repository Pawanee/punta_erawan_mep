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
/// File    : approved_xlpe_cable_context_policy.dart
///
/// OFOR-007C.7C.2
///
/// Description
/// ----------------------------------------------------------------------------
///
/// Approved XLPE cable context policy.
///
/// Current approved reference context:
///
///   XLPE/EPR
///       ↓
///   90°C
///       ↓
///   Table 5-27
///
/// This policy defines reference context only.
///
/// It does NOT:
/// - map any CableType to XLPE;
/// - calculate ampacity;
/// - calculate voltage drop;
/// - apply grouping factors;
/// - apply ambient-temperature correction;
/// - modify Table 5-27 data;
/// - modify the active cable-selection flow.
///
/// CableType-to-XLPE mapping must be approved separately.
/// ============================================================================

class ApprovedXlpeCableContextPolicy implements CableContextPolicy {
  const ApprovedXlpeCableContextPolicy();

  /// Returns the approved XLPE/EPR 90°C context using Table 5-27.
  ///
  /// [cableType] is carried as context metadata only.
  ///
  /// This method does not imply that the supplied CableType is an XLPE cable.
  /// The actual CableType-to-insulation mapping remains a separate
  /// engineering-policy decision.
  @override
  CableContext resolve(CableType cableType) {
    return CableContext(
      cableType: cableType,
      insulation: CableInsulation.xlpe,
      temperatureClass: ConductorTemperatureClass.xlpeEpr90,
      ampacityTable: AmpacityTable.table527,
    );
  }
}