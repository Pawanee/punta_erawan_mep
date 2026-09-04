import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('เลือกขนาดสายจาก Ampacity เท่านั้น'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(option).value, isFalse);

    await tester.tap(option);
    await tester.pump();

    expect(tester.widget<CheckboxListTile>(option).value, isTrue);
  });
}
