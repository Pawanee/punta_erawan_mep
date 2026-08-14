 import 'package:flutter_test/flutter_test.dart';

import 'package:mep_project/features/electrical/cable_design/services/grouping_factor_service.dart';

void main() {
  // Required because GroupingFactorService loads Table 5-8
  // through Flutter's rootBundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GroupingFactorService', () {
    final service = GroupingFactorService();

    test('1 circuit returns factor 1.00', () async {
      final result = await service.getFactor(
        circuits: 1,
        enclosed: true,
      );

      expect(result, 1.00);
    });

    test('2 circuits enclosed returns 0.80', () async {
      final result = await service.getFactor(
        circuits: 2,
        enclosed: true,
      );

      expect(result, 0.80);
    });

    test('2 circuits surface returns 0.85', () async {
      final result = await service.getFactor(
        circuits: 2,
        enclosed: false,
      );

      expect(result, 0.85);
    });

    test('3 circuits enclosed returns 0.70', () async {
      final result = await service.getFactor(
        circuits: 3,
        enclosed: true,
      );

      expect(result, 0.70);
    });

    test('3 circuits surface returns 0.79', () async {
      final result = await service.getFactor(
        circuits: 3,
        enclosed: false,
      );

      expect(result, 0.79);
    });

    test('10 circuits uses 10-12 range', () async {
      final result = await service.getFactor(
        circuits: 10,
        enclosed: true,
      );

      expect(result, 0.45);
    });

    test('12 circuits uses 10-12 range', () async {
      final result = await service.getFactor(
        circuits: 12,
        enclosed: true,
      );

      expect(result, 0.45);
    });

    test('13 circuits uses 13-16 range', () async {
      final result = await service.getFactor(
        circuits: 13,
        enclosed: true,
      );

      expect(result, 0.41);
    });

    test('16 circuits uses 13-16 range', () async {
      final result = await service.getFactor(
        circuits: 16,
        enclosed: true,
      );

      expect(result, 0.41);
    });

    test('17 circuits uses 17-20 range', () async {
      final result = await service.getFactor(
        circuits: 17,
        enclosed: true,
      );

      expect(result, 0.38);
    });

    test('20 circuits uses 17-20 range', () async {
      final result = await service.getFactor(
        circuits: 20,
        enclosed: true,
      );

      expect(result, 0.38);
    });

    test('21 circuits falls back to 1.00', () async {
      final result = await service.getFactor(
        circuits: 21,
        enclosed: true,
      );

      expect(result, 1.00);
    });
  });
}