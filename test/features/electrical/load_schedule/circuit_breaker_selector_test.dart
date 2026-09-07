import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/load_schedule/load_schedule.dart';

void main() {
  const selector = CircuitBreakerSelector();

  group('approved catalogs and automatic boundaries', () {
    test('catalog V1 contains exactly the approved ratings', () {
      expect(CircuitBreakerCatalog.version, 'load-schedule-cb-catalog-v1');
      expect(CircuitBreakerCatalog.mcbRatingsA, const [
        6,
        10,
        16,
        20,
        25,
        32,
        40,
        50,
        63,
        80,
        100,
        125,
      ]);
      expect(CircuitBreakerCatalog.mccbRatingsA, const [
        16,
        20,
        25,
        32,
        40,
        50,
        63,
        80,
        100,
        125,
        160,
        200,
        225,
        250,
        315,
        400,
        500,
        630,
        800,
        1000,
        1250,
        1600,
      ]);
    });

    for (final type in BreakerType.values) {
      final ratings = CircuitBreakerCatalog.ratingsFor(type);

      test('${type.name} exact ratings select the same rating', () {
        for (final rating in ratings) {
          final result = selector.select(
            circuit: activeCircuit(),
            current: calculatedCurrent(rating),
            input: automaticInput(type),
          );
          expect(result.status, CircuitBreakerSelectionStatus.selected);
          expect(result.ratedCurrentA, rating);
        }
      });

      test('${type.name} just above a boundary selects the next rating', () {
        for (var index = 0; index < ratings.length - 1; index++) {
          final result = selector.select(
            circuit: activeCircuit(),
            current: calculatedCurrent(ratings[index] + 1e-6),
            input: automaticInput(type),
          );
          expect(result.ratedCurrentA, ratings[index + 1]);
        }
      });

      test('${type.name} below minimum selects the minimum', () {
        final result = selector.select(
          circuit: activeCircuit(),
          current: calculatedCurrent(0.5),
          input: automaticInput(type),
        );
        expect(result.ratedCurrentA, ratings.first);
      });

      test('${type.name} above maximum returns noMatch', () {
        final result = selector.select(
          circuit: activeCircuit(),
          current: calculatedCurrent(ratings.last + 1e-6),
          input: automaticInput(type),
        );
        expect(result.status, CircuitBreakerSelectionStatus.noMatch);
        expect(result.breakerType, isNull);
        expect(result.ratedCurrentA, isNull);
      });
    }

    test('MCB never falls back to MCCB', () {
      final result = selector.select(
        circuit: activeCircuit(),
        current: calculatedCurrent(126),
        input: automaticInput(BreakerType.mcb),
      );
      expect(result.status, CircuitBreakerSelectionStatus.noMatch);
      expect(result.breakerType, isNull);
    });

    test('selection uses raw Ib without rounding', () {
      final result = selector.select(
        circuit: activeCircuit(),
        current: calculatedCurrent(16.0000000001),
        input: automaticInput(BreakerType.mcb),
      );
      expect(result.ratedCurrentA, 20);
    });
  });

  group('phase and pole configuration', () {
    test('single-phase defaults to 1P', () {
      final result = selector.select(
        circuit: activeCircuit(),
        current: calculatedCurrent(10),
        input: automaticInput(BreakerType.mcb),
      );
      expect(result.poleConfiguration, BreakerPoleConfiguration.oneP);
    });

    test('three-phase defaults to 3P', () {
      final result = selector.select(
        circuit: activeCircuit(threePhase: true),
        current: calculatedCurrent(10, threePhase: true),
        input: automaticInput(BreakerType.mccb),
      );
      expect(result.poleConfiguration, BreakerPoleConfiguration.threeP);
    });

    test('1P+N, 2P, and 4P approved manual pole choices are accepted', () {
      for (final pole in [
        BreakerPoleConfiguration.onePPlusN,
        BreakerPoleConfiguration.twoP,
      ]) {
        expect(
          selector
              .select(
                circuit: activeCircuit(),
                current: calculatedCurrent(10),
                input: automaticInput(BreakerType.mcb, pole: pole),
              )
              .status,
          CircuitBreakerSelectionStatus.selected,
        );
      }
      expect(
        selector
            .select(
              circuit: activeCircuit(threePhase: true),
              current: calculatedCurrent(10, threePhase: true),
              input: automaticInput(
                BreakerType.mccb,
                pole: BreakerPoleConfiguration.fourP,
              ),
            )
            .status,
        CircuitBreakerSelectionStatus.selected,
      );
    });

    test('phase-incompatible poles fail closed', () {
      final single = selector.select(
        circuit: activeCircuit(),
        current: calculatedCurrent(10),
        input: automaticInput(
          BreakerType.mcb,
          pole: BreakerPoleConfiguration.threeP,
        ),
      );
      final three = selector.select(
        circuit: activeCircuit(threePhase: true),
        current: calculatedCurrent(10, threePhase: true),
        input: automaticInput(
          BreakerType.mccb,
          pole: BreakerPoleConfiguration.twoP,
        ),
      );
      expect(single.status, CircuitBreakerSelectionStatus.invalid);
      expect(three.status, CircuitBreakerSelectionStatus.invalid);
    });
  });

  group('manual and circuit status rules', () {
    test('ACTIVE manual rating below Ib is invalid', () {
      final result = selector.select(
        circuit: activeCircuit(),
        current: calculatedCurrent(20.1),
        input: manualInput(BreakerType.mcb, 20),
      );
      expect(result.status, CircuitBreakerSelectionStatus.invalid);
    });

    test('manual rating outside selected catalog is invalid', () {
      final result = selector.select(
        circuit: activeCircuit(),
        current: calculatedCurrent(10),
        input: manualInput(BreakerType.mcb, 15),
      );
      expect(result.status, CircuitBreakerSelectionStatus.invalid);
    });

    test(
      'ACTIVE manual reason is mandatory and optional fields are validated',
      () {
        final missingReason = selector.select(
          circuit: activeCircuit(),
          current: calculatedCurrent(10),
          input: CircuitBreakerSelectionInput(
            selectionMode: BreakerSelectionMode.manual,
            breakerType: BreakerType.mcb,
            ratedCurrentA: 16,
          ),
        );
        expect(missingReason.status, CircuitBreakerSelectionStatus.invalid);
        expect(
          () => CircuitBreakerSelectionInput(
            selectionMode: BreakerSelectionMode.manual,
            breakerType: BreakerType.mcb,
            ratedCurrentA: 16,
            manualOverrideReason: ' ',
          ),
          throwsArgumentError,
        );
        for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
          expect(
            () => CircuitBreakerSelectionInput(
              selectionMode: BreakerSelectionMode.manual,
              breakerType: BreakerType.mcb,
              ratedCurrentA: 16,
              manualOverrideReason: 'Approved override',
              breakingCapacityKa: invalid,
            ),
            throwsArgumentError,
          );
        }
        expect(
          () => CircuitBreakerSelectionInput(
            selectionMode: BreakerSelectionMode.manual,
            breakerType: BreakerType.mcb,
            ratedCurrentA: 16,
            manualOverrideReason: 'Approved override',
            tripCurveDesignation: '',
          ),
          throwsArgumentError,
        );
      },
    );

    test('valid SPARE stores manual breaker without Ib or coordination', () {
      final result = selector.select(
        circuit: spareCircuit(),
        current: CurrentCalculationResult.notCalculated(),
        input: manualInput(
          BreakerType.mcb,
          16,
          pole: BreakerPoleConfiguration.twoP,
          includeReason: false,
        ),
      );
      expect(result.status, CircuitBreakerSelectionStatus.selected);
      expect(result.designCurrentIbA, isNull);
      expect(result.currentMarginA, isNull);
      expect(result.cableCoordinationStatus, isNull);
    });

    test('SPARE automatic and non-catalog manual inputs fail closed', () {
      final automatic = selector.select(
        circuit: spareCircuit(),
        current: CurrentCalculationResult.notCalculated(),
        input: automaticInput(BreakerType.mcb),
      );
      final invalidManual = selector.select(
        circuit: spareCircuit(),
        current: CurrentCalculationResult.notCalculated(),
        input: manualInput(
          BreakerType.mcb,
          15,
          pole: BreakerPoleConfiguration.oneP,
          includeReason: false,
        ),
      );
      final missingPole = selector.select(
        circuit: spareCircuit(),
        current: CurrentCalculationResult.notCalculated(),
        input: manualInput(BreakerType.mcb, 16, includeReason: false),
      );
      expect(automatic.status, CircuitBreakerSelectionStatus.insufficient);
      expect(invalidManual.status, CircuitBreakerSelectionStatus.invalid);
      expect(missingPole.status, CircuitBreakerSelectionStatus.insufficient);
    });

    test('SPACE has no engineering values', () {
      final result = selector.select(
        circuit: spaceCircuit(),
        current: CurrentCalculationResult.notCalculated(),
        input: manualInput(BreakerType.mcb, 16),
      );
      expect(result.status, CircuitBreakerSelectionStatus.notCalculated);
      expect(result.breakerType, isNull);
      expect(result.ratedCurrentA, isNull);
      expect(result.sourceReferences, isEmpty);
    });
  });

  group('fail-closed result and JSON boundary', () {
    test('missing or unresolved current is invalid for ACTIVE', () {
      for (final current in [
        CurrentCalculationResult.notCalculated(),
        CurrentCalculationResult.insufficient(reason: 'missing voltage'),
        CurrentCalculationResult.invalid(reason: 'invalid load'),
      ]) {
        final result = selector.select(
          circuit: activeCircuit(),
          current: current,
          input: automaticInput(BreakerType.mcb),
        );
        expect(result.status, CircuitBreakerSelectionStatus.invalid);
      }
      final missingInput = selector.select(
        circuit: activeCircuit(),
        current: calculatedCurrent(10),
      );
      expect(missingInput.status, CircuitBreakerSelectionStatus.insufficient);
    });

    test(
      'rating and breaking capacity reject NaN Infinity zero and negative',
      () {
        for (final invalid in [
          0.0,
          -1.0,
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ]) {
          expect(
            () => CircuitBreakerSelectionInput(
              selectionMode: BreakerSelectionMode.manual,
              breakerType: BreakerType.mcb,
              ratedCurrentA: invalid,
              manualOverrideReason: 'Approved override',
            ),
            throwsArgumentError,
          );
        }
      },
    );

    test('selected result round-trips and preserves traceability', () {
      final original = selector.select(
        circuit: activeCircuit(),
        current: calculatedCurrent(15.5),
        input: manualInput(
          BreakerType.mcb,
          16,
          breakingCapacityKa: 10,
          tripCurveDesignation: 'C',
        ),
      );
      final decoded = CircuitBreakerSelectionResult.fromJson(
        Map<String, Object?>.from(
          jsonDecode(jsonEncode(original.toJson())) as Map,
        ),
      );
      expect(decoded.toJson(), original.toJson());
      expect(decoded.sourceReferences, isNotEmpty);
      expect(decoded.catalogVersion, CircuitBreakerCatalog.version);
      expect(
        decoded.cableCoordinationStatus,
        CableCoordinationStatus.pendingCableSelection,
      );
    });

    test('malformed JSON cannot bypass result invariants', () {
      final valid = selector
          .select(
            circuit: activeCircuit(),
            current: calculatedCurrent(10),
            input: automaticInput(BreakerType.mcb),
          )
          .toJson();
      final missingSources = Map<String, Object?>.from(valid)
        ..['sourceReferences'] = <Object?>[];
      final wrongMargin = Map<String, Object?>.from(valid)
        ..['currentMarginA'] = 99;
      final unresolvedWithValue = <String, Object?>{
        'status': 'invalid',
        'reason': 'bad',
        'ratedCurrentA': 16,
        'sourceReferences': <Object?>[],
      };
      final wrongCatalogVersion = Map<String, Object?>.from(valid)
        ..['catalogVersion'] = 'unknown-catalog';
      final wrongCoordination = Map<String, Object?>.from(valid)
        ..['cableCoordinationStatus'] = null;
      expect(
        () => CircuitBreakerSelectionResult.fromJson(missingSources),
        throwsArgumentError,
      );
      expect(
        () => CircuitBreakerSelectionResult.fromJson(wrongMargin),
        throwsArgumentError,
      );
      expect(
        () => CircuitBreakerSelectionResult.fromJson(unresolvedWithValue),
        throwsArgumentError,
      );
      expect(
        () => CircuitBreakerSelectionResult.fromJson(wrongCatalogVersion),
        throwsArgumentError,
      );
      expect(
        () => CircuitBreakerSelectionResult.fromJson(wrongCoordination),
        throwsArgumentError,
      );
    });

    test('ACTIVE result is provisional pending cable selection', () {
      final result = selector.select(
        circuit: activeCircuit(),
        current: calculatedCurrent(10),
        input: automaticInput(BreakerType.mcb),
      );
      expect(
        result.cableCoordinationStatus,
        CableCoordinationStatus.pendingCableSelection,
      );
      expect(result.currentMarginA, result.ratedCurrentA! - 10);
    });
  });
}

CircuitBreakerSelectionInput automaticInput(
  BreakerType type, {
  BreakerPoleConfiguration? pole,
}) => CircuitBreakerSelectionInput(
  selectionMode: BreakerSelectionMode.automatic,
  breakerType: type,
  poleConfiguration: pole,
);

CircuitBreakerSelectionInput manualInput(
  BreakerType type,
  double rating, {
  BreakerPoleConfiguration? pole,
  double? breakingCapacityKa,
  String? tripCurveDesignation,
  bool includeReason = true,
}) => CircuitBreakerSelectionInput(
  selectionMode: BreakerSelectionMode.manual,
  breakerType: type,
  ratedCurrentA: rating,
  poleConfiguration: pole,
  breakingCapacityKa: breakingCapacityKa,
  tripCurveDesignation: tripCurveDesignation,
  manualOverrideReason: includeReason ? 'Approved manual override' : null,
);

CircuitDefinition activeCircuit({bool threePhase = false}) => CircuitDefinition(
  circuitNo: 1,
  description: 'Load',
  status: CircuitStatus.active,
  phaseConfiguration: threePhase
      ? CircuitPhaseConfiguration.threePhase
      : CircuitPhaseConfiguration.singlePhase,
  phaseAssignmentMode: PhaseAssignmentMode.manual,
  phaseAssignment: threePhase ? PhaseAssignment.rst : PhaseAssignment.r,
  loadInput: LoadInput.directCurrentA(10),
);

CircuitDefinition spareCircuit() => CircuitDefinition(
  circuitNo: 2,
  description: 'Spare',
  status: CircuitStatus.spare,
  phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
  phaseAssignmentMode: PhaseAssignmentMode.manual,
  phaseAssignment: PhaseAssignment.s,
);

CircuitDefinition spaceCircuit() => CircuitDefinition(
  circuitNo: 3,
  description: 'Space',
  status: CircuitStatus.space,
  phaseConfiguration: CircuitPhaseConfiguration.singlePhase,
  phaseAssignmentMode: PhaseAssignmentMode.manual,
  phaseAssignment: PhaseAssignment.t,
);

CurrentCalculationResult calculatedCurrent(
  double currentA, {
  bool threePhase = false,
}) {
  final voltage = threePhase ? 400.0 : 230.0;
  final multiplier = threePhase ? 1.7320508075688772 : 1.0;
  return CurrentCalculationResult.calculated(
    designCurrentA: currentA,
    apparentPowerVa: currentA * voltage * multiplier,
    voltageBasis: threePhase
        ? VoltageBasis.lineToLine
        : VoltageBasis.lineToNeutral,
    voltageUsedV: voltage,
    formulaId: threePhase
        ? CurrentFormulaId.directCurrentThreePhase
        : CurrentFormulaId.directCurrentSinglePhase,
    sourceReferences: const [
      CalculationSourceReference(
        sourceId: 'test-current',
        label: 'Calculated current fixture',
      ),
    ],
  );
}
