import '../../enums/electrical_system_applicability.dart';
import '../../repositories/table_5_21_repository.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/routing_electrical_system.dart';
import '../models/ampacity_routing_context.dart';
import '../models/table_521_column_resolution.dart';

/// Resolves Table 5-21's published C1-C9 headers without holding ampacity data.
class Table521ColumnResolver {
  Table521ColumnResolver({Table521Repository? repository})
    : _repository = repository ?? Table521Repository();
  final Table521Repository _repository;

  Future<Table521ColumnResolution> resolve(
    AmpacityRoutingContext context,
  ) async {
    final missing = <String>[];
    if (context.cableShape == null) missing.add('cableShape');
    if (context.coreType == null) missing.add('coreType');
    if (context.insulation == null) missing.add('insulation');
    if (context.conductorTemperatureClass == null)
      missing.add('conductorTemperatureClass');
    if (missing.isNotEmpty)
      return Table521ColumnResolution(
        status: AmpacityRoutingStatus.insufficient,
        columnId: null,
        reason: 'Required Table 5-21 dimensions are unavailable.',
        missingDimensions: missing,
        candidates: [],
      );

    final columns = (await _repository.loadTable()).columns
        .where((column) {
          return column.cableShape == context.cableShape &&
              column.coreType == context.coreType &&
              column.insulation == context.insulation &&
              column.conductorTemperatureClass ==
                  context.conductorTemperatureClass &&
              column.loadedConductors == context.loadedConductors &&
              _systemMatches(
                context.electricalSystem,
                column.systemApplicability,
              ) &&
              column.applicableCableTypeCodes.contains(context.cableType.code);
        })
        .toList(growable: false);
    if (columns.isEmpty)
      return const Table521ColumnResolution(
        status: AmpacityRoutingStatus.noMatch,
        columnId: null,
        reason: 'No Table 5-21 source column matches the supplied facts.',
        missingDimensions: [],
        candidates: [],
      );
    if (columns.length > 1)
      return Table521ColumnResolution(
        status: AmpacityRoutingStatus.ambiguous,
        columnId: null,
        reason: 'More than one Table 5-21 source column matches.',
        missingDimensions: [],
        candidates: columns.map((column) => column.id).toList(),
      );
    return Table521ColumnResolution(
      status: AmpacityRoutingStatus.resolved,
      columnId: columns.single.id,
      reason: null,
      missingDimensions: const [],
      candidates: const [],
    );
  }

  bool _systemMatches(
    RoutingElectricalSystem system,
    ElectricalSystemApplicability source,
  ) =>
      source == ElectricalSystemApplicability.acDc ||
      system != RoutingElectricalSystem.dc;
}
