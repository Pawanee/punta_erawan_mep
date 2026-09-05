import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_execution_caller_adaptation_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_execution_controller_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_workflow.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_caller_adaptation_result.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_caller_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_controller_result_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_v2_presentation_state.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_workflow_activation.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/pages/cable_design_v2_page.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_execution_controller_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_v2_result_presenter.dart';

class _ControllerSpy extends CableDesignExecutionControllerV2 {
  var calls = 0;
  Future<CableDesignExecutionControllerResultV2>? completion;

  @override
  Future<CableDesignExecutionControllerResultV2> execute(
    CableDesignExecutionCallerInput input,
  ) {
    calls++;
    return completion = super.execute(input);
  }
}

class _PendingControllerSpy extends CableDesignExecutionControllerV2 {
  final release = Completer<void>();
  var calls = 0;

  @override
  Future<CableDesignExecutionControllerResultV2> execute(
    CableDesignExecutionCallerInput input,
  ) async {
    calls++;
    await release.future;
    return const CableDesignExecutionControllerResultV2(
      status: CableDesignExecutionControllerStatusV2.insufficient,
      adaptation: CableDesignExecutionCallerAdaptationResult(
        status: CableDesignExecutionCallerAdaptationStatus.insufficient,
        request: null,
      ),
    );
  }
}

class _InsufficientControllerSpy extends CableDesignExecutionControllerV2 {
  var calls = 0;
  Future<CableDesignExecutionControllerResultV2>? completion;

  @override
  Future<CableDesignExecutionControllerResultV2> execute(
    CableDesignExecutionCallerInput input,
  ) async {
    calls++;
    return completion = Future.value(
      const CableDesignExecutionControllerResultV2(
        status: CableDesignExecutionControllerStatusV2.insufficient,
        adaptation: CableDesignExecutionCallerAdaptationResult(
          status: CableDesignExecutionCallerAdaptationStatus.insufficient,
          request: null,
          missingFields: ['controllerInput'],
        ),
        reason: 'Controller requires additional input.',
      ),
    );
  }
}

class _PresenterSpy extends CableDesignV2ResultPresenter {
  var calls = 0;

  @override
  CableDesignV2PresentationState present(
    CableDesignExecutionControllerResultV2 result,
  ) {
    calls++;
    return super.present(result);
  }
}

void main() {
  const activation = CableDesignWorkflowActivation(
    workflow: CableDesignWorkflow.advancedCableDesign,
  );

  tearDown(rootBundle.clear);

  Future<void> selectDropdown(
    WidgetTester tester,
    Key key,
    String label,
  ) async {
    await tester.scrollUntilVisible(
      find.byKey(key).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> scrollToKey(WidgetTester tester, Key key) =>
      tester.scrollUntilVisible(
        find.byKey(key),
        400,
        scrollable: find.byType(Scrollable).first,
      );

  Future<void> openReferences(WidgetTester tester) async {
    final details = find.text('Reference / Calculation Details');
    await tester.scrollUntilVisible(
      details,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(details);
    await tester.pump();
    await tester.tap(details);
    await tester.pumpAndSettle();
  }

  Future<void> enterReadyAmpacityInputs(
    WidgetTester tester, {
    required String product,
    String loadCurrent = '10',
    String loadedConductors = '2',
    bool selectProduct = true,
    bool selectCore = true,
    String coreType = 'Multi Core',
  }) async {
    await tester.drag(find.byType(ListView), const Offset(0, 1600));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('v2-load-current')).first,
      loadCurrent,
    );
    await selectDropdown(tester, const Key('v2-phase-system'), '1Ø');
    await selectDropdown(
      tester,
      const Key('v2-loaded-conductors'),
      loadedConductors,
    );
    if (selectCore) {
      await selectDropdown(tester, const Key('v2-core-type'), coreType);
    }
    await tester.enterText(
      find.byKey(const Key('v2-ambient-temperature')).first,
      '40',
    );
    if (selectProduct) {
      final productFinder = switch (product) {
        '60227 IEC 10' => find.byKey(const Key('v2-product-iec10')),
        'IEC 60502-1' => find.byKey(const Key('v2-product-iec60502')),
        _ => find.text(product),
      };
      final productTapTarget =
          product == '60227 IEC 10' || product == 'IEC 60502-1'
          ? find.descendant(of: productFinder, matching: find.text(product))
          : productFinder;
      await tester.scrollUntilVisible(
        productTapTarget,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(productTapTarget);
      await tester.pumpAndSettle();
    }
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
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
    await scrollToKey(tester, const Key('v2-check-inputs'));
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
  }

  Future<void> enterIec10SupplementalInputs(WidgetTester tester) async {
    await selectDropdown(tester, const Key('v2-iec10-cable-shape'), 'round');
    await selectDropdown(tester, const Key('v2-iec10-insulation'), 'pvc');
    await selectDropdown(
      tester,
      const Key('v2-iec10-conductor-temperature-class'),
      'PVC 70°C',
    );
  }

  Future<void> enterReadyVoltageDropInputs(
    WidgetTester tester, {
    required String length,
    required String allowable,
  }) async {
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
    await tester.ensureVisible(find.byKey(const Key('v2-vd-length')).first);
    await tester.enterText(find.byKey(const Key('v2-vd-length')).first, length);
    await tester.ensureVisible(
      find.byKey(const Key('v2-vd-system-voltage')).first,
    );
    await tester.enterText(
      find.byKey(const Key('v2-vd-system-voltage')).first,
      '230',
    );
    await tester.ensureVisible(find.byKey(const Key('v2-vd-allowable')).first);
    await tester.enterText(
      find.byKey(const Key('v2-vd-allowable')).first,
      allowable,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
  }

  Future<void> completeExecution(
    WidgetTester tester,
    _ControllerSpy controller,
  ) async {
    await tester.runAsync(
      () => controller.completion!.timeout(const Duration(seconds: 30)),
    );
    await tester.pump();
  }

  testWidgets(
    'VAF executes only after readiness through the controller and presenter',
    (tester) async {
      final controller = _ControllerSpy();
      await tester.pumpWidget(
        MaterialApp(
          home: CableDesignV2Page(
            activation: activation,
            controller: controller,
          ),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('v2-calculate')).first)
            .onPressed,
        isNull,
      );
      await enterReadyAmpacityInputs(tester, product: 'VAF');
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('v2-calculate')).first)
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('v2-calculate')).first);
      await completeExecution(tester, controller);
      expect(controller.calls, 1);
      expect(find.text('Cable product / standard: VAF'), findsOneWidget);
      expect(find.textContaining('Selected cable size:'), findsOneWidget);
      expect(find.text('Voltage drop: NOT VERIFIED'), findsOneWidget);
      await openReferences(tester);
      expect(find.text('Installation source: Table 5-47'), findsOneWidget);
      expect(find.text('Routing cable identity: VAF'), findsOneWidget);
      expect(find.text('Profile reference: Table 5-48'), findsOneWidget);
      expect(find.text('Source ampacity table: Table 5-21'), findsOneWidget);
      expect(find.text('Source column: C1'), findsOneWidget);
    },
  );

  testWidgets('VAF-G uses the same isolated V2 controller path', (
    tester,
  ) async {
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(tester, product: 'VAF-G');
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(controller.calls, 1);
    expect(find.text('Cable product / standard: VAF-G'), findsOneWidget);
    expect(find.text('Voltage drop: NOT VERIFIED'), findsOneWidget);
    await openReferences(tester);
    expect(find.text('Installation source: Table 5-47'), findsOneWidget);
    expect(find.text('Routing cable identity: VAF-G'), findsOneWidget);
    expect(find.text('Profile reference: Table 5-48'), findsOneWidget);
  });

  testWidgets('IEC 10 executes through the explicit C6 route', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
    tester.binding.window.devicePixelRatioTestValue = 1;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await scrollToKey(tester, const Key('v2-product-iec10'));
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('v2-product-iec10'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('v2-product-iec10')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('v2-iec10-cable-shape')), findsOneWidget);
    await enterReadyAmpacityInputs(
      tester,
      product: '60227 IEC 10',
      selectProduct: false,
      selectCore: false,
    );
    expect(
      tester
          .widget<RadioListTile<CableRoutingIdentity>>(
            find.byKey(const Key('v2-product-iec10')),
          )
          .groupValue,
      CableRoutingIdentity.iec10,
    );
    await enterIec10SupplementalInputs(tester);
    await scrollToKey(tester, const Key('v2-check-inputs'));
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('v2-calculate')).first)
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(controller.calls, 1);
    expect(find.text('Cable product / standard: 60227 IEC 10'), findsOneWidget);
    expect(find.text('Voltage drop: NOT VERIFIED'), findsOneWidget);
    await openReferences(tester);
    expect(find.text('Routing cable identity: 60227 IEC 10'), findsOneWidget);
    expect(find.text('Profile reference: Table 5-48'), findsOneWidget);
    expect(find.text('Installation source: Table 5-47'), findsOneWidget);
    expect(find.text('Source ampacity table: Table 5-21'), findsOneWidget);
    expect(find.text('Source column: C6'), findsOneWidget);
    expect(
      find.text('Shape: round (Explicit supplemental input)'),
      findsOneWidget,
    );
  });

  testWidgets('IEC 10 executes and presents the explicit C7 route', (
    tester,
  ) async {
    tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
    tester.binding.window.devicePixelRatioTestValue = 1;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    expect(find.text('จำนวนตัวนำที่มีกระแส'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('v2-product-iec10')));
    await tester.pumpAndSettle();
    await enterReadyAmpacityInputs(
      tester,
      product: '60227 IEC 10',
      loadCurrent: '60',
      loadedConductors: '3',
      selectProduct: false,
      selectCore: false,
    );
    await enterIec10SupplementalInputs(tester);
    await scrollToKey(tester, const Key('v2-check-inputs'));
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(find.text('Cable product / standard: 60227 IEC 10'), findsOneWidget);
    expect(find.text('Loaded conductors: 3'), findsOneWidget);
    expect(find.text('Selected cable size: 16 sq.mm'), findsOneWidget);
    expect(find.text('Number of runs: 1'), findsOneWidget);
    expect(find.text('Current per run: 60 A'), findsOneWidget);
    expect(find.text('Base ampacity: 66 A'), findsOneWidget);
    expect(find.text('Corrected ampacity: 66 A'), findsOneWidget);
    await openReferences(tester);
    expect(find.text('Source ampacity table: Table 5-21'), findsOneWidget);
    expect(find.text('Source column: C7'), findsOneWidget);
  });

  testWidgets('NYY executes and presents the explicit C2 route', (
    tester,
  ) async {
    tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
    tester.binding.window.devicePixelRatioTestValue = 1;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(
      tester,
      product: 'NYY',
      loadCurrent: '50',
      loadedConductors: '2',
      coreType: 'Single Core',
    );
    await enterIec10SupplementalInputs(tester);
    await scrollToKey(tester, const Key('v2-check-inputs'));
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(find.text('Cable product / standard: NYY'), findsOneWidget);
    expect(find.text('Loaded conductors: 2'), findsOneWidget);
    expect(find.text('Selected cable size: 10 sq.mm'), findsOneWidget);
    expect(find.text('Base ampacity: 57 A'), findsOneWidget);
    expect(find.text('Voltage drop: NOT VERIFIED'), findsOneWidget);
    await openReferences(tester);
    expect(find.text('Profile reference: Table 5-48'), findsOneWidget);
    expect(find.text('Installation source: Table 5-47'), findsOneWidget);
    expect(find.text('Source ampacity table: Table 5-21'), findsOneWidget);
    expect(find.text('Source column: C2'), findsOneWidget);
  });

  testWidgets('IEC 60502-1 executes the explicit C4 construction', (
    tester,
  ) async {
    tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
    tester.binding.window.devicePixelRatioTestValue = 1;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(
      tester,
      product: 'IEC 60502-1',
      loadCurrent: '50',
      loadedConductors: '2',
      coreType: 'Single Core',
    );
    await enterIec10SupplementalInputs(tester);
    await selectDropdown(tester, const Key('v2-iec10-insulation'), 'xlpe');
    await selectDropdown(
      tester,
      const Key('v2-iec10-conductor-temperature-class'),
      'XLPE/EPR 90°C',
    );
    await selectDropdown(
      tester,
      const Key('v2-routing-electrical-system'),
      'Single-phase AC',
    );
    await selectDropdown(tester, const Key('v2-outer-sheath'), 'Present');
    await scrollToKey(tester, const Key('v2-check-inputs'));
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(find.text('Cable product / standard: IEC 60502-1'), findsOneWidget);
    expect(find.text('Selected cable size: 6 sq.mm'), findsOneWidget);
    expect(find.text('Base ampacity: 54 A'), findsOneWidget);
    expect(find.text('Voltage drop: NOT VERIFIED'), findsOneWidget);
    await openReferences(tester);
    expect(
      find.text('Outer sheath: Present (Explicit supplemental input)'),
      findsOneWidget,
    );
    expect(find.text('Installation source: Table 5-47'), findsOneWidget);
    expect(find.text('Source ampacity table: Table 5-21'), findsOneWidget);
    expect(find.text('Source column: C4'), findsOneWidget);
  });

  testWidgets('VAF 100 A displays the backend-selected two-run design', (
    tester,
  ) async {
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(tester, product: 'VAF', loadCurrent: '100');
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(controller.calls, 1);
    expect(find.text('Cable product / standard: VAF'), findsOneWidget);
    expect(find.text('Selected cable size: 10 sq.mm'), findsOneWidget);
    expect(find.text('Number of runs: 2'), findsOneWidget);
    expect(find.text('Current per run: 50 A'), findsOneWidget);
    expect(find.text('Base ampacity: 56 A'), findsOneWidget);
    expect(find.text('Corrected ampacity: 56 A'), findsOneWidget);
    expect(find.text('Voltage drop: NOT VERIFIED'), findsOneWidget);
    await openReferences(tester);
    expect(find.text('Installation source: Table 5-47'), findsOneWidget);
    expect(find.text('Profile reference: Table 5-48'), findsOneWidget);
    expect(find.text('Source ampacity table: Table 5-21'), findsOneWidget);
    expect(find.text('Source column: C1'), findsOneWidget);
  });

  testWidgets('two-run VAF VD failure preserves the selected ampacity design', (
    tester,
  ) async {
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(tester, product: 'VAF', loadCurrent: '100');
    await enterReadyVoltageDropInputs(tester, length: '1000', allowable: '.01');
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(controller.calls, 1);
    expect(find.text('Selected cable size: 10 sq.mm'), findsOneWidget);
    expect(find.text('Number of runs: 2'), findsOneWidget);
    expect(find.text('Current per run: 50 A'), findsOneWidget);
    expect(find.text('Voltage drop: FAILED'), findsOneWidget);
    expect(find.textContaining('Voltage drop margin: -'), findsOneWidget);
  });

  testWidgets('two-run VAF VD verification uses the selected current per run', (
    tester,
  ) async {
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(tester, product: 'VAF', loadCurrent: '100');
    await enterReadyVoltageDropInputs(tester, length: '10', allowable: '99');
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(controller.calls, 1);
    expect(find.text('Selected cable size: 10 sq.mm'), findsOneWidget);
    expect(find.text('Number of runs: 2'), findsOneWidget);
    expect(find.text('Current per run: 50 A'), findsOneWidget);
    expect(find.text('Voltage drop: VERIFIED'), findsOneWidget);
    expect(find.text('mV/A/m: 4.4'), findsOneWidget);
    await openReferences(tester);
    expect(find.text('Source ampacity table: Table 5-21'), findsOneWidget);
    expect(find.text('Voltage-drop table: Table 9.2'), findsOneWidget);
  });

  testWidgets('an input edit after readiness invalidates the execution gate', (
    tester,
  ) async {
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(tester, product: 'VAF');
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(find.text('Cable product / standard: VAF'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('v2-ambient-temperature')).first,
      '45',
    );
    await scrollToKey(tester, const Key('v2-calculate'));
    expect(find.text('Inputs ready for calculation'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('v2-calculate')).first)
          .onPressed,
      isNull,
    );
    expect(controller.calls, 1);
    expect(find.text('Result: Cable design'), findsOneWidget);
  });

  testWidgets('explicit VD context verifies independently after VAF ampacity', (
    tester,
  ) async {
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(tester, product: 'VAF');
    await enterReadyVoltageDropInputs(tester, length: '10', allowable: '99');
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await completeExecution(tester, controller);
    expect(controller.calls, 1);
    expect(find.text('Cable product / standard: VAF'), findsOneWidget);
    expect(find.text('Voltage drop: VERIFIED'), findsOneWidget);
  });

  testWidgets(
    'failed VD retains the selected VAF cable and runs without retry',
    (tester) async {
      final controller = _ControllerSpy();
      await tester.pumpWidget(
        MaterialApp(
          home: CableDesignV2Page(
            activation: activation,
            controller: controller,
          ),
        ),
      );
      await enterReadyAmpacityInputs(tester, product: 'VAF');
      await enterReadyVoltageDropInputs(
        tester,
        length: '1000',
        allowable: '.01',
      );
      await tester.tap(find.byKey(const Key('v2-calculate')).first);
      await completeExecution(tester, controller);
      expect(controller.calls, 1);
      expect(find.text('Cable product / standard: VAF'), findsOneWidget);
      expect(find.text('Number of runs: 1'), findsOneWidget);
      expect(find.text('Voltage drop: FAILED'), findsOneWidget);
    },
  );

  testWidgets('insufficient mapping never calls the controller', (
    tester,
  ) async {
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    expect(find.text('Inputs are incomplete'), findsOneWidget);
    expect(controller.calls, 0);
  });

  testWidgets('invalid mapping never calls the controller', (tester) async {
    final controller = _ControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(tester, product: 'VAF');
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('v2-load-current')).first, '0');
    await scrollToKey(tester, const Key('v2-check-inputs'));
    await tester.ensureVisible(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('v2-check-inputs')).first);
    await tester.pump();
    expect(find.text('Inputs are invalid'), findsOneWidget);
    expect(controller.calls, 0);
  });

  testWidgets('controller insufficiency is presented without fallback', (
    tester,
  ) async {
    final controller = _InsufficientControllerSpy();
    final presenter = _PresenterSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(
          activation: activation,
          controller: controller,
          presenter: presenter,
        ),
      ),
    );
    await enterReadyAmpacityInputs(tester, product: 'VAF');
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await tester.runAsync(() => controller.completion!);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.calls, 1);
    expect(presenter.calls, 1);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(find.text('Result: More design input is required'), findsOneWidget);
  });

  testWidgets('a running execution blocks a duplicate Calculate tap', (
    tester,
  ) async {
    final controller = _PendingControllerSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(activation: activation, controller: controller),
      ),
    );
    await enterReadyAmpacityInputs(tester, product: 'VAF');
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await tester.pump();
    expect(controller.calls, 1);
    expect(find.text('Calculating...'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('v2-calculate')).first)
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('v2-calculate')).first);
    await tester.pump();
    expect(controller.calls, 1);
    controller.release.complete();
    await tester.pumpAndSettle();
  });
}
