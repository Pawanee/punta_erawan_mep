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
import '../routing_v2/enums/cable_design_workflow.dart';
import '../routing_v2/models/cable_design_workflow_activation.dart';
import '../routing_v2/pages/cable_design_v2_page.dart';
import '../widgets/cable_header.dart';
import '../widgets/result_row.dart';

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

  final TextEditingController _currentController = TextEditingController();

  final TextEditingController _ambientController = TextEditingController(
    text: '30',
  );

  final TextEditingController _groupingController = TextEditingController(
    text: '1',
  );

  final TextEditingController _voltageDropController = TextEditingController(
    text: '3',
  );

  final TextEditingController _lengthController = TextEditingController();

  final TextEditingController _systemVoltageController = TextEditingController(
    text: '400',
  );

  PhaseSystem _phaseSystem = PhaseSystem.threePhase;
  CableType _cableType = CableType.iec01;
  InstallationMethod _installationMethod = InstallationMethod.group1;
  CoreType _coreType = CoreType.singleCore;

  int _loadedConductors = 3;

  CableArrangement? _arrangement;

  bool _isLoading = false;
  bool _voltageDropEnabled = true;

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
    _systemVoltageController.text = _phaseSystem.name == 'singlePhase'
        ? '230'
        : '400';

    setState(() {
      _phaseSystem = PhaseSystem.threePhase;
      _cableType = CableType.iec01;
      _installationMethod = InstallationMethod.group1;
      _coreType = CoreType.singleCore;
      _loadedConductors = 3;
      _arrangement = null;
      _voltageDropEnabled = true;
      _result = null;
    });
  }

  Widget _space() => const SizedBox(height: 18);

  bool get _requiresArrangement {
    return _coreType.name == 'singleCore' &&
        !_isGroup1_2_5(_installationMethod.name);
  }

  bool _isGroup1_2_5(String name) {
    return name == 'group1' || name == 'group2' || name == 'group5';
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
    final loadCurrent = double.tryParse(_currentController.text) ?? 0;

    final lengthM = double.tryParse(_lengthController.text) ?? 0;

    final systemVoltage = double.tryParse(_systemVoltageController.text) ?? 0;

    final allowableVoltageDrop =
        double.tryParse(_voltageDropController.text) ?? 0;

    if (loadCurrent <= 0) {
      setState(() {
        _result = VoltageDropDesignResult.error('Load Current ต้องมากกว่า 0 A');
      });
      return;
    }

    if (_voltageDropEnabled && lengthM <= 0) {
      setState(() {
        _result = VoltageDropDesignResult.error('Cable Length ต้องมากกว่า 0 m');
      });
      return;
    }

    if (_voltageDropEnabled && systemVoltage <= 0) {
      setState(() {
        _result = VoltageDropDesignResult.error(
          'System Voltage ต้องมากกว่า 0 V',
        );
      });
      return;
    }

    if (_voltageDropEnabled && allowableVoltageDrop <= 0) {
      setState(() {
        _result = VoltageDropDesignResult.error(
          'Allowable Voltage Drop ต้องมากกว่า 0 %',
        );
      });
      return;
    }

    if (_voltageDropEnabled && _requiresArrangement && _arrangement == null) {
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
      ambientTemperature: double.tryParse(_ambientController.text) ?? 30,
      groupingCircuits: int.tryParse(_groupingController.text) ?? 1,
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
      voltageDropEnabled: _voltageDropEnabled,
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

      debugPrint('Legacy Cable Design UI error: $e');

      setState(() {
        _result = VoltageDropDesignResult.error(
          'ไม่สามารถคำนวณได้ กรุณาตรวจสอบข้อมูลที่ป้อน',
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

    final voltageDropConsidered = result.voltageDropConsidered;
    final allowable = double.tryParse(_voltageDropController.text) ?? 0;

    final actual = result.voltageDropPercent;

    final margin = actual == null ? null : allowable - actual;

    final isPass = !voltageDropConsidered || (margin != null && margin >= 0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegacySectionHeader(
              icon: isPass ? Icons.verified : Icons.warning,
              title: 'Design Summary',
              color: isPass ? Colors.green : Colors.orange,
            ),
            const _ThaiSectionHelper('สรุปผลการออกแบบ'),
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
                    title: 'กระแสออกแบบ',
                    value: '${_number(result.loadCurrent)} A',
                  ),
                  ResultRow(
                    title: 'ขนาดสาย',
                    value: result.cableArrangement ?? '-',
                  ),
                  ResultRow(title: 'จำนวน Run', value: '${result.runs ?? '-'}'),
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
                    value: voltageDropConsidered
                        ? '${_number(result.voltageDropPercent)} %'
                        : 'ไม่พิจารณา',
                  ),
                  if (voltageDropConsidered) ...[
                    ResultRow(
                      title: 'Allowable Voltage Drop',
                      value: '${_number(allowable)} %',
                    ),
                    ResultRow(
                      title: 'Voltage Drop Margin',
                      value: '${_number(margin)} %',
                    ),
                  ] else ...[
                    const ResultRow(
                      title: 'สถานะ Voltage Drop',
                      value: 'เลือกขนาดสายจาก Ampacity เท่านั้น',
                    ),
                  ],
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
          key: const Key('legacy-calculate'),
          onPressed: _isLoading ? null : _calculate,
          icon: const Icon(Icons.calculate),
          label: const _BilingualButtonLabel(
            english: 'CALCULATE',
            thai: 'คำนวณ',
          ),
        );
        final resetButton = OutlinedButton.icon(
          onPressed: _isLoading ? null : _resetForm,
          icon: const Icon(Icons.refresh),
          label: const _BilingualButtonLabel(
            english: 'RESET',
            thai: 'ล้างข้อมูล',
          ),
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
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'PUNTA ERAWAN MEP',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('advanced-cable-design-entry'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CableDesignV2Page(
                  activation: const CableDesignWorkflowActivation(
                    workflow: CableDesignWorkflow.advancedCableDesign,
                  ),
                ),
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const SizedBox(
              width: 112,
              child: _BilingualButtonLabel(
                english: 'Advanced Cable Design',
                thai: 'การออกแบบสายไฟขั้นสูง',
              ),
            ),
          ),
        ],
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
                          const _LegacySectionHeader(
                            icon: Icons.settings,
                            title: 'Design Input',
                            color: Colors.blue,
                          ),
                          const _ThaiSectionHelper('ข้อมูลการออกแบบ'),

                          _space(),

                          TextField(
                            key: const Key('legacy-load-current'),
                            controller: _currentController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Load Current (A)',
                              thai: 'กระแสโหลดที่ใช้ในการออกแบบ',
                              prefixIcon: Icons.bolt,
                            ),
                          ),

                          _space(),

                          DropdownButtonFormField<PhaseSystem>(
                            key: const Key('legacy-phase-system'),
                            isExpanded: true,
                            value: _phaseSystem,
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Phase System',
                              thai: 'ระบบเฟสของวงจร',
                              prefixIcon: Icons.power,
                              infoKey: const Key('legacy-info-phase-system'),
                              infoText:
                                  'ระบบเฟสของวงจรใช้กำหนดเงื่อนไขการออกแบบและแรงดันระบบเริ่มต้น\n\nPhase System remains an explicit engineering input.',
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
                                    value.name == 'singlePhase' ? '230' : '400';
                              });
                            },
                          ),

                          _space(),

                          DropdownButtonFormField<CableType>(
                            isExpanded: true,
                            value: _cableType,
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Cable Type',
                              thai: 'ชนิดสายไฟ',
                              prefixIcon: Icons.cable,
                              infoKey: const Key('legacy-info-cable-type'),
                              infoText:
                                  'เลือกชนิดหรือมาตรฐานสายไฟตามงานออกแบบ โดยชื่อมาตรฐานจะคงรูปเดิม\n\nCable Type determines the approved cable context.',
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
                            isExpanded: true,
                            value: _installationMethod,
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Installation Method',
                              thai: 'วิธีการติดตั้ง',
                              prefixIcon: Icons.route,
                              infoKey: const Key(
                                'legacy-info-installation-method',
                              ),
                              infoText:
                                  'เลือกวิธีติดตั้งจริงเพื่อใช้เงื่อนไขพิกัดกระแสและแหล่งอ้างอิงที่ถูกต้อง\n\nInstallation Method is an explicit engineering condition.',
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
                            isExpanded: true,
                            value: _coreType,
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Core Type',
                              thai: 'ชนิดแกนของสายไฟ',
                              prefixIcon: Icons.memory,
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
                              isExpanded: true,
                              value: _arrangement,
                              decoration: _legacyFieldDecoration(
                                context,
                                english: 'Cable Arrangement',
                                thai: 'รูปแบบการจัดวางสาย',
                                prefixIcon: Icons.alt_route,
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
                            isExpanded: true,
                            value: _loadedConductors,
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Loaded Conductors',
                              thai: 'จำนวนตัวนำที่มีกระแส',
                              prefixIcon: Icons.linear_scale,
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1')),
                              DropdownMenuItem(value: 2, child: Text('2')),
                              DropdownMenuItem(value: 3, child: Text('3')),
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
                            key: const Key('legacy-ambient-temperature'),
                            controller: _ambientController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Ambient Temperature (°C)',
                              thai: 'อุณหภูมิแวดล้อม',
                              prefixIcon: Icons.thermostat,
                            ),
                          ),

                          _space(),

                          TextField(
                            key: const Key('legacy-grouping-circuits'),
                            controller: _groupingController,
                            keyboardType: TextInputType.number,
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Grouping Circuits',
                              thai: 'จำนวนวงจรที่จัดกลุ่มร่วมกัน',
                              prefixIcon: Icons.grid_view,
                            ),
                          ),

                          _space(),

                          TextField(
                            key: const Key('legacy-cable-length'),
                            controller: _lengthController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Cable Length (m)',
                              thai: 'ความยาววงจร',
                              prefixIcon: Icons.straighten,
                            ),
                          ),

                          _space(),

                          TextField(
                            key: const Key('legacy-system-voltage'),
                            controller: _systemVoltageController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'System Voltage (V)',
                              thai: 'แรงดันระบบ',
                              prefixIcon: Icons.electrical_services,
                            ),
                          ),

                          _space(),

                          CheckboxListTile(
                            key: const Key('voltage-drop-enabled'),
                            contentPadding: EdgeInsets.zero,
                            value: !_voltageDropEnabled,
                            title: const _BilingualFieldLabel(
                              english: 'Do not consider voltage drop',
                              thai: 'ไม่พิจารณา Voltage Drop',
                            ),
                            subtitle: const Text(
                              'ไม่ได้พิจารณาแรงดันตกในการเลือกขนาดสาย\n'
                              'Ampacity-only cable selection',
                            ),
                            secondary: const _LegacyInfoButton(
                              key: Key('legacy-info-voltage-drop'),
                              title: 'Voltage Drop Verification',
                              text:
                                  'เมื่อเลือกตัวเลือกนี้ ระบบจะเลือกขนาดสายจาก Ampacity เท่านั้น และไม่ถือว่าแรงดันตกเป็น 0% หรือผ่านการตรวจสอบ\n\nVoltage drop is not considered or verified.',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _voltageDropEnabled = !(value ?? false);
                              });
                            },
                          ),

                          const Padding(
                            padding: EdgeInsets.only(left: 16, right: 16),
                            child: Text(
                              'Ampacity = ความสามารถในการรับกระแสของสาย\n'
                              'Voltage Drop = ข้อจำกัดแรงดันตกตามระยะทาง',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),

                          _space(),

                          TextField(
                            key: const Key('legacy-allowable-voltage-drop'),
                            controller: _voltageDropController,
                            enabled: _voltageDropEnabled,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _legacyFieldDecoration(
                              context,
                              english: 'Allowable Voltage Drop (%)',
                              thai: 'แรงดันตกที่ยอมให้',
                              prefixIcon: Icons.percent,
                              infoKey: const Key(
                                'legacy-info-allowable-voltage-drop',
                              ),
                              infoText:
                                  'ค่าร้อยละแรงดันตกสูงสุดที่ยอมให้ ใช้เฉพาะเมื่อพิจารณา Voltage Drop\n\nAllowable Voltage Drop is the verification limit.',
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
                    const Center(child: CircularProgressIndicator()),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LegacySectionHeader(
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
                            _ThaiSectionHelper(
                              _result!.isSuccess
                                  ? 'ผลการคำนวณ'
                                  : 'ไม่สามารถคำนวณได้',
                            ),

                            _space(),

                            ResultRow(title: 'Status', value: _result!.message),

                            if (_result!.isSuccess) ...[
                              const Divider(height: 28),

                              const Text(
                                'Input / Grouping',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const _ThaiSectionHelper(
                                'ข้อมูลนำเข้า / การจัดกลุ่ม',
                              ),

                              _space(),

                              ResultRow(
                                title: 'Load Current',
                                value: '${_number(_result!.loadCurrent)} A',
                              ),

                              ResultRow(
                                title: 'Grouping Factor',
                                value: _number(_result!.groupingFactor),
                              ),

                              ResultRow(
                                title: 'Required Current',
                                value: '${_number(_result!.requiredCurrent)} A',
                              ),

                              const Divider(height: 28),

                              const Text(
                                'Cable Selection',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const _ThaiSectionHelper('ผลการเลือกขนาดสายไฟ'),

                              _space(),

                              ResultRow(
                                title: 'Selected Cable',
                                value:
                                    '${_number(_result!.cableSizeSqmm, digits: 0)} sq.mm',
                              ),

                              ResultRow(
                                title: 'Parallel Runs',
                                value: '${_result!.runs ?? '-'}',
                              ),

                              ResultRow(
                                title: 'Actual Load Current / Run',
                                value: '${_number(_result!.currentPerRun)} A',
                              ),

                              ResultRow(
                                title: 'Ampacity / Run',
                                value: '${_number(_result!.ampacityPerRun)} A',
                              ),

                              ResultRow(
                                title: 'Total Ampacity',
                                value: '${_number(_result!.totalAmpacity)} A',
                              ),

                              ResultRow(
                                title: 'Cable Arrangement',
                                value: _result!.cableArrangement ?? '-',
                              ),

                              const Divider(height: 28),

                              const Text(
                                'Voltage Drop',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const _ThaiSectionHelper('แรงดันตก'),

                              _space(),

                              if (_result!.voltageDropConsidered) ...[
                                ResultRow(
                                  title: 'Cable Length',
                                  value: '${_number(_result!.cableLengthM)} m',
                                ),
                                ResultRow(
                                  title: 'mV/A/m',
                                  value: _number(_result!.mvPerAperM),
                                ),
                                ResultRow(
                                  title: 'Voltage Drop',
                                  value: '${_number(_result!.voltageDropV)} V',
                                ),
                                ResultRow(
                                  title: 'Voltage Drop %',
                                  value:
                                      '${_number(_result!.voltageDropPercent)} %',
                                ),
                              ] else
                                const Column(
                                  children: [
                                    ResultRow(
                                      title: 'Voltage Drop',
                                      value: 'ไม่พิจารณา',
                                    ),
                                    ResultRow(
                                      title: 'สถานะ',
                                      value:
                                          'เลือกขนาดสายจาก Ampacity เท่านั้น',
                                    ),
                                  ],
                                ),

                              const Divider(height: 28),

                              const Text(
                                'Reference Traceability',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const _ThaiSectionHelper(
                                'แหล่งอ้างอิง / รายละเอียดการคำนวณ',
                              ),

                              _space(),

                              ResultRow(
                                title: 'Ampacity Reference',
                                value: _result!.ampacityReference ?? '-',
                              ),

                              ResultRow(
                                title: 'Voltage Drop Reference',
                                value: _result!.voltageDropConsidered
                                    ? (_result!.voltageDropReference ?? '-')
                                    : 'Not Verified',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Card(
                    color: Colors.blueGrey.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ผลการคำนวณขึ้นอยู่กับข้อมูลและเงื่อนไขการออกแบบที่เลือก\n'
                              'ควรตรวจสอบโดยวิศวกรก่อนนำไปใช้ในการก่อสร้าง',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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

InputDecoration _legacyFieldDecoration(
  BuildContext context, {
  required String english,
  required String thai,
  required IconData prefixIcon,
  Key? infoKey,
  String? infoText,
}) => InputDecoration(
  labelText: english,
  helperText: thai,
  helperMaxLines: 2,
  helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontWeight: FontWeight.normal,
  ),
  border: const OutlineInputBorder(),
  prefixIcon: Icon(prefixIcon),
  suffixIcon: infoText == null
      ? null
      : _LegacyInfoButton(key: infoKey, title: english, text: infoText),
);

class _BilingualFieldLabel extends StatelessWidget {
  const _BilingualFieldLabel({required this.english, required this.thai});

  final String english;
  final String thai;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(english),
      Text(
        thai,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.normal,
        ),
      ),
    ],
  );
}

class _BilingualButtonLabel extends StatelessWidget {
  const _BilingualButtonLabel({required this.english, required this.thai});

  final String english;
  final String thai;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(english),
        Text(thai, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _ThaiSectionHelper extends StatelessWidget {
  const _ThaiSectionHelper(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 48, top: 2),
    child: Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _LegacySectionHeader extends StatelessWidget {
  const _LegacySectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    ],
  );
}

class _LegacyInfoButton extends StatelessWidget {
  const _LegacyInfoButton({
    super.key,
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'ข้อมูลเพิ่มเติม / More information',
    icon: const Icon(Icons.info_outline),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(
            key: const Key('legacy-info-close'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด / Close'),
          ),
        ],
      ),
    ),
  );
}
