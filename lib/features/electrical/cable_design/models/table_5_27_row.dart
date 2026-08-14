import '../enums/core_type.dart';
import '../enums/installation_method.dart';

/// One row of Master Table 5-27.
///
/// The table is the XLPE ampacity source at 40°C ambient and 90°C conductor
/// temperature. This model stores reference data only; it does not apply
/// grouping or ambient correction factors.
class Table527Row {
  static const String reference = 'Table 5-27';
  static const int conductorTemperatureC = 90;
  static const int ambientTemperatureC = 40;

  final double cableSizeSqmm;
  final InstallationMethod installationMethod;
  final int loadedConductors;
  final CoreType coreType;
  final double ampacity;

  const Table527Row({
    required this.cableSizeSqmm,
    required this.installationMethod,
    required this.loadedConductors,
    required this.coreType,
    required this.ampacity,
  });

  factory Table527Row.fromJson({
    required Map<String, dynamic> json,
    required InstallationMethod installationMethod,
    required int loadedConductors,
    required CoreType coreType,
  }) {
    final value = (((json[installationMethod.name] as Map<String, dynamic>)[
        loadedConductors == 2 ? 'twoLoaded' : 'threeLoaded']
      as Map<String, dynamic>)[coreType == CoreType.singleCore
        ? 'singleCore'
        : 'multiCore']);

    if (value == null) {
      throw StateError(
        'Table 5-27 has no ampacity for '
        '${installationMethod.name}, '
        '$loadedConductors loaded conductors, '
        '${coreType.name}, '
        '${json['sizeSqmm']} sq.mm.',
      );
    }

    return Table527Row(
      cableSizeSqmm: (json['sizeSqmm'] as num).toDouble(),
      installationMethod: installationMethod,
      loadedConductors: loadedConductors,
      coreType: coreType,
      ampacity: (value as num).toDouble(),
    );
  }
}
