import '../../cable_design/policies/approved_cable_type_context_policy.dart';
import '../../cable_design/policies/cable_context_policy.dart';
import '../../cable_design/repositories/ampacity_repository.dart';
import '../../cable_design/services/grouping_factor_service.dart';
import '../../cable_design/services/temperature_factor_service.dart';
import '../models/voltage_drop_cable_selection_request.dart';
import '../models/voltage_drop_cable_selection_result.dart';
import 'voltage_drop_cable_selection_service.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module  : Electrical
/// Feature : Voltage Drop
/// File    : voltage_drop_cable_design_engine.dart
///
/// OFOR-007C.7B
///
/// Description
/// ----------------------------------------------------------------------------
///
/// Orchestration layer between Voltage Drop request and cable selection.
///
/// Engineering flow:
///
///   CableType
///      ↓
///   ApprovedCableTypeContextPolicy
///      ↓
///   CableContext
///      ↓
///   AmpacityTable
///      ↓
///   AmpacityRepository
///      ↓
///   CableTableRow
///      ↓
///   VoltageDropCableSelectionService
///
/// Approved ampacity sources:
///
///   PVC cable
///      → Table 5-20
///
///   IEC 60502-1 / XLPE
///      → Table 5-27
///
/// This engine does NOT:
/// - calculate ampacity;
/// - apply grouping factors;
/// - apply ambient-temperature correction;
/// - calculate voltage drop;
/// - modify Table 5-20 data;
/// - modify Table 5-27 data;
/// - modify the cable-selection algorithm.
/// ============================================================================

class VoltageDropCableDesignEngine {
  VoltageDropCableDesignEngine({
    AmpacityRepository? ampacityRepository,
    VoltageDropCableSelectionService? selectionService,
    CableContextPolicy? cableContextPolicy,
    GroupingFactorService? groupingFactorService,
    TemperatureFactorService? temperatureFactorService,
  })  : _ampacityRepository =
            ampacityRepository ?? AmpacityRepository(),
        _selectionService =
            selectionService ?? VoltageDropCableSelectionService(),
        _cableContextPolicy =
            cableContextPolicy ?? const ApprovedCableTypeContextPolicy(),
        _groupingFactorService =
            groupingFactorService ?? GroupingFactorService(),
        _temperatureFactorService =
            temperatureFactorService ?? TemperatureFactorService();

  final AmpacityRepository _ampacityRepository;
  final VoltageDropCableSelectionService _selectionService;
  final CableContextPolicy _cableContextPolicy;
  final GroupingFactorService _groupingFactorService;
  final TemperatureFactorService _temperatureFactorService;

  /// Designs cable selection using the approved CableType policy.
  ///
  /// The active ampacity table is determined by:
  ///
  ///   CableType
  ///      ↓
  ///   ApprovedCableTypeContextPolicy
  ///      ↓
  ///   CableContext.ampacityTable
  ///
  /// Therefore:
  ///
  ///   PVC cable     → Table 5-20
  ///   IEC 60502-1   → Table 5-27
  ///
  /// No ampacity correction or voltage-drop calculation is performed here.
  Future<VoltageDropCableSelectionResult> design(
    VoltageDropCableSelectionRequest request,
  ) async {
    try {
      final cableContext = _cableContextPolicy.resolve(
        request.cableRequest.cableType,
      );

      final groupingFactor = await _groupingFactorService.resolve(
        circuits: request.cableRequest.groupingCircuits,
        enclosed: request.cableRequest.installationMethod.name == 'group1',
      );

      if (groupingFactor == null) {
        return VoltageDropCableSelectionResult.error(
          'Grouping circuits are outside approved Table 5-8 coverage.',
        );
      }

      final temperatureFactor = await _temperatureFactorService.resolve(
        ambientTemperatureC: request.cableRequest.ambientTemperature,
        temperatureClass: cableContext.temperatureClass,
      );

      if (temperatureFactor == null) {
        return VoltageDropCableSelectionResult.error(
          'No approved Table 5-43 temperature factor is available.',
        );
      }

      final rows = await _ampacityRepository.loadTable(
        table: cableContext.ampacityTable,
        cableType: request.cableRequest.cableType,
      );

      if (rows.isEmpty) {
        return VoltageDropCableSelectionResult.error(
          'Ampacity reference table has no cable data.',
        );
      }

      return _selectionService.select(
        request: request,
        candidates: rows,
        groupingFactor: groupingFactor,
        temperatureFactor: temperatureFactor,
        conductorTemperatureClass: cableContext.temperatureClass,
      );
    } catch (e) {
      return VoltageDropCableSelectionResult.error(
        e.toString(),
      );
    }
  }
}
