import 'package:flutter/material.dart';

import '../../enums/core_type.dart';
import '../../enums/phase_system.dart';
import '../../models/cable_routing_identity.dart';
import '../../../voltage_drop/enums/cable_arrangement.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../../../voltage_drop/enums/voltage_drop_installation_group.dart';
import '../../../voltage_drop/enums/voltage_phase.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/cable_design_v2_input_mapping_status.dart';
import '../enums/cable_design_v2_presentation_status.dart';
import '../../enums/cable_design_routing_mode.dart';
import '../enums/cable_design_workflow.dart';
import '../enums/installation_environment.dart';
import '../enums/installation_support.dart';
import '../enums/resolved_correction_state_v2.dart';
import '../enums/routing_property_source.dart';
import '../enums/voltage_drop_verification_status_v2.dart';
import '../models/cable_design_v2_input_state.dart';
import '../models/cable_design_v2_input_mapping_result.dart';
import '../models/cable_design_v2_presentation_state.dart';
import '../models/cable_design_execution_caller_input.dart';
import '../models/cable_design_workflow_activation.dart';
import '../services/cable_design_v2_input_mapper.dart';
import '../services/cable_design_execution_controller_v2.dart';
import '../services/cable_design_v2_result_presenter.dart';

/// Isolated shell for the future Advanced Cable Design workflow.
///
/// This widget executes only an explicitly ready V2 request through the
/// branch-safe controller and renders its already-computed presentation state.
class CableDesignV2Page extends StatefulWidget {
  CableDesignV2Page({
    super.key,
    required this.activation,
    CableDesignExecutionControllerV2? controller,
    CableDesignV2ResultPresenter? presenter,
  }) : assert(
         activation.workflow == CableDesignWorkflow.advancedCableDesign,
         'CableDesignV2Page requires explicit Advanced Cable Design activation.',
       ),
       controller = controller ?? CableDesignExecutionControllerV2(),
       presenter = presenter ?? const CableDesignV2ResultPresenter();

  final CableDesignWorkflowActivation activation;
  final CableDesignExecutionControllerV2 controller;
  final CableDesignV2ResultPresenter presenter;

  @override
  State<CableDesignV2Page> createState() => _CableDesignV2PageState();
}

class _CableDesignV2PageState extends State<CableDesignV2Page> {
  static const _inputMapper = CableDesignV2InputMapper();
  CableDesignV2InputState _inputState = const CableDesignV2InputState();
  CableDesignV2PresentationState _presentationState =
      const CableDesignV2PresentationState.initial();
  CableDesignV2InputMappingResult? _mappingResult;
  _ExecutionState _executionState = _ExecutionState.idle;

  bool get _canCalculate =>
      _mappingResult?.status == CableDesignV2InputMappingStatus.ready &&
      _executionState != _ExecutionState.running;

  void _replaceInputState({
    double? loadCurrent,
    PhaseSystem? phaseSystem,
    int? loadedConductors,
    CoreType? coreType,
    double? ambientTemperature,
    CableRoutingIdentity? identity,
    Set<InstallationEnvironment>? environments,
    Set<InstallationSupport>? supports,
    bool? verifyVoltageDrop,
    VoltagePhase? voltageDropPhase,
    CableInsulation? voltageDropInsulation,
    CoreType? voltageDropCoreType,
    VoltageDropInstallationGroup? voltageDropInstallationGroup,
    CableArrangement? voltageDropArrangement,
    double? circuitLengthM,
    double? systemVoltage,
    double? allowableVoltageDropPercent,
    bool updateLoadCurrent = false,
    bool updateAmbientTemperature = false,
    bool updateCircuitLengthM = false,
    bool updateSystemVoltage = false,
    bool updateAllowableVoltageDropPercent = false,
  }) {
    setState(() {
      _inputState = CableDesignV2InputState(
        loadCurrent: updateLoadCurrent ? loadCurrent : _inputState.loadCurrent,
        phaseSystem: phaseSystem ?? _inputState.phaseSystem,
        loadedConductors: loadedConductors ?? _inputState.loadedConductors,
        coreType: coreType ?? _inputState.coreType,
        ambientTemperature: updateAmbientTemperature
            ? ambientTemperature
            : _inputState.ambientTemperature,
        identity: identity ?? _inputState.identity,
        environments: environments ?? _inputState.environments,
        supports: supports ?? _inputState.supports,
        hasOuterSheath: _inputState.hasOuterSheath,
        spacingAtLeastCableDiameter: _inputState.spacingAtLeastCableDiameter,
        ventilationOpeningPercent: _inputState.ventilationOpeningPercent,
        supplementalCableProperties: _inputState.supplementalCableProperties,
        verifyVoltageDrop: verifyVoltageDrop ?? _inputState.verifyVoltageDrop,
        voltageDropPhase: voltageDropPhase ?? _inputState.voltageDropPhase,
        voltageDropInsulation:
            voltageDropInsulation ?? _inputState.voltageDropInsulation,
        voltageDropCoreType:
            voltageDropCoreType ?? _inputState.voltageDropCoreType,
        voltageDropInstallationGroup:
            voltageDropInstallationGroup ??
            _inputState.voltageDropInstallationGroup,
        voltageDropArrangement:
            voltageDropArrangement ?? _inputState.voltageDropArrangement,
        circuitLengthM: updateCircuitLengthM
            ? circuitLengthM
            : _inputState.circuitLengthM,
        systemVoltage: updateSystemVoltage
            ? systemVoltage
            : _inputState.systemVoltage,
        allowableVoltageDropPercent: updateAllowableVoltageDropPercent
            ? allowableVoltageDropPercent
            : _inputState.allowableVoltageDropPercent,
      );
      _mappingResult = null;
      _presentationState = const CableDesignV2PresentationState.initial();
      _executionState = _ExecutionState.idle;
    });
  }

  void _checkInputs() {
    setState(() => _mappingResult = _inputMapper.map(_inputState));
  }

  void _replaceVoltageDropState({
    VoltagePhase? voltageDropPhase,
    CableInsulation? voltageDropInsulation,
    CoreType? voltageDropCoreType,
    VoltageDropInstallationGroup? voltageDropInstallationGroup,
    CableArrangement? voltageDropArrangement,
    double? circuitLengthM,
    double? systemVoltage,
    double? allowableVoltageDropPercent,
    bool? updateCircuitLengthM,
    bool? updateSystemVoltage,
    bool? updateAllowableVoltageDropPercent,
  }) {
    _replaceInputState(
      voltageDropPhase: voltageDropPhase,
      voltageDropInsulation: voltageDropInsulation,
      voltageDropCoreType: voltageDropCoreType,
      voltageDropInstallationGroup: voltageDropInstallationGroup,
      voltageDropArrangement: voltageDropArrangement,
      circuitLengthM: circuitLengthM,
      systemVoltage: systemVoltage,
      allowableVoltageDropPercent: allowableVoltageDropPercent,
      updateCircuitLengthM: updateCircuitLengthM ?? false,
      updateSystemVoltage: updateSystemVoltage ?? false,
      updateAllowableVoltageDropPercent:
          updateAllowableVoltageDropPercent ?? false,
    );
  }

  Future<void> _calculate() async {
    final mapped = _mappingResult;
    if (mapped?.status != CableDesignV2InputMappingStatus.ready ||
        mapped?.ampacityRequest == null ||
        _executionState == _ExecutionState.running) {
      return;
    }
    setState(() => _executionState = _ExecutionState.running);
    try {
      final controllerResult = await widget.controller.execute(
        CableDesignExecutionCallerInput(
          routingMode: CableDesignRoutingMode.routingV2,
          routingV2CableRequest: mapped!.ampacityRequest,
          routingV2VoltageDropContext: mapped.voltageDropContext,
        ),
      );
      if (!mounted) return;
      setState(() {
        _presentationState = widget.presenter.present(controllerResult);
        _executionState = _ExecutionState.completed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _presentationState = const CableDesignV2PresentationState(
          status: CableDesignV2PresentationStatus.invalidInput,
          headline: 'Cable design could not be completed',
          message: 'The calculation could not be completed. Review the inputs.',
        );
        _executionState = _ExecutionState.completed;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Advanced Cable Design')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Electrical Load',
          child: Column(
            children: [
              TextFormField(
                key: const Key('v2-load-current'),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Load current (A)',
                ),
                onChanged: (value) => _replaceInputState(
                  loadCurrent: double.tryParse(value),
                  updateLoadCurrent: true,
                ),
              ),
              DropdownButtonFormField<PhaseSystem>(
                key: const Key('v2-phase-system'),
                value: _inputState.phaseSystem,
                decoration: const InputDecoration(labelText: 'Phase / system'),
                items: PhaseSystem.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => _replaceInputState(phaseSystem: value),
              ),
              DropdownButtonFormField<int>(
                key: const Key('v2-loaded-conductors'),
                value: _inputState.loadedConductors,
                decoration: const InputDecoration(
                  labelText: 'Loaded conductors',
                ),
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                ],
                onChanged: (value) =>
                    _replaceInputState(loadedConductors: value),
              ),
              DropdownButtonFormField<CoreType>(
                key: const Key('v2-core-type'),
                value: _inputState.coreType,
                decoration: const InputDecoration(labelText: 'Core type'),
                items: CoreType.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => _replaceInputState(coreType: value),
              ),
              TextFormField(
                key: const Key('v2-ambient-temperature'),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ambient temperature (°C)',
                ),
                onChanged: (value) => _replaceInputState(
                  ambientTemperature: double.tryParse(value),
                  updateAmbientTemperature: true,
                ),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Cable Product',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cable product / standard'),
              RadioListTile<CableRoutingIdentity>(
                title: const Text('VAF'),
                value: CableRoutingIdentity.vaf,
                groupValue: _inputState.identity,
                onChanged: (value) => _replaceInputState(identity: value),
              ),
              RadioListTile<CableRoutingIdentity>(
                title: const Text('VAF-G'),
                value: CableRoutingIdentity.vafG,
                groupValue: _inputState.identity,
                onChanged: (value) => _replaceInputState(identity: value),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Installation',
          child: Column(
            children: [
              DropdownButtonFormField<InstallationEnvironment>(
                key: const Key('v2-installation-environment'),
                value: _inputState.environments?.singleOrNull,
                decoration: const InputDecoration(labelText: 'Environment'),
                items: InstallationEnvironment.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => _replaceInputState(
                  environments: value == null ? null : {value},
                ),
              ),
              DropdownButtonFormField<InstallationSupport>(
                key: const Key('v2-installation-support'),
                value: _inputState.supports?.singleOrNull,
                decoration: const InputDecoration(
                  labelText: 'Support / enclosure',
                ),
                items: InstallationSupport.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => _replaceInputState(
                  supports: value == null ? null : {value},
                ),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Voltage Drop Verification',
          child: Column(
            children: [
              SwitchListTile(
                key: const Key('v2-verify-voltage-drop'),
                title: const Text('Verify voltage drop'),
                value: _inputState.verifyVoltageDrop,
                onChanged: (value) =>
                    _replaceInputState(verifyVoltageDrop: value),
              ),
              if (_inputState.verifyVoltageDrop)
                _VoltageDropInputs(
                  state: _inputState,
                  onChanged: _replaceVoltageDropState,
                ),
            ],
          ),
        ),
        _Section(
          title: 'Calculate / Result',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Check explicit inputs before calculation.'),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('v2-check-inputs'),
                onPressed: _checkInputs,
                child: const Text('Check inputs'),
              ),
              if (_mappingResult != null)
                _InputReadiness(result: _mappingResult!),
              ElevatedButton(
                key: const Key('v2-calculate'),
                onPressed: _canCalculate ? _calculate : null,
                child: Text(
                  _executionState == _ExecutionState.running
                      ? 'Calculating...'
                      : 'Calculate',
                ),
              ),
              if (_executionState == _ExecutionState.running)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 8),
              _ResultSummary(state: _presentationState),
            ],
          ),
        ),
      ],
    ),
  );
}

enum _ExecutionState { idle, running, completed }

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.state});
  final CableDesignV2PresentationState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedDesign;
    final ampacity = state.ampacitySummary;
    final voltageDrop = state.voltageDropSummary;
    final installationReference = state.installationReference;
    final cableProfile = state.cableProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Result: ${state.headline}'),
        Text(state.message),
        if (selected != null) ...[
          const SizedBox(height: 16),
          _ResultSection(
            title: 'DESIGN SUMMARY',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cable product / standard: '
                  '${selected.cableIdentityDisplay ?? 'Not specified'}',
                ),
                Text(
                  'Selected cable size: ${_format(selected.cableSizeSqmm)} sq.mm',
                ),
                Text('Number of runs: ${selected.runs}'),
                Text('Current per run: ${_format(selected.currentPerRun)} A'),
                Text('Base ampacity: ${_format(selected.baseAmpacity)} A'),
                Text(
                  'Corrected ampacity: '
                  '${_format(selected.correctedAmpacityPerRun)} A',
                ),
              ],
            ),
          ),
        ],
        if (ampacity != null || voltageDrop != null) ...[
          const SizedBox(height: 16),
          _ResultSection(
            title: 'ENGINEERING DETAILS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ampacity != null) ...[
                  Text('Ampacity: ${_ampacityStatus(ampacity.status)}'),
                  if (ampacity.reason != null) Text(ampacity.reason!),
                  if (ampacity.corrections.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Corrections'),
                    for (final correction in ampacity.corrections)
                      Text(_correctionText(correction)),
                  ],
                ],
                if (voltageDrop != null) ...[
                  if (ampacity != null) const SizedBox(height: 12),
                  Text(
                    'Voltage drop: ${_voltageDropStatus(voltageDrop.status)}',
                  ),
                  if (voltageDrop.reason != null) Text(voltageDrop.reason!),
                  if (voltageDrop.status ==
                          VoltageDropVerificationStatusV2.notVerified &&
                      voltageDrop.reason == null)
                    const Text(
                      'Voltage drop was not verified; the ampacity design remains available.',
                    ),
                  if (voltageDrop.status ==
                          VoltageDropVerificationStatusV2.verified ||
                      voltageDrop.status ==
                          VoltageDropVerificationStatusV2.failed) ...[
                    const SizedBox(height: 8),
                    if (voltageDrop.mvPerAperM case final value?)
                      Text('mV/A/m: ${_format(value)}'),
                    if (voltageDrop.circuitLengthM case final value?)
                      Text('Circuit length: ${_format(value)} m'),
                    if (voltageDrop.voltageDropV case final value?)
                      Text('Voltage drop: ${_format(value)} V'),
                    if (voltageDrop.voltageDropPercent case final value?)
                      Text('Voltage drop: ${_format(value)} %'),
                    if (voltageDrop.allowableVoltageDropPercent
                        case final value?)
                      Text('Allowable voltage drop: ${_format(value)} %'),
                    if (voltageDrop.marginPercent case final value?)
                      Text('Voltage drop margin: ${_format(value)} %'),
                  ],
                ],
              ],
            ),
          ),
        ],
        if (_hasTraceability(
          installationReference,
          cableProfile,
          ampacity,
          voltageDrop,
        )) ...[
          const SizedBox(height: 16),
          _TraceabilityDetails(
            installationReference: installationReference,
            cableProfile: cableProfile,
            ampacity: ampacity,
            voltageDrop: voltageDrop,
          ),
        ],
      ],
    );
  }

  static bool _hasTraceability(
    CableDesignV2InstallationReferencePresentation? installationReference,
    CableDesignV2CableProfilePresentation? cableProfile,
    CableDesignV2AmpacityPresentation? ampacity,
    CableDesignV2VoltageDropPresentation? voltageDrop,
  ) =>
      installationReference != null ||
      cableProfile != null ||
      ampacity?.installationGroupNumber != null ||
      ampacity?.sourceTableId != null ||
      ampacity?.sourceColumnId != null ||
      (ampacity?.sourceReferences.isNotEmpty ?? false) ||
      (ampacity?.correctionReferences.isNotEmpty ?? false) ||
      voltageDrop?.sourceTableId != null ||
      (voltageDrop?.sourceReferences.isNotEmpty ?? false);

  static String _ampacityStatus(AmpacityRoutingStatus status) =>
      switch (status) {
        AmpacityRoutingStatus.resolved => 'Resolved',
        AmpacityRoutingStatus.insufficient => 'Insufficient',
        AmpacityRoutingStatus.ambiguous => 'Ambiguous',
        AmpacityRoutingStatus.noMatch => 'No Match',
        AmpacityRoutingStatus.unsupported => 'Unsupported',
        AmpacityRoutingStatus.noCandidate => 'No Candidate',
      };

  static String _voltageDropStatus(VoltageDropVerificationStatusV2 status) =>
      switch (status) {
        VoltageDropVerificationStatusV2.notVerified => 'NOT VERIFIED',
        VoltageDropVerificationStatusV2.verified => 'VERIFIED',
        VoltageDropVerificationStatusV2.failed => 'FAILED',
        VoltageDropVerificationStatusV2.insufficient => 'INSUFFICIENT',
        VoltageDropVerificationStatusV2.unsupported => 'UNSUPPORTED',
      };

  static String _correctionText(
    CableDesignV2CorrectionPresentation correction,
  ) => switch (correction.state) {
    ResolvedCorrectionStateV2.applied =>
      '${correction.name}: ${_format(correction.factor)}'
          '${correction.sourceReference == null ? '' : ' — ${correction.sourceReference}'}',
    ResolvedCorrectionStateV2.notRequired =>
      '${correction.name}: ${correction.reason ?? 'Not required by source'}',
    ResolvedCorrectionStateV2.unresolved =>
      '${correction.name}: Unresolved'
          '${correction.reason == null ? '' : ' — ${correction.reason}'}',
  };

  static String _format(double? value) {
    if (value == null) return 'Unavailable';
    final fixed = value.toStringAsFixed(4);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _TraceabilityDetails extends StatelessWidget {
  const _TraceabilityDetails({
    required this.installationReference,
    required this.cableProfile,
    required this.ampacity,
    required this.voltageDrop,
  });
  final CableDesignV2InstallationReferencePresentation? installationReference;
  final CableDesignV2CableProfilePresentation? cableProfile;
  final CableDesignV2AmpacityPresentation? ampacity;
  final CableDesignV2VoltageDropPresentation? voltageDrop;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const Text('Reference / Calculation Details'),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    children: [
      if (installationReference != null)
        _InstallationReferences(reference: installationReference!),
      if (cableProfile != null) _CableProfileReferences(profile: cableProfile!),
      if (ampacity != null) _AmpacityReferences(ampacity: ampacity!),
      if (voltageDrop != null)
        _VoltageDropReferences(voltageDrop: voltageDrop!),
    ],
  );
}

class _InstallationReferences extends StatelessWidget {
  const _InstallationReferences({required this.reference});
  final CableDesignV2InstallationReferencePresentation reference;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('INSTALLATION REFERENCE'),
      Text('Installation source: ${reference.sourceReference}'),
      Text('Resolved installation group: Group ${reference.groupNumber}'),
      for (final characteristic in reference.characteristics)
        Text('Source characteristic: $characteristic'),
      const SizedBox(height: 8),
    ],
  );
}

class _CableProfileReferences extends StatelessWidget {
  const _CableProfileReferences({required this.profile});
  final CableDesignV2CableProfilePresentation profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('CABLE PROFILE'),
      Text('Routing cable identity: ${profile.identity}'),
      for (final reference in profile.sourceReferences)
        Text('Profile reference: $reference'),
      for (final property in profile.properties)
        Text(
          '${property.label}: ${property.value} '
          '(${_propertySourceLabel(property.source)})',
        ),
      const SizedBox(height: 8),
    ],
  );

  static String _propertySourceLabel(RoutingPropertySource source) =>
      switch (source) {
        RoutingPropertySource.cableProfile =>
          'Approved cable profile / master source',
        RoutingPropertySource.supplementalInput =>
          'Explicit supplemental input',
        RoutingPropertySource.installationReference =>
          'Table 5-47 installation resolution',
      };
}

class _AmpacityReferences extends StatelessWidget {
  const _AmpacityReferences({required this.ampacity});
  final CableDesignV2AmpacityPresentation ampacity;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('AMPACITY'),
      if (ampacity.installationGroupNumber case final group?)
        Text('Resolved installation group: Group $group'),
      if (ampacity.sourceTableId case final table?)
        Text('Source ampacity table: Table $table'),
      if (ampacity.sourceColumnId case final column?)
        Text('Source column: $column'),
      for (final reference in ampacity.sourceReferences)
        Text('Base ampacity reference: $reference'),
      const SizedBox(height: 8),
      const Text('CORRECTIONS'),
      for (final correction in ampacity.corrections)
        Text(_ResultSummary._correctionText(correction)),
      for (final reference in ampacity.correctionReferences)
        Text('Correction reference: $reference'),
    ],
  );
}

class _VoltageDropReferences extends StatelessWidget {
  const _VoltageDropReferences({required this.voltageDrop});
  final CableDesignV2VoltageDropPresentation voltageDrop;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      const Text('VOLTAGE DROP'),
      if (voltageDrop.sourceTableId case final table?)
        Text('Voltage-drop table: Table $table'),
      if (voltageDrop.phase case final phase?)
        Text('Phase / system: ${phase.name}'),
      if (voltageDrop.installationGroup case final group?)
        Text('VD installation group: ${group.displayName}'),
      if (voltageDrop.insulation case final insulation?)
        Text('Insulation: ${insulation.name}'),
      if (voltageDrop.coreType case final coreType?)
        Text('Core type: ${coreType.displayName}'),
      for (final reference in voltageDrop.sourceReferences)
        Text('VD reference: $reference'),
    ],
  );
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      child,
    ],
  );
}

class _InputReadiness extends StatelessWidget {
  const _InputReadiness({required this.result});
  final CableDesignV2InputMappingResult result;

  @override
  Widget build(BuildContext context) {
    final text = switch (result.status) {
      CableDesignV2InputMappingStatus.ready => 'Inputs ready for calculation',
      CableDesignV2InputMappingStatus.insufficient => 'Inputs are incomplete',
      CableDesignV2InputMappingStatus.invalid => 'Inputs are invalid',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (result.reason != null) Text(result.reason!),
          if (result.missingFields.isNotEmpty)
            Text('Missing: ${result.missingFields.join(', ')}'),
        ],
      ),
    );
  }
}

class _VoltageDropInputs extends StatelessWidget {
  const _VoltageDropInputs({required this.state, required this.onChanged});
  final CableDesignV2InputState state;
  final void Function({
    VoltagePhase? voltageDropPhase,
    CableInsulation? voltageDropInsulation,
    CoreType? voltageDropCoreType,
    VoltageDropInstallationGroup? voltageDropInstallationGroup,
    CableArrangement? voltageDropArrangement,
    double? circuitLengthM,
    double? systemVoltage,
    double? allowableVoltageDropPercent,
    bool? updateCircuitLengthM,
    bool? updateSystemVoltage,
    bool? updateAllowableVoltageDropPercent,
  })
  onChanged;

  bool get _arrangementRequired =>
      state.voltageDropCoreType == CoreType.singleCore &&
      state.voltageDropInstallationGroup != null &&
      !state.voltageDropInstallationGroup!.isGroup1_2_5;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      DropdownButtonFormField<VoltagePhase>(
        key: const Key('v2-vd-phase'),
        value: state.voltageDropPhase,
        decoration: const InputDecoration(labelText: 'VD phase / system'),
        items: VoltagePhase.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.name)),
            )
            .toList(),
        onChanged: (value) => onChanged(voltageDropPhase: value),
      ),
      DropdownButtonFormField<CableInsulation>(
        key: const Key('v2-vd-insulation'),
        value: state.voltageDropInsulation,
        decoration: const InputDecoration(labelText: 'VD insulation'),
        items: CableInsulation.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.name)),
            )
            .toList(),
        onChanged: (value) => onChanged(voltageDropInsulation: value),
      ),
      DropdownButtonFormField<CoreType>(
        key: const Key('v2-vd-core-type'),
        value: state.voltageDropCoreType,
        decoration: const InputDecoration(labelText: 'VD core type'),
        items: CoreType.values
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(value.displayName),
              ),
            )
            .toList(),
        onChanged: (value) => onChanged(voltageDropCoreType: value),
      ),
      DropdownButtonFormField<VoltageDropInstallationGroup>(
        key: const Key('v2-vd-installation-group'),
        value: state.voltageDropInstallationGroup,
        decoration: const InputDecoration(labelText: 'VD installation group'),
        items: VoltageDropInstallationGroup.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.name)),
            )
            .toList(),
        onChanged: (value) => onChanged(voltageDropInstallationGroup: value),
      ),
      if (_arrangementRequired)
        DropdownButtonFormField<CableArrangement>(
          key: const Key('v2-vd-arrangement'),
          value: state.voltageDropArrangement,
          decoration: const InputDecoration(labelText: 'VD arrangement'),
          items: CableArrangement.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.name)),
              )
              .toList(),
          onChanged: (value) => onChanged(voltageDropArrangement: value),
        ),
      TextFormField(
        key: const Key('v2-vd-length'),
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Circuit length (m)'),
        onChanged: (value) => onChanged(
          circuitLengthM: double.tryParse(value),
          updateCircuitLengthM: true,
        ),
      ),
      TextFormField(
        key: const Key('v2-vd-system-voltage'),
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'System voltage (V)'),
        onChanged: (value) => onChanged(
          systemVoltage: double.tryParse(value),
          updateSystemVoltage: true,
        ),
      ),
      TextFormField(
        key: const Key('v2-vd-allowable'),
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Allowable voltage drop (%)',
        ),
        onChanged: (value) => onChanged(
          allowableVoltageDropPercent: double.tryParse(value),
          updateAllowableVoltageDropPercent: true,
        ),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          child,
        ],
      ),
    ),
  );
}
