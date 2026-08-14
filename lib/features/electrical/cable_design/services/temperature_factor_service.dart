 import '../enums/conductor_temperature_class.dart';
import '../models/table_5_43_temperature_factor.dart';
import '../repositories/table_5_43_repository.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module  : Electrical
/// Feature : Cable Design
/// File    : temperature_factor_service.dart
///
/// OFOR-050
///
/// Description
/// ----------------------------------------------------------------------------
/// Service for resolving ambient-temperature correction factors
/// from Master Table 5-43.
///
/// Responsibilities:
/// - load Table 5-43 through the repository;
/// - locate the applicable ambient-temperature range;
/// - select the factor according to conductor temperature class.
///
/// This service does NOT:
/// - calculate ampacity;
/// - apply grouping factor;
/// - select cable size;
/// - calculate voltage drop;
/// - interpolate between table values;
/// - guess when the table has no approved factor.
/// ============================================================================

class TemperatureFactorService {
  TemperatureFactorService({
    Table543Repository? repository,
  }) : _repository = repository ?? Table543Repository();

  final Table543Repository _repository;

  /// Resolves the ambient-temperature correction factor.
  ///
  /// Returns null when:
  /// - the ambient temperature is outside Table 5-43;
  /// - the selected temperature class has no factor for that range.
  Future<double?> resolve({
    required double ambientTemperatureC,
    required ConductorTemperatureClass temperatureClass,
  }) async {
    final row = await _repository.findByAmbientTemperature(
      ambientTemperatureC,
    );

    if (row == null) {
      return null;
    }

    return row.factorFor(temperatureClass);
  }

  /// Resolves the complete Table 5-43 row.
  ///
  /// This method is useful when downstream calculation logic needs
  /// both the selected range and the factor.
  Future<Table543TemperatureFactor?> resolveRow({
    required double ambientTemperatureC,
  }) async {
    return _repository.findByAmbientTemperature(
      ambientTemperatureC,
    );
  }
}