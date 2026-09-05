import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/pages/cable_design_page_v2.dart';

void main() {
  testWidgets('legacy page exposes an explicit voltage-drop opt-out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CableDesignPageV2()));

    final option = find.byType(CheckboxListTile);
    await tester.scrollUntilVisible(
      option,
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('ไม่พิจารณา Voltage Drop'), findsOneWidget);
    expect(
      find.textContaining('ไม่ได้พิจารณาแรงดันตกในการเลือกขนาดสาย'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Ampacity = ความสามารถในการรับกระแสของสาย'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Voltage Drop = ข้อจำกัดแรงดันตกตามระยะทาง'),
      findsOneWidget,
    );
    expect(tester.widget<CheckboxListTile>(option).value, isFalse);

    await tester.tap(option);
    await tester.pump();

    expect(tester.widget<CheckboxListTile>(option).value, isTrue);

    await tester.scrollUntilVisible(
      find.byKey(const Key('legacy-load-current')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('legacy-load-current')),
      '10',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('legacy-calculate')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('legacy-calculate')));
    await tester.pumpAndSettle();
    expect(find.text('ไม่พิจารณา'), findsWidgets);
    expect(find.textContaining('Ampacity เท่านั้น'), findsWidgets);
    expect(find.textContaining('0 %'), findsNothing);

    final disclaimer = find.textContaining(
      'ควรตรวจสอบโดยวิศวกรก่อนนำไปใช้ในการก่อสร้าง',
    );
    await tester.scrollUntilVisible(
      disclaimer,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(disclaimer, findsOneWidget);
  });

  testWidgets(
    'legacy bilingual helpers and dialog are mobile-safe and read-only',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: CableDesignPageV2()));
      expect(find.text('ข้อมูลการออกแบบ'), findsOneWidget);
      expect(find.text('กระแสโหลดที่ใช้ในการออกแบบ'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final phaseField = find.byKey(const Key('legacy-phase-system'));
      final phaseBefore = tester.state<FormFieldState<PhaseSystem>>(phaseField).value;
      await tester.scrollUntilVisible(
        find.byKey(const Key('legacy-info-phase-system')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('legacy-info-phase-system')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('ระบบเฟสของวงจร'), findsWidgets);
      await tester.tap(find.byKey(const Key('legacy-info-close')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester.state<FormFieldState<PhaseSystem>>(phaseField).value,
        phaseBefore,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
