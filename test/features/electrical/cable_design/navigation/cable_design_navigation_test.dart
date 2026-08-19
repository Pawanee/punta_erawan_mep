import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/pages/cable_design_page_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/pages/cable_design_v2_page.dart';
import 'package:mep_project/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) =>
      tester.pumpWidget(const PuntaApp());

  testWidgets('standard Cable Design remains the default entry', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(CableDesignPageV2), findsOneWidget);
    expect(find.byType(CableDesignV2Page), findsNothing);
    expect(
      find.byKey(const Key('advanced-cable-design-entry')),
      findsOneWidget,
    );
  });

  testWidgets('Advanced Cable Design opens only from its explicit entry', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('advanced-cable-design-entry')));
    await tester.pumpAndSettle();

    expect(find.byType(CableDesignV2Page), findsOneWidget);
    expect(find.text('Advanced Cable Design'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('v2-calculate')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('v2-calculate')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('back returns to legacy without automatic workflow switching', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('advanced-cable-design-entry')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(CableDesignPageV2), findsOneWidget);
    expect(find.byType(CableDesignV2Page), findsNothing);
  });
}
