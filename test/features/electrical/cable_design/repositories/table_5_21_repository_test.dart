import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/electrical_system_applicability.dart';
import 'package:mep_project/features/electrical/cable_design/models/table_5_21_column.dart';
import 'package:mep_project/features/electrical/cable_design/repositories/table_5_21_repository.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = Table521Repository();

  Future<double?> lookupFor(
    Table521Column column, {
    required String cableTypeCode,
  }) {
    return repository.lookup(
      sizeSqmm: 10,
      cableShape: column.cableShape,
      coreType: column.coreType,
      insulation: column.insulation,
      conductorTemperatureClass: column.conductorTemperatureClass,
      loadedConductors: column.loadedConductors,
      systemApplicability: column.systemApplicability,
      cableTypeCode: cableTypeCode,
    );
  }

  group('Table 5-21 master data', () {
    test('preserves all nine independently published source columns', () async {
      final table = await repository.loadTable();

      expect(table.columns.map((column) => column.id), [
        'C1',
        'C2',
        'C3',
        'C4',
        'C5',
        'C6',
        'C7',
        'C8',
        'C9',
      ]);
      expect(table.rows, hasLength(19));
      expect(table.columns[0].cableShape, CableShape.flat);
      expect(table.columns[0].coreType, CoreType.multiCore);
      expect(table.columns[0].insulation, CableInsulation.pvc);
      expect(
        table.columns[0].conductorTemperatureClass,
        ConductorTemperatureClass.pvc70,
      );
      expect(table.columns[0].loadedConductors, 2);
      expect(
        table.columns[0].systemApplicability,
        ElectricalSystemApplicability.ac,
      );
      expect(table.columns[0].applicableCableTypeCodes, ['VAF', 'VAF-G']);
      expect(table.columns[1].applicableCableTypeCodes, ['NYY', 'IEC 60502-1']);
      expect(table.columns[2].applicableCableTypeCodes, ['NYY', 'IEC 60502-1']);
      expect(table.columns[3].applicableCableTypeCodes, ['IEC 60502-1']);
      expect(table.columns[4].applicableCableTypeCodes, ['IEC 60502-1']);
      expect(table.columns[5].applicableCableTypeCodes, [
        'NYY',
        'NYY-G',
        'VCT',
        'VCT-G',
        '60227 IEC 10',
        'IEC 60502-1',
      ]);
      expect(table.columns[6].applicableCableTypeCodes, [
        'NYY',
        'NYY-G',
        'VCT',
        'VCT-G',
        '60227 IEC 10',
        'IEC 60502-1',
      ]);
      expect(table.columns[7].applicableCableTypeCodes, ['IEC 60502-1']);
      expect(table.columns[8].applicableCableTypeCodes, ['IEC 60502-1']);
      expect(table.columns[8].insulation, CableInsulation.xlpe);
      expect(table.columns[8].loadedConductors, 3);
    });

    test(
      'matches approved spot checks without collapsing source columns',
      () async {
        final table = await repository.loadTable();
        Map<String, double?> cells(double size) => table.rows
            .singleWhere((row) => row.sizeSqmm == size)
            .ampacityByColumnId;

        expect(cells(1).values.toList(), [14, 13, 12, 17, 16, 13, 12, 17, 15]);
        expect(cells(10).values.toList(), [56, 57, 51, 74, 67, 55, 50, 73, 65]);
        expect(cells(25).values.toList(), [
          null,
          99,
          90,
          130,
          118,
          97,
          84,
          126,
          108,
        ]);
        expect(cells(400).values.toList(), [
          null,
          604,
          552,
          790,
          722,
          null,
          null,
          null,
          null,
        ]);
        expect(cells(500).values.toList(), [
          null,
          689,
          629,
          900,
          823,
          null,
          null,
          null,
          null,
        ]);
      },
    );

    test(
      'enforces the approved merged-header cable-type relationships',
      () async {
        final table = await repository.loadTable();
        final columns = {for (final column in table.columns) column.id: column};

        expect(await lookupFor(columns['C1']!, cableTypeCode: 'VAF'), 56);
        expect(await lookupFor(columns['C1']!, cableTypeCode: 'VAF-G'), 56);
        expect(await lookupFor(columns['C2']!, cableTypeCode: 'NYY'), 57);
        expect(
          await lookupFor(columns['C3']!, cableTypeCode: 'IEC 60502-1'),
          51,
        );
        expect(
          await lookupFor(columns['C4']!, cableTypeCode: 'IEC 60502-1'),
          74,
        );
        expect(
          await lookupFor(columns['C5']!, cableTypeCode: 'IEC 60502-1'),
          67,
        );
        for (final cableType in [
          'NYY',
          'NYY-G',
          'VCT',
          'VCT-G',
          '60227 IEC 10',
          'IEC 60502-1',
        ]) {
          expect(await lookupFor(columns['C6']!, cableTypeCode: cableType), 55);
          expect(await lookupFor(columns['C7']!, cableTypeCode: cableType), 50);
        }
        expect(
          await lookupFor(columns['C8']!, cableTypeCode: 'IEC 60502-1'),
          73,
        );
        expect(
          await lookupFor(columns['C9']!, cableTypeCode: 'IEC 60502-1'),
          65,
        );

        for (final columnId in [
          'C2',
          'C3',
          'C4',
          'C5',
          'C6',
          'C7',
          'C8',
          'C9',
        ]) {
          expect(
            await lookupFor(columns[columnId]!, cableTypeCode: 'VAF'),
            isNull,
          );
        }
        expect(await lookupFor(columns['C2']!, cableTypeCode: 'VCT'), isNull);
        expect(await lookupFor(columns['C3']!, cableTypeCode: 'VCT'), isNull);
        for (final columnId in ['C4', 'C5', 'C8', 'C9']) {
          expect(
            await lookupFor(columns[columnId]!, cableTypeCode: 'NYY'),
            isNull,
          );
        }
        for (final column in table.columns) {
          expect(await lookupFor(column, cableTypeCode: 'UNKNOWN'), isNull);
        }

        final unavailable = await repository.lookupByColumnId(
          sizeSqmm: 400,
          columnId: 'C1',
        );
        final explicitSourceColumn = await repository.lookupByColumnId(
          sizeSqmm: 10,
          columnId: 'C2',
        );

        expect(unavailable, isNull);
        expect(explicitSourceColumn, 57);
      },
    );
  });
}
