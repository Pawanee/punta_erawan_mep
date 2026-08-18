import 'package:flutter/material.dart';

import '../../enums/core_type.dart';
import '../../enums/phase_system.dart';
import '../../models/cable_routing_identity.dart';
import '../enums/cable_design_workflow.dart';
import '../enums/installation_environment.dart';
import '../enums/installation_support.dart';
import '../models/cable_design_v2_input_state.dart';
import '../models/cable_design_v2_presentation_state.dart';
import '../models/cable_design_workflow_activation.dart';

/// Isolated shell for the future Advanced Cable Design workflow.
///
/// This widget owns only explicit V2 UI state. It does not execute a design.
class CableDesignV2Page extends StatefulWidget {
  CableDesignV2Page({super.key, required this.activation})
    : assert(
        activation.workflow == CableDesignWorkflow.advancedCableDesign,
        'CableDesignV2Page requires explicit Advanced Cable Design activation.',
      );

  final CableDesignWorkflowActivation activation;

  @override
  State<CableDesignV2Page> createState() => _CableDesignV2PageState();
}

class _CableDesignV2PageState extends State<CableDesignV2Page> {
  CableDesignV2InputState _inputState = const CableDesignV2InputState();
  CableDesignV2PresentationState _presentationState =
      const CableDesignV2PresentationState.initial();

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
  }) {
    setState(() {
      _inputState = CableDesignV2InputState(
        loadCurrent: loadCurrent ?? _inputState.loadCurrent,
        phaseSystem: phaseSystem ?? _inputState.phaseSystem,
        loadedConductors: loadedConductors ?? _inputState.loadedConductors,
        coreType: coreType ?? _inputState.coreType,
        ambientTemperature:
            ambientTemperature ?? _inputState.ambientTemperature,
        identity: identity ?? _inputState.identity,
        environments: environments ?? _inputState.environments,
        supports: supports ?? _inputState.supports,
        hasOuterSheath: _inputState.hasOuterSheath,
        spacingAtLeastCableDiameter: _inputState.spacingAtLeastCableDiameter,
        ventilationOpeningPercent: _inputState.ventilationOpeningPercent,
        supplementalCableProperties: _inputState.supplementalCableProperties,
        verifyVoltageDrop: verifyVoltageDrop ?? _inputState.verifyVoltageDrop,
        voltageDropPhase: _inputState.voltageDropPhase,
        voltageDropInsulation: _inputState.voltageDropInsulation,
        voltageDropCoreType: _inputState.voltageDropCoreType,
        voltageDropInstallationGroup: _inputState.voltageDropInstallationGroup,
        voltageDropArrangement: _inputState.voltageDropArrangement,
        circuitLengthM: _inputState.circuitLengthM,
        systemVoltage: _inputState.systemVoltage,
        allowableVoltageDropPercent: _inputState.allowableVoltageDropPercent,
      );
    });
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
                onChanged: (value) =>
                    _replaceInputState(loadCurrent: double.tryParse(value)),
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Voltage-drop details will be entered explicitly in a future step.',
                  ),
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
              ElevatedButton(
                key: const Key('v2-calculate'),
                onPressed: null,
                child: const Text('Calculate'),
              ),
              const SizedBox(height: 8),
              Text('Result: ${_presentationState.headline}'),
              Text(_presentationState.message),
            ],
          ),
        ),
      ],
    ),
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
