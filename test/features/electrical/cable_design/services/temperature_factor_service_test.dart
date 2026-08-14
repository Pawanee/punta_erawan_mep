import 'package:flutter_test/flutter_test.dart';

import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/services/temperature_factor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TemperatureFactorService', () {
    final service = TemperatureFactorService();

    test('PVC 70C at 30C returns 1.15', () async {
      final result = await service.resolve(
        ambientTemperatureC: 30,
        temperatureClass: ConductorTemperatureClass.pvc70,
      );

      expect(result, 1.15);
    });

    test('PVC 70C at 40C returns 1.00', () async {
      final result = await service.resolve(
        ambientTemperatureC: 40,
        temperatureClass: ConductorTemperatureClass.pvc70,
      );

      expect(result, 1.00);
    });

    test('PVC 70C at 45C returns 0.91', () async {
      final result = await service.resolve(
        ambientTemperatureC: 45,
        temperatureClass: ConductorTemperatureClass.pvc70,
      );

      expect(result, 0.91);
    });

    test('PVC 70C at 50C returns 0.82', () async {
      final result = await service.resolve(
        ambientTemperatureC: 50,
        temperatureClass: ConductorTemperatureClass.pvc70,
      );

      expect(result, 0.82);
    });

    test('XLPE/EPR 90C at 30C returns 1.10', () async {
      final result = await service.resolve(
        ambientTemperatureC: 30,
        temperatureClass: ConductorTemperatureClass.xlpeEpr90,
      );

      expect(result, 1.10);
    });

    test('XLPE/EPR 90C at 40C returns 1.00', () async {
      final result = await service.resolve(
        ambientTemperatureC: 40,
        temperatureClass: ConductorTemperatureClass.xlpeEpr90,
      );

      expect(result, 1.00);
    });

    test('XLPE/EPR 90C at 50C returns 0.90', () async {
      final result = await service.resolve(
        ambientTemperatureC: 50,
        temperatureClass: ConductorTemperatureClass.xlpeEpr90,
      );

      expect(result, 0.90);
    });

    test('XLPE/EPR 90C at 60C returns 0.78', () async {
      final result = await service.resolve(
        ambientTemperatureC: 60,
        temperatureClass: ConductorTemperatureClass.xlpeEpr90,
      );

      expect(result, 0.78);
    });

    test('PVC 90C at 60C returns 0.83', () async {
      final result = await service.resolve(
        ambientTemperatureC: 60,
        temperatureClass: ConductorTemperatureClass.pvc90,
      );

      expect(result, 0.83);
    });

    test('PVC 70C at 65C returns null', () async {
      final result = await service.resolve(
        ambientTemperatureC: 65,
        temperatureClass: ConductorTemperatureClass.pvc70,
      );

      expect(result, isNull);
    });

    test('XLPE/EPR 90C at 75C returns 0.55', () async {
      final result = await service.resolve(
        ambientTemperatureC: 75,
        temperatureClass: ConductorTemperatureClass.xlpeEpr90,
      );

      expect(result, 0.55);
    });

    test('temperature below table range returns null', () async {
      final result = await service.resolve(
        ambientTemperatureC: 10,
        temperatureClass: ConductorTemperatureClass.pvc70,
      );

      expect(result, isNull);
    });

    test('temperature above table range returns null', () async {
      final result = await service.resolve(
        ambientTemperatureC: 100,
        temperatureClass: ConductorTemperatureClass.xlpeEpr90,
      );

      expect(result, isNull);
    });
  });
}