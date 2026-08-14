 import 'package:flutter_test/flutter_test.dart';

import 'package:mep_project/features/electrical/cable_design/enums/ampacity_table.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_type.dart';
import 'package:mep_project/features/electrical/cable_design/policies/approved_cable_type_context_policy.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/ampacity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApprovedCableTypeContextPolicy - Ampacity Table', () {
    test('IEC 01 resolves to Table 5-20', () {
      const policy = ApprovedCableTypeContextPolicy();

      final context = policy.resolve(
        CableType.iec01,
      );

      expect(
        context.ampacityTable,
        AmpacityTable.table520,
      );
    });

    test('IEC 60502-1 resolves to Table 5-27', () {
      const policy = ApprovedCableTypeContextPolicy();

      final context = policy.resolve(
        CableType.iec605021,
      );

      expect(
        context.ampacityTable,
        AmpacityTable.table527,
      );
    });
  });

  group('AmpacityRepository - approved table access', () {
    test(
      'Table 5-20 repository path is available',
      () async {
        final repository = AmpacityRepository();

        final rows = await repository.loadTable(
          table: AmpacityTable.table520,
          cableType: CableType.iec01,
        );

        expect(
          rows,
          isNotEmpty,
        );

        expect(
          rows.every(
            (row) => row.reference == 'Table 5-20',
          ),
          isTrue,
        );
      },
    );

    test(
      'Table 5-27 repository path is available',
      () async {
        final repository = AmpacityRepository();

        final rows = await repository.loadTable(
          table: AmpacityTable.table527,
          cableType: CableType.iec605021,
        );

        expect(
          rows,
          isNotEmpty,
        );

        expect(
          rows.every(
            (row) => row.reference == 'Table 5-27',
          ),
          isTrue,
        );
      },
    );
  });
}