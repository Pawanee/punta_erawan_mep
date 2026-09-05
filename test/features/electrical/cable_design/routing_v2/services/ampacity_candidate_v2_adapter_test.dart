import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_20_repository.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_21_repository.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_27_repository.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/ampacity_candidate_v2_adapter.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const adapter = AmpacityCandidateV2Adapter();

  test('adapts Table 5-20 without a source column', () async {
    final rows = await Table520Repository().loadTable(
      cableType: CableType.iec01,
    );
    final candidates = adapter.fromTable520(
      rows: rows,
      insulation: CableInsulation.pvc,
      conductorTemperatureClass: ConductorTemperatureClass.pvc70,
    );
    final candidate = candidates.firstWhere(
      (candidate) =>
          candidate.sizeSqmm == 4 &&
          candidate.installationGroupNumber == 1 &&
          candidate.loadedConductors == 2 &&
          candidate.coreType == CoreType.singleCore,
    );

    expect(candidate.baseAmpacity, 23);
    expect(candidate.sourceTableId, '5-20');
    expect(candidate.sourceColumnId, isNull);
  });

  test('adapts Table 5-27 with explicit XLPE metadata', () async {
    final candidates = adapter.fromTable527(
      rows: await Table527Repository().loadTable(),
      insulation: CableInsulation.xlpe,
      conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
      routingCableIdentity: CableRoutingIdentity.iec605021,
    );
    final candidate = candidates.firstWhere(
      (candidate) =>
          candidate.sizeSqmm == 4 &&
          candidate.installationGroupNumber == 1 &&
          candidate.loadedConductors == 2 &&
          candidate.coreType == CoreType.singleCore,
    );

    expect(candidate.baseAmpacity, 32);
    expect(candidate.sourceColumnId, isNull);
    expect(candidate.insulation, CableInsulation.xlpe);
    expect(
      candidate.conductorTemperatureClass,
      ConductorTemperatureClass.xlpeEpr90,
    );
  });

  test('adapts Table 5-21 C1 faithfully without legacy identities', () async {
    final candidates = adapter.fromTable521(
      data: await Table521Repository().loadTable(),
      sourceColumnId: 'C1',
    );
    final candidate = candidates.firstWhere(
      (candidate) => candidate.sizeSqmm == 10,
    );

    expect(candidate.baseAmpacity, 56);
    expect(candidate.installationGroupNumber, 3);
    expect(candidate.sourceColumnId, 'C1');
    expect(candidate.applicableCableIdentities, {
      CableRoutingIdentity.vaf,
      CableRoutingIdentity.vafG,
    });
  });

  test(
    'omits unavailable Table 5-21 cells and preserves source row ordering',
    () async {
      final candidates = adapter.fromTable521(
        data: await Table521Repository().loadTable(),
        sourceColumnId: 'C1',
      );

      expect(
        candidates.map((candidate) => candidate.sizeSqmm),
        orderedEquals([1, 1.5, 2.5, 4, 6, 10, 16]),
      );
      expect(candidates.any((candidate) => candidate.sizeSqmm == 25), isFalse);
    },
  );

  test('preserves all independently published Table 5-21 columns', () async {
    final data = await Table521Repository().loadTable();
    for (final column in data.columns) {
      final candidates = adapter.fromTable521(
        data: data,
        sourceColumnId: column.id,
      );
      expect(candidates, isNotEmpty, reason: column.id);
      expect(
        candidates.every((candidate) => candidate.sourceColumnId == column.id),
        isTrue,
      );
    }
  });

  test(
    'C8/C9 omit null cells and preserve all 17 source-ordered candidates',
    () async {
      final data = await Table521Repository().loadTable();
      for (final columnId in ['C8', 'C9']) {
        final candidates = adapter.fromTable521(
          data: data,
          sourceColumnId: columnId,
        );
        expect(candidates, hasLength(17));
        expect(
          candidates.map((candidate) => candidate.sizeSqmm),
          orderedEquals([
            1,
            1.5,
            2.5,
            4,
            6,
            10,
            16,
            25,
            35,
            50,
            70,
            95,
            120,
            150,
            185,
            240,
            300,
          ]),
        );
        expect(
          candidates.any((candidate) => candidate.sizeSqmm == 400),
          isFalse,
        );
        expect(
          candidates.any((candidate) => candidate.sizeSqmm == 500),
          isFalse,
        );
      }
    },
  );
}
