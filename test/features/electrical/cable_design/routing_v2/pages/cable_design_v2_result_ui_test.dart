import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/ampacity_routing_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_execution_controller_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_execution_caller_adaptation_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_v2_presentation_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_workflow.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/resolved_correction_state_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/voltage_drop_verification_status_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_caller_adaptation_result.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_caller_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_controller_result_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_v2_presentation_state.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_workflow_activation.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/pages/cable_design_v2_page.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_execution_controller_v2.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_v2_result_presenter.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';

class _PresentationController extends CableDesignExecutionControllerV2 {
  @override
  Future<CableDesignExecutionControllerResultV2> execute(
    CableDesignExecutionCallerInput input,
  ) async => const CableDesignExecutionControllerResultV2(
    status: CableDesignExecutionControllerStatusV2.insufficient,
    adaptation: CableDesignExecutionCallerAdaptationResult(
      status: CableDesignExecutionCallerAdaptationStatus.insufficient,
      request: null,
    ),
  );
}

class _StatePresenter extends CableDesignV2ResultPresenter {
  const _StatePresenter(this.state);
  final CableDesignV2PresentationState state;

  @override
  CableDesignV2PresentationState present(
    CableDesignExecutionControllerResultV2 result,
  ) => state;
}

void main() {
  const activation = CableDesignWorkflowActivation(
    workflow: CableDesignWorkflow.advancedCableDesign,
  );

  const selected = CableDesignV2SelectedDesignPresentation(
    cableIdentityDisplay: 'VAF',
    cableSizeSqmm: 10,
    runs: 1,
    currentPerRun: 10,
    baseAmpacity: 56,
    correctedAmpacityPerRun: 50.96,
  );

  const ampacity = CableDesignV2AmpacityPresentation(
    status: AmpacityRoutingStatus.resolved,
    installationGroupNumber: 3,
    sourceTableId: '5-21',
    sourceColumnId: 'C1',
    baseAmpacity: 56,
    correctedAmpacityPerRun: 50.96,
    corrections: [
      CableDesignV2CorrectionPresentation(
        name: 'Temperature correction',
        state: ResolvedCorrectionStateV2.applied,
        factor: 0.91,
        sourceReference: 'Table 5-43',
      ),
      CableDesignV2CorrectionPresentation(
        name: 'Grouping correction',
        state: ResolvedCorrectionStateV2.notRequired,
      ),
    ],
    sourceReferences: ['Table 5-21'],
    correctionReferences: ['Table 5-43'],
  );

  const notVerified = CableDesignV2PresentationState(
    status: CableDesignV2PresentationStatus.voltageDropNotVerified,
    headline: 'Voltage drop not verified',
    message: 'Ampacity is available; voltage-drop facts were not supplied.',
    selectedDesign: selected,
    ampacitySummary: ampacity,
    voltageDropSummary: CableDesignV2VoltageDropPresentation(
      status: VoltageDropVerificationStatusV2.notVerified,
    ),
  );

  const verified = CableDesignV2PresentationState(
    status: CableDesignV2PresentationStatus.voltageDropVerified,
    headline: 'Cable design verified',
    message: 'Ampacity and voltage drop are verified.',
    selectedDesign: selected,
    ampacitySummary: ampacity,
    voltageDropSummary: CableDesignV2VoltageDropPresentation(
      status: VoltageDropVerificationStatusV2.verified,
      sourceTableId: '9.2',
      mvPerAperM: 4.4,
      circuitLengthM: 30,
      voltageDropV: 1.32,
      voltageDropPercent: 0.57,
      allowableVoltageDropPercent: 3,
      marginPercent: 2.43,
      phase: VoltagePhase.singlePhase,
      installationGroup: VoltageDropInstallationGroup.group1,
      insulation: CableInsulation.pvc,
      coreType: CoreType.multiCore,
      sourceReferences: ['Table 9.2'],
    ),
  );

  const failed = CableDesignV2PresentationState(
    status: CableDesignV2PresentationStatus.voltageDropFailed,
    headline: 'Voltage drop failed',
    message:
        'The selected ampacity design is retained; no automatic change was made.',
    selectedDesign: selected,
    ampacitySummary: ampacity,
    voltageDropSummary: CableDesignV2VoltageDropPresentation(
      status: VoltageDropVerificationStatusV2.failed,
      sourceTableId: '9.2',
      mvPerAperM: 4.4,
      circuitLengthM: 1000,
      voltageDropV: 44,
      voltageDropPercent: 19.13,
      allowableVoltageDropPercent: 3,
      marginPercent: -16.13,
      sourceReferences: ['Table 9.2'],
    ),
  );

  Future<void> selectDropdown(
    WidgetTester tester,
    Key key,
    String label,
  ) async {
    await tester.ensureVisible(find.byKey(key).first);
    await tester.tap(find.byKey(key).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> prepareAndCalculate(
    WidgetTester tester,
    CableDesignV2PresentationState state,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CableDesignV2Page(
          activation: activation,
          controller: _PresentationController(),
          presenter: _StatePresenter(state),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('v2-load-current')), '10');
    await selectDropdown(tester, const Key('v2-phase-system'), '1Ø');
    await selectDropdown(tester, const Key('v2-loaded-conductors'), '2');
    await selectDropdown(tester, const Key('v2-core-type'), 'Multi Core');
    await tester.enterText(
      find.byKey(const Key('v2-ambient-temperature')),
      '40',
    );
    await tester.tap(find.text('VAF'));
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
    await tester.tap(find.byKey(const Key('v2-check-inputs')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('v2-calculate')));
    await tester.pump();
    await tester.pump();
  }

  Future<void> openReferences(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Reference / Calculation Details'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Reference / Calculation Details'));
    await tester.pump();
    await tester.tap(find.text('Reference / Calculation Details'));
    await tester.pumpAndSettle();
  }

  testWidgets('initial state has no engineering design or references', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CableDesignV2Page(activation: activation)),
    );
    await tester.scrollUntilVisible(
      find.text('Result: Cable design'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('DESIGN SUMMARY'), findsNothing);
    expect(find.text('Reference / Calculation Details'), findsNothing);
  });

  testWidgets('resolved summary presents selected VAF design and corrections', (
    tester,
  ) async {
    await prepareAndCalculate(tester, notVerified);
    expect(find.text('DESIGN SUMMARY'), findsOneWidget);
    expect(find.text('Cable product / standard: VAF'), findsOneWidget);
    expect(find.text('Selected cable size: 10 sq.mm'), findsOneWidget);
    expect(find.text('Number of runs: 1'), findsOneWidget);
    expect(find.text('Current per run: 10 A'), findsOneWidget);
    expect(find.text('Base ampacity: 56 A'), findsOneWidget);
    expect(find.text('Corrected ampacity: 50.96 A'), findsOneWidget);
    expect(find.text('Ampacity: Resolved'), findsOneWidget);
    expect(
      find.text('Temperature correction: 0.91 — Table 5-43'),
      findsOneWidget,
    );
    expect(
      find.text('Grouping correction: Not required by source'),
      findsOneWidget,
    );
    expect(find.textContaining('Grouping correction: 1'), findsNothing);
  });

  testWidgets('VAF-G identity is displayed without a legacy cable field', (
    tester,
  ) async {
    const vafG = CableDesignV2PresentationState(
      status: CableDesignV2PresentationStatus.voltageDropNotVerified,
      headline: 'Voltage drop not verified',
      message: 'Ampacity is available.',
      selectedDesign: CableDesignV2SelectedDesignPresentation(
        cableIdentityDisplay: 'VAF-G',
        cableSizeSqmm: 10,
        runs: 1,
        currentPerRun: 10,
        baseAmpacity: 56,
        correctedAmpacityPerRun: 56,
      ),
      ampacitySummary: ampacity,
      voltageDropSummary: CableDesignV2VoltageDropPresentation(
        status: VoltageDropVerificationStatusV2.notVerified,
      ),
    );
    await prepareAndCalculate(tester, vafG);
    expect(find.text('Cable product / standard: VAF-G'), findsOneWidget);
    expect(find.textContaining('CableType'), findsNothing);
    expect(find.textContaining('InstallationMethod'), findsNothing);
  });

  testWidgets('verified voltage-drop details retain independent VD values', (
    tester,
  ) async {
    await prepareAndCalculate(tester, verified);
    expect(find.text('Voltage drop: VERIFIED'), findsOneWidget);
    expect(find.text('mV/A/m: 4.4'), findsOneWidget);
    expect(find.text('Circuit length: 30 m'), findsOneWidget);
    expect(find.text('Voltage drop: 1.32 V'), findsOneWidget);
    expect(find.text('Voltage drop: 0.57 %'), findsOneWidget);
    expect(find.text('Allowable voltage drop: 3 %'), findsOneWidget);
    expect(find.text('Voltage drop margin: 2.43 %'), findsOneWidget);
  });

  testWidgets('failed voltage drop preserves ampacity design and margin', (
    tester,
  ) async {
    await prepareAndCalculate(tester, failed);
    expect(find.text('Ampacity: Resolved'), findsOneWidget);
    expect(find.text('Selected cable size: 10 sq.mm'), findsOneWidget);
    expect(find.text('Number of runs: 1'), findsOneWidget);
    expect(find.text('Voltage drop: FAILED'), findsOneWidget);
    expect(find.text('Voltage drop margin: -16.13 %'), findsOneWidget);
    expect(find.textContaining('automatic change was made'), findsOneWidget);
  });

  testWidgets(
    'traceability keeps ampacity correction and VD references separate',
    (tester) async {
      await prepareAndCalculate(tester, verified);
      expect(find.text('Source column: C1'), findsNothing);
      expect(find.textContaining('Table 5-21'), findsNothing);
      await openReferences(tester);
      expect(find.text('AMPACITY'), findsOneWidget);
      expect(find.text('Resolved installation group: Group 3'), findsOneWidget);
      expect(find.text('Source ampacity table: Table 5-21'), findsOneWidget);
      expect(find.text('Source column: C1'), findsOneWidget);
      expect(find.text('Base ampacity reference: Table 5-21'), findsOneWidget);
      expect(find.text('CORRECTIONS'), findsOneWidget);
      expect(find.text('Correction reference: Table 5-43'), findsOneWidget);
      expect(find.text('VOLTAGE DROP'), findsOneWidget);
      expect(find.text('Voltage-drop table: Table 9.2'), findsOneWidget);
      expect(find.text('VD reference: Table 9.2'), findsOneWidget);
    },
  );

  testWidgets(
    'no match and no candidate retain presenter state without a design',
    (tester) async {
      const noMatch = CableDesignV2PresentationState(
        status: CableDesignV2PresentationStatus.ampacityUnresolved,
        headline: 'Ampacity source does not match',
        message: 'No approved source combination matches the supplied facts.',
        ampacitySummary: CableDesignV2AmpacityPresentation(
          status: AmpacityRoutingStatus.noMatch,
        ),
      );
      await prepareAndCalculate(tester, noMatch);
      expect(find.text('Ampacity: No Match'), findsOneWidget);
      expect(find.text('DESIGN SUMMARY'), findsNothing);

      const noCandidate = CableDesignV2PresentationState(
        status: CableDesignV2PresentationStatus.ampacityUnresolved,
        headline: 'No ampacity candidate was selected',
        message: 'No source-backed candidate satisfies the request.',
        ampacitySummary: CableDesignV2AmpacityPresentation(
          status: AmpacityRoutingStatus.noCandidate,
        ),
      );
      await prepareAndCalculate(tester, noCandidate);
      expect(find.text('Ampacity: No Candidate'), findsOneWidget);
      expect(find.text('DESIGN SUMMARY'), findsNothing);
    },
  );

  testWidgets(
    'controller-insufficient presentation is rendered without a design',
    (tester) async {
      const needsInput = CableDesignV2PresentationState(
        status: CableDesignV2PresentationStatus.needsInput,
        headline: 'More design input is required',
        message: 'Controller requires additional input.',
        missingInputs: ['controllerInput'],
      );
      await prepareAndCalculate(tester, needsInput);
      expect(
        find.text('Result: More design input is required'),
        findsOneWidget,
      );
      expect(find.text('DESIGN SUMMARY'), findsNothing);
    },
  );
}
