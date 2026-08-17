import '../../enums/ampacity_table.dart';
import '../../enums/cable_type.dart';
import '../../registries/ampacity_table_registry.dart';
import '../enums/ampacity_routing_status.dart';
import '../models/ampacity_routing_context.dart';
import '../models/table_521_column_resolution.dart';
import 'table_521_column_resolver.dart';

class AmpacityTableResolution {
  const AmpacityTableResolution({
    required this.status,
    required this.table,
    required this.column,
    required this.reason,
    required this.missingDimensions,
    required this.candidates,
  });
  final AmpacityRoutingStatus status;
  final AmpacityTable? table;
  final Table521ColumnResolution? column;
  final String? reason;
  final List<String> missingDimensions;
  final List<String> candidates;
}

/// Parallel metadata and source-header resolver; it never reads ampacity values.
class AmpacityTableResolver {
  AmpacityTableResolver({
    AmpacityTableRegistry? registry,
    Table521ColumnResolver? table521ColumnResolver,
  }) : _registry = registry ?? const AmpacityTableRegistry(),
       _table521ColumnResolver =
           table521ColumnResolver ?? Table521ColumnResolver();
  final AmpacityTableRegistry _registry;
  final Table521ColumnResolver _table521ColumnResolver;

  Future<AmpacityTableResolution> resolve(
    AmpacityRoutingContext context,
  ) async {
    final group = context.installationResolution.reference!.group;
    if (group == 3) {
      final column = await _table521ColumnResolver.resolve(context);
      return AmpacityTableResolution(
        status: column.status,
        table: column.status == AmpacityRoutingStatus.resolved
            ? AmpacityTable.table521
            : null,
        column: column,
        reason: column.reason,
        missingDimensions: column.missingDimensions,
        candidates: column.candidates,
      );
    }
    final missing = <String>[];
    if (context.insulation == null) missing.add('insulation');
    if (context.conductorTemperatureClass == null) {
      missing.add('conductorTemperatureClass');
    }
    if (missing.isNotEmpty) {
      return AmpacityTableResolution(
        status: AmpacityRoutingStatus.insufficient,
        table: null,
        column: null,
        reason:
            'Table compatibility requires insulation and temperature class.',
        missingDimensions: missing,
        candidates: const [],
      );
    }
    final candidates = AmpacityTableRegistry.tables
        .where((metadata) {
          return metadata.installationGroupNumbers.contains(group) &&
              metadata.applicableCableTypes.any(
                (type) => type.code == context.cableType.code,
              ) &&
              context.insulation != null &&
              metadata.insulationTypes.contains(context.insulation) &&
              context.conductorTemperatureClass != null &&
              metadata.conductorTemperatureClasses.contains(
                context.conductorTemperatureClass,
              );
        })
        .toList(growable: false);
    if (candidates.length == 1)
      return AmpacityTableResolution(
        status: AmpacityRoutingStatus.resolved,
        table: candidates.single.table,
        column: null,
        reason: null,
        missingDimensions: const [],
        candidates: const [],
      );
    if (candidates.length > 1)
      return AmpacityTableResolution(
        status: AmpacityRoutingStatus.ambiguous,
        table: null,
        column: null,
        reason: 'Multiple ampacity tables match.',
        missingDimensions: const [],
        candidates: candidates.map((metadata) => metadata.tableId).toList(),
      );
    final hasCableCompatibility = AmpacityTableRegistry.tables.any(
      (metadata) =>
          metadata.installationGroupNumbers.contains(group) &&
          metadata.applicableCableTypes.any(
            (type) => type.code == context.cableType.code,
          ),
    );
    return AmpacityTableResolution(
      status: hasCableCompatibility
          ? AmpacityRoutingStatus.noMatch
          : AmpacityRoutingStatus.unsupported,
      table: null,
      column: null,
      reason:
          'No approved table is available for the resolved installation context.',
      missingDimensions: const [],
      candidates: const [],
    );
  }
}
