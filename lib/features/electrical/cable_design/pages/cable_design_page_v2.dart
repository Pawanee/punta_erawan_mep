import 'package:flutter/material.dart';

import '../enums/cable_type.dart';
import '../enums/core_type.dart';
import '../enums/installation_method.dart';
import '../enums/phase_system.dart';

import '../../voltage_drop/enums/cable_arrangement.dart';
import '../../voltage_drop/enums/cable_insulation.dart';
import '../../voltage_drop/enums/voltage_drop_installation_group.dart';
import '../../voltage_drop/enums/voltage_phase.dart';
import '../../voltage_drop/models/voltage_drop_cable_selection_request.dart';
import '../../voltage_drop/models/voltage_drop_design_result.dart';
import '../../voltage_drop/services/voltage_drop_design_engine.dart';

import '../models/cable_design_request.dart';
import '../policies/approved_cable_type_context_policy.dart';
import '../policies/cable_context_policy.dart';
import '../widgets/cable_header.dart';
import '../widgets/result_row.dart';
import '../widgets/section_header.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Cable Design Page V2
///
/// PART 9 - Voltage Drop UI Integration
///
/// UI มีหน้าที่:
/// - รับ Input
/// - สร้าง Request
/// - เรียก VoltageDropDesignEngine
/// - แสดง Result
///
/// UI ไม่มี Logic คำนวณ Voltage Drop
/// ============================================================================

class CableDesignPageV2 extends StatefulWidget {
  const CableDesignPageV2({super.key});

  @override
  State<CableDesignPageV2> createState() => _CableDesignPageV2State();
}

class _CableDesignPageV2State extends State<CableDesignPageV2> {
  final VoltageDropDesignEngine _engine = VoltageDropDesignEngine();

  /// Approved CableType -> CableContext engineering policy.
  ///
  /// The same policy used by VoltageDropCableDesignEngine is used here
  /// so the voltage-drop reference follows the approved cable context.
  final CableContextPolicy _cableContextPolicy =
      const ApprovedCableTypeContextPolicy();

  final TextEditingController _currentController =
      TextEditingController();

  final TextEditingController _ambientController =
      TextEditingController(text: '30');

  final TextEditingController _groupingController =
      TextEditingController(text: '1');

  final TextEditingController _voltageDropController =
      TextEditingController(text: '3');

  final TextEditingController _lengthController =
      TextEditingController();

  final TextEditingController _systemVoltageController =
      TextEditingController(text: '400');

  PhaseSystem _phaseSystem = PhaseSystem.threePhase;
  CableType _cableType = CableType.iec01;
  InstallationMethod _installationMethod = InstallationMethod.group1;
  CoreType _coreType = CoreType.singleCore;

  int _loadedConductors = 3;

  CableArrangement? _arrangement;

  bool _isLoading = false;

  VoltageDropDesignResult? _result;

  @override
  void dispose() {
    _currentController.dispose();
    _ambientController.dispose();
    _groupingController.dispose();
    _voltageDropController.dispose();
    _lengthController.dispose();
    _systemVoltageController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _currentController.clear();
    _ambientController.text = '30';
    _groupingController.text = '1';
    _voltageDropController.text = '3';
    _lengthController.clear();
    _systemVoltageController.text =
        _phaseSystem.name == 'singlePhase' ? '230' : '400';

    setState(() {
      _phaseSystem = PhaseSystem.threePhase;
      _cableType = CableType.iec01;
      _installationMethod = InstallationMethod.group1;
      _coreType = CoreType.singleCore;
      _loadedConductors = 3;
      _arrangement = null;
      _result = null;
    });
  }

  Widget _space() => const SizedBox(height: 18);

  bool get _requiresArrangement {
    return _coreType.name == 'singleCore' &&
        !_isGroup1_2_5(_installationMethod.name);
  }

  bool _isGroup1_2_5(String name) {
    return name == 'group1' ||
        name == 'group2' ||
        name == 'group5';
  }

  /// Resolves insulation from the approved CableType -> CableContext policy.
  ///
  /// This keeps the UI aligned with the same engineering policy used by
  /// VoltageDropCableDesignEngine.
  ///
  /// Approved examples:
  /// - PVC cable types -> PVC -> Table 9.1 / 9.2
  /// - IEC 60502-1 -> XLPE -> Table 9.3 / 9.4
  CableInsulation _resolveInsulation() {
    return _cableContextPolicy.resolve(_cableType).insulation;
  }

  VoltagePhase _resolveVoltagePhase() {
    final phaseName = _phaseSystem.name;

    return VoltagePhase.values.firstWhere(
      (e) => e.name == phaseName,
      orElse: () => VoltagePhase.values.first,
    );
  }

  VoltageDropInstallationGroup _resolveInstallationGroup() {
    return VoltageDropInstallationGroup.values.firstWhere(
      (e) => e.name == _installationMethod.name,
      orElse: () => VoltageDropInstallationGroup.values.first,
    );
  }

  Future<void> _calculate() async {
    final loadCurrent =
        double.tryParse(_currentController.text) ?? 0;

    final lengthM =
        double.tryParse(_lengthController.text) ?? 0;

    final systemVoltage =
        double.tryParse(_systemVoltageController.text) ?? 0;

    final allowableVoltageDrop =
        double.tryParse(_voltageDropController.text) ?? 0;

    if (loadCurrent <= 0) {
      setState(() {
        _result = VoltageDropDesignResult.error(
          'Load Current ต้องมากกว่า 0 A',
        );
      });
      return;
    }

    if (lengthM <= 0) {
      setState(() {
        _result = VoltageDropDesignResult.error(
          'Cable Length ต้องมากกว่า 0 m',
        );
      });
      return;
    }

    if (systemVoltage <= 0) {
      setState(() {
        _result = VoltageDropDesignResult.error(
          'System Voltage ต้องมากกว่า 0 V',
        );
      });
      return;
    }

    if (allowableVoltageDrop <= 0) {
      setState(() {
        _result = VoltageDropDesignResult.error(
          'Allowable Voltage Drop ต้องมากกว่า 0 %',
        );
      });
      return;
    }

    if (_requiresArrangement && _arrangement == null) {
      setState(() {
        _result = VoltageDropDesignResult.error(
          'Single Core สำหรับ Group 3, 4, 6, 7 ต้องระบุ Cable Arrangement',
        );
      });
      return;
    }

    final cableRequest = CableDesignRequest(
      loadCurrent: loadCurrent,
      phaseSystem: _phaseSystem,
      cableType: _cableType,
      installationMethod: _installationMethod,
      loadedConductors: _loadedConductors,
      coreType: _coreType,
      ambientTemperature:
          double.tryParse(_ambientController.text) ?? 30,
      groupingCircuits:
          int.tryParse(_groupingController.text) ?? 1,
      allowableVoltageDrop: allowableVoltageDrop,
    );

    final request = VoltageDropCableSelectionRequest(
      cableRequest: cableRequest,
      insulation: _resolveInsulation(),
      phase: _resolveVoltagePhase(),
      lengthM: lengthM,
      systemVoltage: systemVoltage,
      allowableVoltageDropPercent: allowableVoltageDrop,
      installationGroup: _resolveInstallationGroup(),
      arrangement: _arrangement,
    );

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final result = await _engine.design(request);

      if (!mounted) return;

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _result = VoltageDropDesignResult.error(
          'Voltage Drop UI error: $e',
        );
        _isLoading = false;
      });
    }
  }

  String _number(double? value, {int digits = 2}) {
    if (value == null) return '-';
    return value.toStringAsFixed(digits);
  }

  Widget _buildDesignSummary() {
    final result = _result;

    if (result == null || !result.isSuccess) {
      return const SizedBox.shrink();
    }

    final allowable =
        double.tryParse(_voltageDropController.text) ?? 0;

    final actual = result.voltageDropPercent ?? 0;

    final margin = allowable - actual;

    final isPass = margin >= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: isPass ? Icons.verified : Icons.warning,
              title: 'Design Summary',
              color: isPass ? Colors.green : Colors.orange,
            ),
            _space(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPass
                    ? Colors.green.withValues(alpha: 0.08)
                    : Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPass
                      ? Colors.green.withValues(alpha: 0.35)
                      : Colors.orange.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isPass ? Icons.check_circle : Icons.warning,
                        color: isPass ? Colors.green : Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPass ? 'DESIGN PASS' : 'CHECK REQUIRED',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isPass ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ResultRow(
                    title: 'Selected Cable',
                    value: result.cableArrangement ?? '-',
                  ),
                  ResultRow(
                    title: 'Ampacity / Run',
                    value: '${_number(result.ampacityPerRun)} A',
                  ),
                  ResultRow(
                    title: 'Total Ampacity',
                    value: '${_number(result.totalAmpacity)} A',
                  ),
                  ResultRow(
                    title: 'Voltage Drop',
                    value: '${_number(result.voltageDropPercent)} %',
                  ),
                  ResultRow(
                    title: 'Allowable Voltage Drop',
                    value: '${_number(allowable)} %',
                  ),
                  ResultRow(
                    title: 'Voltage Drop Margin',
                    value: '${_number(margin)} %',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 480;
        final calculateButton = FilledButton.icon(
          onPressed: _isLoading ? null : _calculate,
          icon: const Icon(Icons.calculate),
          label: const Text('CALCULATE'),
        );
        final resetButton = OutlinedButton.icon(
          onPressed: _isLoading ? null : _resetForm,
          icon: const Icon(Icons.refresh),
          label: const Text('RESET'),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              calculateButton,
              const SizedBox(height: 12),
              resetButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: calculateButton),
            const SizedBox(width: 16),
            Expanded(child: resetButton),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'PUNTA ERAWAN MEP',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16 : 28,
                  vertical: isCompact ? 16 : 24,
                ),
            children: [
              const CableHeader(),
              const SizedBox(height: 20),

              // ----------------------------------------------------------------
              // INPUT
              // ----------------------------------------------------------------
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.settings,
                        title: 'Design Input',
                        color: Colors.blue,
                      ),

                      _space(),

                      TextField(
                        controller: _currentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Load Current (A)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.bolt),
                        ),
                      ),

                      _space(),

                      DropdownButtonFormField<PhaseSystem>(
                        value: _phaseSystem,
                        decoration: const InputDecoration(
                          labelText: 'Phase System',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.power),
                        ),
                        items: PhaseSystem.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _phaseSystem = value;
                            _systemVoltageController.text =
                                value.name == 'singlePhase'
                                    ? '230'
                                    : '400';
                          });
                        },
                      ),

                      _space(),

                      DropdownButtonFormField<CableType>(
                        value: _cableType,
                        decoration: const InputDecoration(
                          labelText: 'Cable Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.cable),
                        ),
                        items: CableType.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _cableType = value;
                          });
                        },
                      ),

                      _space(),

                      DropdownButtonFormField<InstallationMethod>(
                        value: _installationMethod,
                        decoration: const InputDecoration(
                          labelText: 'Installation Method',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.route),
                        ),
                        items: InstallationMethod.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _installationMethod = value;

                            if (_isGroup1_2_5(value.name)) {
                              _arrangement = null;
                            }
                          });
                        },
                      ),

                      _space(),

                      DropdownButtonFormField<CoreType>(
                        value: _coreType,
                        decoration: const InputDecoration(
                          labelText: 'Core Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.memory),
                        ),
                        items: CoreType.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _coreType = value;

                            if (value.name != 'singleCore') {
                              _arrangement = null;
                            }
                          });
                        },
                      ),

                      if (_requiresArrangement) ...[
                        _space(),

                        DropdownButtonFormField<CableArrangement>(
                          value: _arrangement,
                          decoration: const InputDecoration(
                            labelText: 'Cable Arrangement',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.alt_route),
                          ),
                          items: CableArrangement.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _arrangement = value;
                            });
                          },
                        ),
                      ],

                      _space(),

                      DropdownButtonFormField<int>(
                        value: _loadedConductors,
                        decoration: const InputDecoration(
                          labelText: 'Loaded Conductors',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.linear_scale),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('1'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('2'),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('3'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _loadedConductors = value;
                          });
                        },
                      ),

                      _space(),

                      TextField(
                        controller: _ambientController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Ambient Temperature (°C)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.thermostat),
                        ),
                      ),

                      _space(),

                      TextField(
                        controller: _groupingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Grouping Circuits',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grid_view),
                        ),
                      ),

                      _space(),

                      TextField(
                        controller: _lengthController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cable Length (m)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),

                      _space(),

                      TextField(
                        controller: _systemVoltageController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'System Voltage (V)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.electrical_services),
                        ),
                      ),

                      _space(),

                      TextField(
                        controller: _voltageDropController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Allowable Voltage Drop (%)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.percent),
                        ),
                      ),

                      _space(),

                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),

              // ----------------------------------------------------------------
              // RESULT
              // ----------------------------------------------------------------
              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],

              if (_result != null) ...[
                const SizedBox(height: 24),

                if (_result!.isSuccess) ...[
                  _buildDesignSummary(),
                  const SizedBox(height: 24),
                ],

                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          icon: _result!.isSuccess
                              ? Icons.check_circle
                              : Icons.error,
                          title: _result!.isSuccess
                              ? 'Calculation Result'
                              : 'Calculation Failed',
                          color: _result!.isSuccess
                              ? Colors.green
                              : Colors.red,
                        ),

                        _space(),

                        ResultRow(
                          title: 'Status',
                          value: _result!.message,
                        ),

                        if (_result!.isSuccess) ...[
                          const Divider(height: 28),

                          const Text(
                            'Input / Grouping',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          _space(),

                          ResultRow(
                            title: 'Load Current',
                            value:
                                '${_number(_result!.loadCurrent)} A',
                          ),

                          ResultRow(
                            title: 'Grouping Factor',
                            value: _number(
                              _result!.groupingFactor,
                            ),
                          ),

                          ResultRow(
                            title: 'Required Current',
                            value:
                                '${_number(_result!.requiredCurrent)} A',
                          ),

                          const Divider(height: 28),

                          const Text(
                            'Cable Selection',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          _space(),

                          ResultRow(
                            title: 'Selected Cable',
                            value:
                                '${_number(_result!.cableSizeSqmm, digits: 0)} sq.mm',
                          ),

                          ResultRow(
                            title: 'Parallel Runs',
                            value:
                                '${_result!.runs ?? '-'}',
                          ),

                          ResultRow(
                            title: 'Actual Load Current / Run',
                            value:
                                '${_number(_result!.currentPerRun)} A',
                          ),

                          ResultRow(
                            title: 'Ampacity / Run',
                            value:
                                '${_number(_result!.ampacityPerRun)} A',
                          ),

                          ResultRow(
                            title: 'Total Ampacity',
                            value:
                                '${_number(_result!.totalAmpacity)} A',
                          ),

                          ResultRow(
                            title: 'Cable Arrangement',
                            value:
                                _result!.cableArrangement ?? '-',
                          ),

                          const Divider(height: 28),

                          const Text(
                            'Voltage Drop',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          _space(),

                          ResultRow(
                            title: 'Cable Length',
                            value:
                                '${_number(_result!.cableLengthM)} m',
                          ),

                          ResultRow(
                            title: 'mV/A/m',
                            value:
                                _number(_result!.mvPerAperM),
                          ),

                          ResultRow(
                            title: 'Voltage Drop',
                            value:
                                '${_number(_result!.voltageDropV)} V',
                          ),

                          ResultRow(
                            title: 'Voltage Drop %',
                            value:
                                '${_number(_result!.voltageDropPercent)} %',
                          ),

                          const Divider(height: 28),

                          const Text(
                            'Reference Traceability',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          _space(),

                          ResultRow(
                            title: 'Ampacity Reference',
                            value:
                                _result!.ampacityReference ?? '-',
                          ),

                          ResultRow(
                            title: 'Voltage Drop Reference',
                            value:
                                _result!.voltageDropReference ?? '-',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
          );
        },
      ),
    );
  }
}
