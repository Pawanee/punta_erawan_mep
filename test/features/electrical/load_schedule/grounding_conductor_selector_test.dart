import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/load_schedule/load_schedule.dart';

void main() {
  const selector = GroundingConductorSelector();

  group('Table 4-2 repository', () {
    const approvedThresholdsGolden = <double>[
      20,
      40,
      70,
      100,
      200,
      400,
      500,
      800,
      1000,
      1250,
      2000,
      2500,
      4000,
      6000,
    ];
    const approvedSizesGolden = <double>[
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
      185,
      240,
      400,
    ];

    test('contains all 14 frozen approved rows and source metadata', () {
      const repository = Table42GroundingRepository();
      final rows = repository.loadRows();

      expect(
        rows.map((row) => row.protectiveDeviceThresholdA),
        approvedThresholdsGolden,
      );
      expect(
        rows.map((row) => row.minimumGroundingConductorSizeSqmm),
        approvedSizesGolden,
      );
      expect(Table42GroundingRepository.tableId, '4-2');
      expect(
        Table42GroundingRepository.title,
        'ขนาดสายดินเล็กสุดของบริภัณฑ์ไฟฟ้า',
      );
      expect(
        Table42GroundingRepository.documentTitle,
        'คู่มือการติดตั้งระบบไฟฟ้าอย่างมืออาชีพ',
      );
      expect(Table42GroundingRepository.page, 113);
      expect(Table42GroundingRepository.version, 'table-4-2-v1');
    });

    test('every exact boundary selects its own row', () {
      const repository = Table42GroundingRepository();
      for (final row in repository.loadRows()) {
        final selectedRow = repository.selectCeiling(
          row.protectiveDeviceThresholdA,
        );
        expect(selectedRow, same(row));
        final result = selectedResult(
          ratedCurrentA: row.protectiveDeviceThresholdA,
          valueA: row.protectiveDeviceThresholdA,
          thresholdA: row.protectiveDeviceThresholdA,
          sizeSqmm: row.minimumGroundingConductorSizeSqmm,
        );
        expect(result.status, GroundingConductorSelectionStatus.selected);
      }
    });

    test(
      'repository applies ceiling and rejects invalid/out-of-range values',
      () {
        const repository = Table42GroundingRepository();
        expect(
          repository.selectCeiling(20.000001)!.protectiveDeviceThresholdA,
          40,
        );
        expect(repository.selectCeiling(6000), isNotNull);
        expect(repository.selectCeiling(6000.001), isNull);
        for (final value in [0.0, -1.0, double.nan, double.infinity]) {
          expect(() => repository.selectCeiling(value), throwsArgumentError);
        }
      },
    );
  });

  group('ceiling selection', () {
    test('below and equal to 20 A select 2.5 sq.mm', () {
      for (final value in [0.001, 6.0, 20.0]) {
        final result = selector.select(
          circuitStatus: CircuitStatus.active,
          circuitBreaker: activeBreaker(20),
          input: GroundingConductorSelectionInput(
            basis: ProtectiveDeviceCurrentBasis.adjustableTripSetting,
            ratedCurrentA: 20,
            adjustableTripSettingA: value,
          ),
        );
        expect(result.selectedTableThresholdA, 20);
        expect(result.groundingConductorSizeSqmm, 2.5);
      }
    });

    test('between rows selects the next threshold without interpolation', () {
      final result = selector.select(
        circuitStatus: CircuitStatus.active,
        circuitBreaker: activeBreaker(40),
        input: GroundingConductorSelectionInput(
          basis: ProtectiveDeviceCurrentBasis.adjustableTripSetting,
          ratedCurrentA: 40,
          adjustableTripSettingA: 20.000001,
        ),
      );

      expect(result.selectedTableThresholdA, 40);
      expect(result.groundingConductorSizeSqmm, 4);
    });

    test('6000 A is selected and greater than 6000 A is unsupported', () {
      expect(
        selectedResult(
          ratedCurrentA: 6000,
          valueA: 6000,
          thresholdA: 6000,
          sizeSqmm: 400,
        ).groundingConductorSizeSqmm,
        400,
      );

      final unsupported = selector.select(
        circuitStatus: CircuitStatus.active,
        circuitBreaker: activeBreaker(1600),
        input: GroundingConductorSelectionInput(
          basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
          ratedCurrentA: 6000.001,
        ),
      );
      expect(unsupported.status, GroundingConductorSelectionStatus.unsupported);

      expect(
        () => selectedResult(
          ratedCurrentA: 6000.001,
          valueA: 6000.001,
          thresholdA: 6000,
          sizeSqmm: 400,
        ),
        throwsArgumentError,
      );
    });
  });

  group('protective-device basis and validation', () {
    test('fixed rated current uses breaker In', () {
      final result = selector.select(
        circuitStatus: CircuitStatus.active,
        circuitBreaker: activeBreaker(63),
        input: GroundingConductorSelectionInput(
          basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
          ratedCurrentA: 63,
        ),
      );

      expect(result.protectiveDeviceValueA, 63);
      expect(result.selectedTableThresholdA, 70);
      expect(result.groundingConductorSizeSqmm, 6);
    });

    test('manual breaker selection does not imply adjustable trip', () {
      final breaker = activeBreaker(63, manual: true);
      final result = selector.select(
        circuitStatus: CircuitStatus.active,
        circuitBreaker: breaker,
        input: GroundingConductorSelectionInput(
          basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
          ratedCurrentA: 63,
        ),
      );

      expect(result.basis, ProtectiveDeviceCurrentBasis.ratedCurrent);
      expect(result.adjustableTripSettingA, isNull);
    });

    test('MCB/MCCB and automatic/manual modes use the explicit basis', () {
      for (final fixture in <({double rating, bool manual})>[
        (rating: 63, manual: false),
        (rating: 63, manual: true),
        (rating: 160, manual: false),
        (rating: 160, manual: true),
      ]) {
        final result = selector.select(
          circuitStatus: CircuitStatus.active,
          circuitBreaker: activeBreaker(fixture.rating, manual: fixture.manual),
          input: GroundingConductorSelectionInput(
            basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
            ratedCurrentA: fixture.rating,
          ),
        );
        expect(result.status, GroundingConductorSelectionStatus.selected);
        expect(result.protectiveDeviceValueA, fixture.rating);
        expect(result.adjustableTripSettingA, isNull);
      }
    });

    test('adjustable trip must be present, positive and not exceed In', () {
      expect(
        () => GroundingConductorSelectionInput(
          basis: ProtectiveDeviceCurrentBasis.adjustableTripSetting,
          ratedCurrentA: 100,
        ),
        throwsArgumentError,
      );
      for (final value in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => GroundingConductorSelectionInput(
            basis: ProtectiveDeviceCurrentBasis.adjustableTripSetting,
            ratedCurrentA: 100,
            adjustableTripSettingA: value,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => GroundingConductorSelectionInput(
          basis: ProtectiveDeviceCurrentBasis.adjustableTripSetting,
          ratedCurrentA: 100,
          adjustableTripSettingA: 100.01,
        ),
        throwsArgumentError,
      );
    });

    test('all numeric input fields reject NaN Infinity zero and negative', () {
      for (final value in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => GroundingConductorSelectionInput(
            basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
            ratedCurrentA: value,
          ),
          throwsArgumentError,
        );
        expect(
          () => GroundingConductorSelectionInput(
            basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
            ratedCurrentA: 20,
            phaseConductorSizeSqmm: value,
          ),
          throwsArgumentError,
        );
      }
    });

    test('breaker snapshot mismatch fails closed', () {
      final result = selector.select(
        circuitStatus: CircuitStatus.active,
        circuitBreaker: activeBreaker(63),
        input: GroundingConductorSelectionInput(
          basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
          ratedCurrentA: 50,
        ),
      );

      expect(result.status, GroundingConductorSelectionStatus.invalid);
      expect(result.reason, contains('does not match'));
    });
  });

  group('status and JSON boundaries', () {
    test('ACTIVE missing input or breaker fails closed', () {
      expect(
        selector
            .select(
              circuitStatus: CircuitStatus.active,
              circuitBreaker: activeBreaker(20),
            )
            .status,
        GroundingConductorSelectionStatus.insufficient,
      );
      expect(
        selector
            .select(
              circuitStatus: CircuitStatus.active,
              circuitBreaker: CircuitBreakerSelectionResult.notCalculated(),
              input: GroundingConductorSelectionInput(
                basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
                ratedCurrentA: 20,
              ),
            )
            .status,
        GroundingConductorSelectionStatus.insufficient,
      );
    });

    test('SPARE and SPACE are notCalculated without engineering values', () {
      for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
        final result = selector.select(
          circuitStatus: status,
          circuitBreaker: activeBreaker(20),
          input: GroundingConductorSelectionInput(
            basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
            ratedCurrentA: 20,
          ),
        );
        expect(result.status, GroundingConductorSelectionStatus.notCalculated);
        expect(result.ratedCurrentA, isNull);
        expect(result.sourceReferences, isEmpty);
      }
    });

    test('selected result and input round-trip through JSON', () {
      final input = GroundingConductorSelectionInput(
        basis: ProtectiveDeviceCurrentBasis.adjustableTripSetting,
        ratedCurrentA: 100,
        adjustableTripSettingA: 70,
        phaseConductorSizeSqmm: 25,
      );
      final decodedInput = GroundingConductorSelectionInput.fromJson(
        input.toJson(),
      );
      expect(decodedInput.toJson(), input.toJson());

      final result = selector.select(
        circuitStatus: CircuitStatus.active,
        circuitBreaker: activeBreaker(100),
        input: input,
      );
      final decodedResult = GroundingConductorSelectionResult.fromJson(
        result.toJson(),
      );
      expect(decodedResult.toJson(), result.toJson());
      expect(decodedResult.sourceReferences.single.tableId, '4-2');
      expect(
        decodedResult.sourceReferences.single.rowId,
        'protectiveDeviceThresholdA:70.0',
      );
    });

    test('contradictory selected JSON is rejected', () {
      final json = selectedResult(
        ratedCurrentA: 40,
        valueA: 40,
        thresholdA: 40,
        sizeSqmm: 4,
      ).toJson();

      for (final mutate in <void Function(Map<String, Object?>)>[
        (value) => value['protectiveDeviceValueA'] = 20,
        (value) => value['selectedTableThresholdA'] = 70,
        (value) => value['groundingConductorSizeSqmm'] = 6,
        (value) => value['tableId'] = '4-1',
        (value) => value['tableVersion'] = 'wrong',
        (value) => value['sourceReferences'] = <Object?>[],
        (value) => value['reason'] = 'Selected result cannot have a reason.',
      ]) {
        final malformed = Map<String, Object?>.from(json);
        mutate(malformed);
        expect(
          () => GroundingConductorSelectionResult.fromJson(malformed),
          throwsA(anything),
        );
      }
    });

    test('aggregate accepts matching ACTIVE grounding and round-trips', () {
      final result = activeAggregate(
        ground: selectedResult(
          ratedCurrentA: 20,
          valueA: 20,
          thresholdA: 20,
          sizeSqmm: 2.5,
        ),
      );

      expect(
        CircuitCalculationResult.fromJson(result.toJson()).toJson(),
        result.toJson(),
      );
    });

    test('aggregate rejects breaker mismatch and phase snapshot mismatch', () {
      expect(
        () => activeAggregate(
          ground: selectedResult(
            ratedCurrentA: 40,
            valueA: 40,
            thresholdA: 40,
            sizeSqmm: 4,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => activeAggregate(
          ground: GroundingConductorSelectionResult.selected(
            basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
            ratedCurrentA: 20,
            protectiveDeviceValueA: 20,
            selectedTableThresholdA: 20,
            groundingConductorSizeSqmm: 2.5,
            phaseConductorSizeSqmm: 4,
            sourceReferences: [groundingReference(20)],
          ),
        ),
        throwsArgumentError,
      );
    });

    test(
      'SPARE/SPACE require notCalculated at constructor and JSON boundary',
      () {
        for (final status in [CircuitStatus.spare, CircuitStatus.space]) {
          expect(
            () => nonActiveAggregate(
              status: status,
              ground: GroundingConductorSelectionResult.insufficient(
                reason: 'Contradictory result.',
              ),
            ),
            throwsArgumentError,
          );
          final valid = nonActiveAggregate(
            status: status,
            ground: GroundingConductorSelectionResult.notCalculated(),
          );
          final json = valid.toJson();
          json['ground'] = GroundingConductorSelectionResult.invalid(
            reason: 'Contradictory JSON.',
          ).toJson();
          expect(
            () => CircuitCalculationResult.fromJson(json),
            throwsArgumentError,
          );
        }
      },
    );
  });
}

CircuitBreakerSelectionResult activeBreaker(
  double ratedCurrentA, {
  bool manual = false,
}) => CircuitBreakerSelectionResult.selected(
  breakerType: ratedCurrentA <= 125 ? BreakerType.mcb : BreakerType.mccb,
  ratedCurrentA: ratedCurrentA,
  poleConfiguration: BreakerPoleConfiguration.oneP,
  selectionMode: manual
      ? BreakerSelectionMode.manual
      : BreakerSelectionMode.automatic,
  designCurrentIbA: 1,
  currentMarginA: ratedCurrentA - 1,
  manualOverrideReason: manual ? 'Approved manual selection.' : null,
  sourceReferences: [sourceReference()],
  catalogVersion: CircuitBreakerCatalog.version,
);

GroundingConductorSelectionResult selectedResult({
  required double ratedCurrentA,
  required double valueA,
  required double thresholdA,
  required double sizeSqmm,
}) => GroundingConductorSelectionResult.selected(
  basis: ProtectiveDeviceCurrentBasis.ratedCurrent,
  ratedCurrentA: ratedCurrentA,
  protectiveDeviceValueA: valueA,
  selectedTableThresholdA: thresholdA,
  groundingConductorSizeSqmm: sizeSqmm,
  sourceReferences: [groundingReference(thresholdA)],
);

CalculationSourceReference groundingReference(double thresholdA) =>
    CalculationSourceReference(
      sourceId: 'table-4-2-page-113',
      label: Table42GroundingRepository.title,
      tableId: Table42GroundingRepository.tableId,
      rowId: 'protectiveDeviceThresholdA:$thresholdA',
      sourceVersion: Table42GroundingRepository.version,
    );

CalculationSourceReference sourceReference() => CalculationSourceReference(
  sourceId: 'breaker-catalog-v1',
  label: 'Breaker catalog V1',
  sourceVersion: CircuitBreakerCatalog.version,
);

CircuitCalculationResult activeAggregate({
  required GroundingConductorSelectionResult ground,
}) => CircuitCalculationResult(
  circuitNo: 1,
  circuitStatus: CircuitStatus.active,
  phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
  validationStatus: CircuitValidationStatus.valid,
  assignedPhase: PhaseAssignment.r,
  current: CurrentCalculationResult.calculated(
    designCurrentA: 1,
    apparentPowerVa: 230,
    voltageBasis: VoltageBasis.lineToNeutral,
    voltageUsedV: 230,
    formulaId: CurrentFormulaId.directCurrentSinglePhase,
    sourceReferences: [sourceReference()],
  ),
  cable: CableCoordinationResult.notCalculated(),
  voltageDrop: VoltageDropCalculationResult.notCalculated(),
  circuitBreaker: activeBreaker(20),
  ground: ground,
  conduit: const PendingEngineeringResult.notCalculated(),
);

CircuitCalculationResult nonActiveAggregate({
  required CircuitStatus status,
  required GroundingConductorSelectionResult ground,
}) => CircuitCalculationResult(
  circuitNo: 2,
  circuitStatus: status,
  phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
  validationStatus: CircuitValidationStatus.valid,
  assignedPhase: status == CircuitStatus.spare ? PhaseAssignment.r : null,
  current: CurrentCalculationResult.notCalculated(),
  cable: CableCoordinationResult.notCalculated(),
  voltageDrop: VoltageDropCalculationResult.notCalculated(),
  circuitBreaker: CircuitBreakerSelectionResult.notCalculated(),
  ground: ground,
  conduit: const PendingEngineeringResult.notCalculated(),
);
