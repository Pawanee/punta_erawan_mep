import 'package:flutter_test/flutter_test.dart';

import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/policies/approved_cable_type_context_policy.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  const policy = ApprovedCableTypeContextPolicy();

  group('ApprovedCableTypeContextPolicy', () {
    test('maps PVC cable types to PVC 70C / Table 5-20', () {
      const pvcCableTypes = [
        CableType.iec01,
        CableType.iec02,
        CableType.iec05,
        CableType.iec06,
        CableType.iec10,
        CableType.nyy,
        CableType.nyyG,
        CableType.vct,
        CableType.vctG,
      ];

      for (final cableType in pvcCableTypes) {
        final context = policy.resolve(cableType);

        expect(context.cableType, cableType);
        expect(context.insulation, CableInsulation.pvc);
        expect(
          context.temperatureClass,
          ConductorTemperatureClass.pvc70,
        );
        expect(
          context.ampacityTable,
          AmpacityTable.table520,
        );
      }
    });

    test('maps IEC 60502-1 to XLPE 90C / Table 5-27', () {
      final context = policy.resolve(CableType.iec605021);

      expect(
        context.cableType,
        CableType.iec605021,
      );
      expect(
        context.insulation,
        CableInsulation.xlpe,
      );
      expect(
        context.temperatureClass,
        ConductorTemperatureClass.xlpeEpr90,
      );
      expect(
        context.ampacityTable,
        AmpacityTable.table527,
      );
    });
  });
}