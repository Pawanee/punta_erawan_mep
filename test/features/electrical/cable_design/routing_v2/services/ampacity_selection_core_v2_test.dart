import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_20_repository.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_21_repository.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_27_repository.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_selection_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_candidate_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_correction_context_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/ampacity_selection_request_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/ampacity_candidate_v2_adapter.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/ampacity_selection_core_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/correction_resolver_v2.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const adapter = AmpacityCandidateV2Adapter();
  final core = AmpacitySelectionCoreV2();

  test(
    'selects smallest passing Table 5-21 source candidate with traceability',
    () async {
      final candidates = adapter.fromTable521(
        data: await Table521Repository().loadTable(),
        sourceColumnId: 'C1',
      );
      final result = await core.select(
        AmpacitySelectionRequestV2(
          loadCurrent: 56,
          candidates: candidates,
          correctionResolver: _FixedResolver(),
        ),
      );
      expect(result.status, AmpacitySelectionStatusV2.resolved);
      expect(result.selected!.candidate.sizeSqmm, 10);
      expect(result.selected!.candidate.baseAmpacity, 56);
      expect(result.selected!.candidate.sourceColumnId, 'C1');
      expect(result.selected!.runs, 1);
      expect(result.voltageDropVerified, isFalse);
    },
  );

  test(
    'unresolved corrections are insufficient while explicit 1.0 is valid',
    () async {
      final candidates = adapter.fromTable521(
        data: await Table521Repository().loadTable(),
        sourceColumnId: 'C1',
      );
      final missing = await core.select(
        AmpacitySelectionRequestV2(
          loadCurrent: 10,
          candidates: candidates,
          correctionResolver: _MissingResolver(),
        ),
      );
      final one = await core.select(
        AmpacitySelectionRequestV2(
          loadCurrent: 10,
          candidates: candidates,
          correctionResolver: _FixedResolver(),
        ),
      );
      expect(missing.status, AmpacitySelectionStatusV2.insufficient);
      expect(one.status, AmpacitySelectionStatusV2.resolved);
      expect(one.selected!.groupingFactor, 1.0);
    },
  );

  test('recalculates correction context for each parallel run', () async {
    final candidates = adapter.fromTable521(
      data: await Table521Repository().loadTable(),
      sourceColumnId: 'C1',
    );
    final resolver = _PerRunResolver();
    final result = await core.select(
      AmpacitySelectionRequestV2(
        loadCurrent: 70,
        candidates: candidates,
        correctionResolver: resolver,
      ),
    );
    expect(result.status, AmpacitySelectionStatusV2.resolved);
    expect(result.selected!.runs, 2);
    expect(result.selected!.currentPerRun, 35);
    expect(resolver.runs, containsAllInOrder([1, 2]));
  });

  test(
    'accepts repository-backed Table 5-20 and Table 5-27 candidates',
    () async {
      final table520 = adapter.fromTable520(
        rows: await Table520Repository().loadTable(cableType: CableType.iec01),
        insulation: CableInsulation.pvc,
        conductorTemperatureClass: ConductorTemperatureClass.pvc70,
      );
      final table527 = adapter.fromTable527(
        rows: await Table527Repository().loadTable(),
        insulation: CableInsulation.xlpe,
        conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
        routingCableIdentity: CableRoutingIdentity.iec605021,
      );
      expect(
        (await core.select(
          AmpacitySelectionRequestV2(
            loadCurrent: 1,
            candidates: table520,
            correctionResolver: _FixedResolver(),
          ),
        )).status,
        AmpacitySelectionStatusV2.resolved,
      );
      expect(
        (await core.select(
          AmpacitySelectionRequestV2(
            loadCurrent: 1,
            candidates: table527,
            correctionResolver: _FixedResolver(),
          ),
        )).status,
        AmpacitySelectionStatusV2.resolved,
      );
    },
  );
}

class _FixedResolver implements CorrectionResolverV2 {
  @override
  Future<AmpacityCorrectionContextV2> resolve(
    AmpacityCandidateV2 candidate,
    int runs,
  ) async => const AmpacityCorrectionContextV2(
    groupingFactor: 1,
    temperatureFactor: 1,
    groupingReference: 'test',
    temperatureReference: 'test',
  );
}

class _MissingResolver implements CorrectionResolverV2 {
  @override
  Future<AmpacityCorrectionContextV2> resolve(
    AmpacityCandidateV2 candidate,
    int runs,
  ) async => const AmpacityCorrectionContextV2();
}

class _PerRunResolver implements CorrectionResolverV2 {
  final runs = <int>[];
  @override
  Future<AmpacityCorrectionContextV2> resolve(
    AmpacityCandidateV2 candidate,
    int run,
  ) async {
    runs.add(run);
    return run == 1
        ? const AmpacityCorrectionContextV2()
        : const AmpacityCorrectionContextV2(
            groupingFactor: 1,
            temperatureFactor: 1,
          );
  }
}
