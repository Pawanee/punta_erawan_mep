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
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/ampacity_correction_plan_resolver_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/resolved_correction_state_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/resolved_correction_application_v2.dart';
import 'package:mep_project/features/electrical/cable_design/services/temperature_factor_service.dart';
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
    'applied, not-required, and unresolved correction states stay distinct',
    () async {
      final candidates = adapter.fromTable521(
        data: await Table521Repository().loadTable(),
        sourceColumnId: 'C1',
      );
      final applied = await core.select(
        AmpacitySelectionRequestV2(
          loadCurrent: 50,
          candidates: candidates,
          correctionResolver: _ApplicationResolver(
            const ResolvedCorrectionApplicationV2.applied(0.91, 'Table 5-43'),
            const ResolvedCorrectionApplicationV2.notRequired(
              'source',
              'Table 5-21',
            ),
          ),
        ),
      );
      final notRequired = await core.select(
        AmpacitySelectionRequestV2(
          loadCurrent: 50,
          candidates: candidates,
          correctionResolver: _ApplicationResolver(
            const ResolvedCorrectionApplicationV2.notRequired(
              'reference ambient',
              'Table 5-21',
            ),
            const ResolvedCorrectionApplicationV2.notRequired(
              'source',
              'Table 5-21',
            ),
          ),
        ),
      );
      final unresolved = await core.select(
        AmpacitySelectionRequestV2(
          loadCurrent: 10,
          candidates: candidates,
          correctionResolver: _ApplicationResolver(
            const ResolvedCorrectionApplicationV2.unresolved('missing'),
            const ResolvedCorrectionApplicationV2.notRequired(
              'source',
              'Table 5-21',
            ),
          ),
        ),
      );
      expect(applied.selected!.correctedAmpacityPerRun, closeTo(50.96, 0.0001));
      expect(
        applied.selected!.temperatureApplication.state,
        ResolvedCorrectionStateV2.applied,
      );
      expect(applied.selected!.temperatureApplication.factor, 0.91);
      expect(notRequired.selected!.correctedAmpacityPerRun, 56);
      expect(notRequired.selected!.temperatureFactor, isNull);
      expect(
        notRequired.selected!.temperatureApplication.state,
        ResolvedCorrectionStateV2.notRequired,
      );
      expect(unresolved.status, AmpacitySelectionStatusV2.insufficient);
      expect(unresolved.selected, isNull);
    },
  );

  test(
    'Table 5-21 40C and 45C plans preserve correction traceability',
    () async {
      final candidates = adapter
          .fromTable521(
            data: await Table521Repository().loadTable(),
            sourceColumnId: 'C1',
          )
          .where((c) => c.sizeSqmm == 10)
          .toList();
      const plans = AmpacityCorrectionPlanResolverV2();
      final at40 = await core.select(
        AmpacitySelectionRequestV2(
          loadCurrent: 56,
          candidates: candidates,
          correctionResolver: _ApplicationResolver(
            const ResolvedCorrectionApplicationV2.notRequired(
              'ambient equals reference',
              'Table 5-21',
            ),
            const ResolvedCorrectionApplicationV2.notRequired(
              'not required by source',
              'Table 5-21',
            ),
          ),
        ),
      );
      final factor = await TemperatureFactorService().resolve(
        ambientTemperatureC: 45,
        temperatureClass: ConductorTemperatureClass.pvc70,
      );
      final at45 = await core.select(
        AmpacitySelectionRequestV2(
          loadCurrent: 1,
          candidates: candidates,
          correctionResolver: _ApplicationResolver(
            ResolvedCorrectionApplicationV2.applied(factor!, 'Table 5-43'),
            const ResolvedCorrectionApplicationV2.notRequired(
              'not required by source',
              'Table 5-21',
            ),
          ),
        ),
      );
      expect(
        plans
            .resolve(sourceTableId: '5-21', ambientTemperatureC: 45)
            .requirements
            .first
            .correctionTableId,
        '5-43',
      );
      expect(at40.selected!.correctedAmpacityPerRun, 56);
      expect(at40.selected!.temperatureFactor, isNull);
      expect(at40.selected!.groupingFactor, isNull);
      expect(
        at45.selected!.temperatureApplication.sourceReference,
        'Table 5-43',
      );
      expect(
        at45.selected!.correctedAmpacityPerRun,
        closeTo(56 * factor, 0.0001),
      );
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

class _ApplicationResolver implements CorrectionResolverV2 {
  const _ApplicationResolver(this.temperature, this.grouping);
  final ResolvedCorrectionApplicationV2 temperature;
  final ResolvedCorrectionApplicationV2 grouping;
  @override
  Future<AmpacityCorrectionContextV2> resolve(
    AmpacityCandidateV2 candidate,
    int runs,
  ) async => AmpacityCorrectionContextV2(
    temperatureApplication: temperature,
    groupingApplication: grouping,
  );
}
