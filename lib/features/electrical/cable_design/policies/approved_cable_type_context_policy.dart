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
/// File    : approved_cable_type_context_policy.dart
///
/// OFOR-007C.3
///
/// Approved CableType -> CableContext engineering policy.
///
/// Approved mapping:
///
/// 60227 IEC 01  -> PVC 70°C  -> Table 5-20
/// 60227 IEC 02  -> PVC 70°C  -> Table 5-20
/// 60227 IEC 05  -> PVC 70°C  -> Table 5-20
/// 60227 IEC 06  -> PVC 70°C  -> Table 5-20
/// 60227 IEC 10  -> PVC 70°C  -> Table 5-20
/// NYY          -> PVC 70°C  -> Table 5-20
/// NYY-G        -> PVC 70°C  -> Table 5-20
/// VCT          -> PVC 70°C  -> Table 5-20
/// VCT-G        -> PVC 70°C  -> Table 5-20
/// IEC 60502-1  -> XLPE 90°C -> Table 5-27
///
/// This policy contains engineering mapping only.
///
/// It does NOT:
/// - calculate ampacity;
/// - calculate voltage drop;
/// - apply grouping factors;
/// - apply temperature correction;
/// - modify reference JSON;
/// - select cable size;
/// - modify the active calculation flow.
/// ============================================================================

class ApprovedCableTypeContextPolicy implements CableContextPolicy {
  const ApprovedCableTypeContextPolicy();

  @override
  CableContext resolve(CableType cableType) {
    switch (cableType) {
      case CableType.iec01:
      case CableType.iec02:
      case CableType.iec05:
      case CableType.iec06:
      case CableType.iec10:
      case CableType.nyy:
      case CableType.nyyG:
      case CableType.vct:
      case CableType.vctG:
        return _pvc70Context(cableType);

      case CableType.iec605021:
        return _xlpe90Context(cableType);
    }
  }

  /// PVC 70°C baseline.
  ///
  /// Approved ampacity source:
  /// Table 5-20.
  CableContext _pvc70Context(CableType cableType) {
    return CableContext(
      cableType: cableType,
      insulation: CableInsulation.pvc,
      temperatureClass: ConductorTemperatureClass.pvc70,
      ampacityTable: AmpacityTable.table520,
    );
  }

  /// XLPE/EPR 90°C baseline.
  ///
  /// Approved ampacity source:
  /// Table 5-27.
  CableContext _xlpe90Context(CableType cableType) {
    return CableContext(
      cableType: cableType,
      insulation: CableInsulation.xlpe,
      temperatureClass: ConductorTemperatureClass.xlpeEpr90,
      ampacityTable: AmpacityTable.table527,
    );
  }
}