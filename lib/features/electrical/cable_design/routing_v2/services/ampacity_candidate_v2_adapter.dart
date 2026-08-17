import '../../enums/conductor_temperature_class.dart';
import '../../enums/installation_method.dart';
import '../../models/cable_routing_identity.dart';
import '../../models/cable_table_row.dart';
import '../../models/table_5_21_data.dart';
import '../../models/table_5_27_row.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../models/ampacity_candidate_v2.dart';

/// Adapts published repository rows/cells into V2 candidates without copying
/// ampacity values, interpolation, or legacy identity requirements.
class AmpacityCandidateV2Adapter {
  const AmpacityCandidateV2Adapter();

  List<AmpacityCandidateV2> fromTable520({
    required List<CableTableRow> rows,
    required CableInsulation insulation,
    required ConductorTemperatureClass conductorTemperatureClass,
  }) => rows
      .map(
        (row) => AmpacityCandidateV2(
          sizeSqmm: row.cableSizeSqmm,
          baseAmpacity: row.baseAmpacity,
          sourceTableId: row.sourceTableId ?? '5-20',
          sourceTableDisplayName: row.sourceTableDisplayName ?? 'Table 5-20',
          sourceColumnId: null,
          installationGroupNumber: _groupNumber(row.installationMethod),
          loadedConductors: row.loadedConductors,
          coreType: row.coreType,
          insulation: insulation,
          conductorTemperatureClass: conductorTemperatureClass,
          applicableCableIdentities: {_identity(row.cableType.code)},
          sourceReferences: [row.reference],
        ),
      )
      .toList(growable: false);

  List<AmpacityCandidateV2> fromTable527({
    required List<Table527Row> rows,
    required CableInsulation insulation,
    required ConductorTemperatureClass conductorTemperatureClass,
    required CableRoutingIdentity routingCableIdentity,
  }) => rows
      .map(
        (row) => AmpacityCandidateV2(
          sizeSqmm: row.cableSizeSqmm,
          baseAmpacity: row.ampacity,
          sourceTableId: '5-27',
          sourceTableDisplayName: 'Table 5-27',
          sourceColumnId: null,
          installationGroupNumber: _groupNumber(row.installationMethod),
          loadedConductors: row.loadedConductors,
          coreType: row.coreType,
          insulation: insulation,
          conductorTemperatureClass: conductorTemperatureClass,
          applicableCableIdentities: {routingCableIdentity},
          sourceReferences: [Table527Row.reference],
        ),
      )
      .toList(growable: false);

  List<AmpacityCandidateV2> fromTable521({
    required Table521Data data,
    required String sourceColumnId,
  }) {
    final columns = data.columns.where((column) => column.id == sourceColumnId);
    if (columns.length != 1) return const [];
    final column = columns.single;
    final identities = column.applicableCableTypeCodes.map(_identity).toSet();
    return data.rows
        .map((row) => MapEntry(row, row.ampacityForColumn(sourceColumnId)))
        .where((entry) => entry.value != null)
        .map(
          (entry) => AmpacityCandidateV2(
            sizeSqmm: entry.key.sizeSqmm,
            baseAmpacity: entry.value!,
            sourceTableId: '5-21',
            sourceTableDisplayName: 'Table 5-21',
            sourceColumnId: sourceColumnId,
            installationGroupNumber: 3,
            loadedConductors: column.loadedConductors,
            coreType: column.coreType,
            insulation: column.insulation,
            conductorTemperatureClass: column.conductorTemperatureClass,
            applicableCableIdentities: identities,
            sourceReferences: const ['Table 5-21'],
          ),
        )
        .toList(growable: false);
  }

  int _groupNumber(InstallationMethod method) => switch (method) {
    InstallationMethod.group1 => 1,
    InstallationMethod.group2 => 2,
  };

  CableRoutingIdentity _identity(String code) => CableRoutingIdentity.values
      .singleWhere((identity) => identity.code == code);
}
