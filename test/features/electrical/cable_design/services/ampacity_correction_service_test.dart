import 'package:flutter_test/flutter_test.dart';

import 'package:mep_project/features/electrical/cable_design/services/ampacity_correction_service.dart';

void main() {
  group('AmpacityCorrectionService', () {
    const service = AmpacityCorrectionService();

    test('calculates corrected ampacity correctly', () {
      final result = service.calculate(
        baseAmpacity: 100,
        groupingFactor: 0.80,
        temperatureFactor: 0.91,
      );

      expect(result, closeTo(72.8, 0.000001));
    });

    test('calculates with both correction factors equal to 1.00', () {
      final result = service.calculate(
        baseAmpacity: 100,
        groupingFactor: 1.00,
        temperatureFactor: 1.00,
      );

      expect(result, closeTo(100.0, 0.000001));
    });

    test('calculates grouping factor only when temperature factor is 1.00', () {
      final result = service.calculate(
        baseAmpacity: 125,
        groupingFactor: 0.80,
        temperatureFactor: 1.00,
      );

      expect(result, closeTo(100.0, 0.000001));
    });

    test('calculates temperature factor only when grouping factor is 1.00', () {
      final result = service.calculate(
        baseAmpacity: 100,
        groupingFactor: 1.00,
        temperatureFactor: 0.91,
      );

      expect(result, closeTo(91.0, 0.000001));
    });

    test('returns null when grouping factor is unavailable', () {
      final result = service.calculate(
        baseAmpacity: 100,
        groupingFactor: null,
        temperatureFactor: 0.91,
      );

      expect(result, isNull);
    });

    test('returns null when temperature factor is unavailable', () {
      final result = service.calculate(
        baseAmpacity: 100,
        groupingFactor: 0.80,
        temperatureFactor: null,
      );

      expect(result, isNull);
    });

    test('returns null when both correction factors are unavailable', () {
      final result = service.calculate(
        baseAmpacity: 100,
        groupingFactor: null,
        temperatureFactor: null,
      );

      expect(result, isNull);
    });

    test('supports decimal base ampacity', () {
      final result = service.calculate(
        baseAmpacity: 37.5,
        groupingFactor: 0.70,
        temperatureFactor: 0.91,
      );

      expect(result, closeTo(23.8875, 0.000001));
    });
  });
}