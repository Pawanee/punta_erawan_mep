import 'package:flutter/material.dart';

import '../../enums/core_type.dart';
import '../../enums/phase_system.dart';
import '../../models/cable_routing_identity.dart';
import '../../../voltage_drop/enums/cable_arrangement.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../../../voltage_drop/enums/voltage_drop_installation_group.dart';
import '../../../voltage_drop/enums/voltage_phase.dart';
import '../enums/cable_design_v2_input_mapping_status.dart';
import '../enums/cable_design_v2_presentation_status.dart';
import '../../enums/cable_design_routing_mode.dart';
import '../enums/cable_design_workflow.dart';
import '../enums/installation_environment.dart';
import '../enums/installation_support.dart';
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
              const Text('Calculation connection pending.'),
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Result: ${state.headline}'),
      Text(state.message),
      if (state.selectedDesign case final selected?) ...[
        const SizedBox(height: 8),
        const Text('Design'),
        Text('Cable: ${selected.cableIdentityDisplay ?? 'Not specified'}'),
        Text('Selected cable size: ${selected.cableSizeSqmm} sq.mm'),
        Text('Runs: ${selected.runs}'),
        Text('Current / run: ${selected.currentPerRun} A'),
        Text('Corrected ampacity: ${selected.correctedAmpacityPerRun} A'),
      ],
      if (state.ampacitySummary != null)
        Text('Ampacity status: ${state.ampacitySummary!.status.name}'),
      if (state.voltageDropSummary != null)
        Text('Voltage drop status: ${state.voltageDropSummary!.status.name}'),
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
