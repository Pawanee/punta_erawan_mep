import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_workflow.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_workflow_activation.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/pages/cable_design_v2_page.dart';

void main() {
  const advanced = CableDesignWorkflowActivation(
    workflow: CableDesignWorkflow.advancedCableDesign,
  );

  Future<void> pumpPage(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(home: CableDesignV2Page(activation: advanced)),
  );

  testWidgets(
    'starts as Advanced Cable Design with an initial result placeholder',
    (tester) async {
      await pumpPage(tester);
      expect(find.text('Advanced Cable Design'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pump();
      expect(find.text('Result: Cable design'), findsOneWidget);
      expect(
        find.text('Enter explicit design inputs to begin.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('selects VAF and VAF-G directly without a legacy cable type', (
    tester,
  ) async {
    await pumpPage(tester);
    final vafRadio = find.byWidgetPredicate(
      (widget) =>
          widget is Radio<CableRoutingIdentity> &&
          widget.value == CableRoutingIdentity.vaf,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('VAF')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('VAF'));
    await tester.pump();
    expect(
      tester.widget<Radio<CableRoutingIdentity>>(vafRadio).groupValue,
      CableRoutingIdentity.vaf,
    );
    final vafGRadio = find.byWidgetPredicate(
      (widget) =>
          widget is Radio<CableRoutingIdentity> &&
          widget.value == CableRoutingIdentity.vafG,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('VAF-G')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('VAF-G'));
    await tester.pump();
    expect(
      tester.widget<Radio<CableRoutingIdentity>>(vafGRadio).groupValue,
      CableRoutingIdentity.vafG,
    );
  });

  testWidgets(
    'VD defaults off and enabling it does not expose inferred facts',
    (tester) async {
      await pumpPage(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pump();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(find.byKey(const Key('v2-vd-phase')), findsNothing);
      await tester.tap(find.text('Verify voltage drop'));
      await tester.pump();
      expect(find.byKey(const Key('v2-vd-phase')), findsWidgets);
      expect(find.text('Table 9.1'), findsNothing);
    },
  );

  testWidgets(
    'shows Thai field help and info dialog without mutating engineering input',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpPage(tester);
      expect(find.text('กระแสโหลดที่ใช้ในการออกแบบ'), findsOneWidget);
      expect(find.text('จำนวนตัวนำที่มีกระแส'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final loadedBefore = tester
          .state<FormFieldState<int>>(
            find.byKey(const Key('v2-loaded-conductors')),
          )
          .value;
      await tester.tap(find.byKey(const Key('v2-info-loaded-conductors')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('ไม่ใช่จำนวนเฟสของระบบโดยตรง'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('v2-info-close')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester
            .state<FormFieldState<int>>(
              find.byKey(const Key('v2-loaded-conductors')),
            )
            .value,
        loadedBefore,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('does not expose engineering tables and Calculate is disabled', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();
    expect(find.textContaining('5-21'), findsNothing);
    expect(find.textContaining('5-47'), findsNothing);
    expect(find.textContaining('C1'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('v2-calculate')).first)
          .onPressed,
      isNull,
    );
  });

  test(
    'activation defaults to legacy and V2 requires an explicit workflow',
    () {
      const legacy = CableDesignWorkflowActivation();
      expect(legacy.workflow, CableDesignWorkflow.legacy);
      expect(legacy.routingMode, CableDesignRoutingMode.legacy);
      expect(advanced.routingMode, CableDesignRoutingMode.routingV2);
    },
  );
}
