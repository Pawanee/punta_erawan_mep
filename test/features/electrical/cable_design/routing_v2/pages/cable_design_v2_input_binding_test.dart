import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_workflow.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_workflow_activation.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/pages/cable_design_v2_page.dart';

void main() {
  const activation = CableDesignWorkflowActivation(
    workflow: CableDesignWorkflow.advancedCableDesign,
  );

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(home: CableDesignV2Page(activation: activation)),
  );

  Future<void> selectDropdown(
    WidgetTester tester,
    Key key,
    String label,
  ) async {
    await tester.ensureVisible(find.byKey(key).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> enterCompleteAmpacityInputs(
    WidgetTester tester, {
    required String product,
    String loadCurrent = '10',
  }) async {
    await tester.enterText(
      find.byKey(const Key('v2-load-current')).first,
      loadCurrent,
    );
    await selectDropdown(tester, const Key('v2-phase-system'), '1Ø');
    await selectDropdown(tester, const Key('v2-loaded-conductors'), '2');
    await selectDropdown(tester, const Key('v2-core-type'), 'Multi Core');
    await tester.enterText(
      find.byKey(const Key('v2-ambient-temperature')).first,
      '40',
    );
    await tester.tap(find.text(product));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await selectDropdown(
      tester,
      const Key('v2-installation-environment'),
      'surfaceMountedWallOrCeiling',
    );
    await selectDropdown(
      tester,
      const Key('v2-installation-support'),
      'surfaceMount',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'initial page has no readiness result and Calculate stays disabled',
    (tester) async {
      await pumpPage(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pump();
      expect(find.text('Inputs ready for calculation'), findsNothing);
      expect(find.text('Inputs are incomplete'), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('v2-calculate')).first)
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('incomplete inputs map to insufficient without execution', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    expect(find.text('Inputs are incomplete'), findsOneWidget);
    expect(find.textContaining('Missing:'), findsOneWidget);
  });

  testWidgets(
    'complete VAF ampacity-only inputs are ready but do not calculate',
    (tester) async {
      await pumpPage(tester);
      await enterCompleteAmpacityInputs(tester, product: 'VAF');
      await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
      await tester.pump();
      expect(find.text('Inputs ready for calculation'), findsOneWidget);
      expect(find.textContaining('Table 5-21'), findsNothing);
      expect(find.textContaining('C1'), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('v2-calculate')).first)
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('complete VAF-G ampacity-only inputs are ready', (tester) async {
    await pumpPage(tester);
    await enterCompleteAmpacityInputs(tester, product: 'VAF-G');
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    expect(find.text('Inputs ready for calculation'), findsOneWidget);
  });

  testWidgets('invalid load is reported invalid by the mapper', (tester) async {
    await pumpPage(tester);
    await enterCompleteAmpacityInputs(tester, product: 'VAF', loadCurrent: '0');
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    expect(find.text('Inputs are invalid'), findsOneWidget);
  });

  testWidgets('VD on without explicit VD facts remains insufficient', (
    tester,
  ) async {
    await pumpPage(tester);
    await enterCompleteAmpacityInputs(tester, product: 'VAF');
    await tester.tap(find.text('Verify voltage drop'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    expect(find.text('Inputs are incomplete'), findsOneWidget);
    expect(find.textContaining('voltageDropPhase'), findsOneWidget);
  });

  testWidgets(
    'complete explicit VD inputs are ready without an engineering result',
    (tester) async {
      await pumpPage(tester);
      await enterCompleteAmpacityInputs(tester, product: 'VAF');
      await tester.tap(find.text('Verify voltage drop'));
      await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
      await selectDropdown(tester, const Key('v2-vd-phase'), 'singlePhase');
      await selectDropdown(tester, const Key('v2-vd-insulation'), 'pvc');
      await selectDropdown(tester, const Key('v2-vd-core-type'), 'Multi Core');
      await selectDropdown(
        tester,
        const Key('v2-vd-installation-group'),
        'group1',
      );
      await tester.enterText(find.byKey(const Key('v2-vd-length')).first, '30');
      await tester.enterText(
        find.byKey(const Key('v2-vd-system-voltage')).first,
        '230',
      );
      await tester.enterText(
        find.byKey(const Key('v2-vd-allowable')).first,
        '3',
      );
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
      await tester.pump();
      expect(find.text('Inputs ready for calculation'), findsOneWidget);
      expect(find.textContaining('Table 9.'), findsNothing);
      expect(find.textContaining('Voltage drop ='), findsNothing);
    },
  );
}
