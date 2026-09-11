import 'dart:math' as math;

import '../../cable_design/models/cable_routing_identity.dart';
import '../../voltage_drop/enums/cable_arrangement.dart';
import '../../voltage_drop/enums/cable_insulation.dart';
import '../../voltage_drop/enums/voltage_drop_core_type.dart';
import '../../voltage_drop/enums/voltage_drop_installation_group.dart';
import '../../voltage_drop/enums/voltage_phase.dart';
import '../enums/voltage_basis.dart';
import '../enums/voltage_drop_calculation_status.dart';
import 'calculation_source_reference.dart';

class VoltageDropCalculationResult {
  VoltageDropCalculationResult._({
    required this.status,
    this.reason,
    this.identity,
    this.insulation,
    this.coreType,
    this.phase,
    this.sizeSqmm,
    this.runs,
    this.designCurrentIbA,
    this.currentPerRunA,
    this.lengthOneWayM,
    this.voltageBasis,
    this.voltageUsedV,
    this.allowableVoltageDropPercent,
    this.installationGroup,
    this.arrangement,
    this.tableId,
    this.rowId,
    this.columnId,
    this.mvPerAperM,
    this.voltageDropV,
    this.voltageDropPercent,
    this.isWithinLimit,
    List<CalculationSourceReference> sourceReferences = const [],
  }) : sourceReferences = List.unmodifiable(sourceReferences) {
    _validate();
  }

  factory VoltageDropCalculationResult.calculated({
    required CableInsulation insulation,
    required CableRoutingIdentity identity,
    required VoltageDropCoreType coreType,
    required VoltagePhase phase,
    required double sizeSqmm,
    required int runs,
    required double designCurrentIbA,
    required double currentPerRunA,
    required double lengthOneWayM,
    required VoltageBasis voltageBasis,
    required double voltageUsedV,
    required double allowableVoltageDropPercent,
    required VoltageDropInstallationGroup installationGroup,
    required String tableId,
    required String rowId,
    required String columnId,
    required double mvPerAperM,
    required double voltageDropV,
    required double voltageDropPercent,
    required bool isWithinLimit,
    required List<CalculationSourceReference> sourceReferences,
    CableArrangement? arrangement,
  }) => VoltageDropCalculationResult._(
    status: VoltageDropCalculationStatus.calculated,
    identity: identity,
    insulation: insulation,
    coreType: coreType,
    phase: phase,
    sizeSqmm: sizeSqmm,
    runs: runs,
    designCurrentIbA: designCurrentIbA,
    currentPerRunA: currentPerRunA,
    lengthOneWayM: lengthOneWayM,
    voltageBasis: voltageBasis,
    voltageUsedV: voltageUsedV,
    allowableVoltageDropPercent: allowableVoltageDropPercent,
    installationGroup: installationGroup,
    arrangement: arrangement,
    tableId: tableId,
    rowId: rowId,
    columnId: columnId,
    mvPerAperM: mvPerAperM,
    voltageDropV: voltageDropV,
    voltageDropPercent: voltageDropPercent,
    isWithinLimit: isWithinLimit,
    sourceReferences: sourceReferences,
  );

  factory VoltageDropCalculationResult.notCalculated({String? reason}) =>
      VoltageDropCalculationResult._(
        status: VoltageDropCalculationStatus.notCalculated,
        reason: reason,
      );

  factory VoltageDropCalculationResult.insufficient({required String reason}) =>
      VoltageDropCalculationResult._(
        status: VoltageDropCalculationStatus.insufficient,
        reason: reason,
      );

  factory VoltageDropCalculationResult.invalid({required String reason}) =>
      VoltageDropCalculationResult._(
        status: VoltageDropCalculationStatus.invalid,
        reason: reason,
      );

  factory VoltageDropCalculationResult.unsupported({required String reason}) =>
      VoltageDropCalculationResult._(
        status: VoltageDropCalculationStatus.unsupported,
        reason: reason,
      );

  final VoltageDropCalculationStatus status;
  final String? reason;
  final CableRoutingIdentity? identity;
  final CableInsulation? insulation;
  final VoltageDropCoreType? coreType;
  final VoltagePhase? phase;
  final double? sizeSqmm;
  final int? runs;
  final double? designCurrentIbA;
  final double? currentPerRunA;
  final double? lengthOneWayM;
  final VoltageBasis? voltageBasis;
  final double? voltageUsedV;
  final double? allowableVoltageDropPercent;
  final VoltageDropInstallationGroup? installationGroup;
  final CableArrangement? arrangement;
  final String? tableId;
  final String? rowId;
  final String? columnId;
  final double? mvPerAperM;
  final double? voltageDropV;
  final double? voltageDropPercent;
  final bool? isWithinLimit;
  final List<CalculationSourceReference> sourceReferences;

  void _validate() {
    final values = [
      ?sizeSqmm,
      ?designCurrentIbA,
      ?currentPerRunA,
      ?lengthOneWayM,
      ?voltageUsedV,
      ?allowableVoltageDropPercent,
      ?mvPerAperM,
      ?voltageDropV,
      ?voltageDropPercent,
    ];
    if (values.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError('Voltage-drop values must be finite and positive.');
    }
    final hasValues =
        identity != null ||
        insulation != null ||
        coreType != null ||
        phase != null ||
        sizeSqmm != null ||
        runs != null ||
        designCurrentIbA != null ||
        currentPerRunA != null ||
        lengthOneWayM != null ||
        voltageBasis != null ||
        voltageUsedV != null ||
        allowableVoltageDropPercent != null ||
        installationGroup != null ||
        arrangement != null ||
        tableId != null ||
        rowId != null ||
        columnId != null ||
        mvPerAperM != null ||
        voltageDropV != null ||
        voltageDropPercent != null ||
        isWithinLimit != null;
    if (status != VoltageDropCalculationStatus.calculated) {
      if (hasValues || sourceReferences.isNotEmpty) {
        throw ArgumentError(
          'Unresolved voltage-drop result cannot contain engineering values.',
        );
      }
      if (status != VoltageDropCalculationStatus.notCalculated &&
          (reason == null || reason!.trim().isEmpty)) {
        throw ArgumentError(
          'Fail-closed voltage-drop result requires a reason.',
        );
      }
      return;
    }
    if (reason != null ||
        identity == null ||
        insulation == null ||
        coreType == null ||
        phase == null ||
        sizeSqmm == null ||
        runs == null ||
        designCurrentIbA == null ||
        currentPerRunA == null ||
        lengthOneWayM == null ||
        voltageBasis == null ||
        voltageUsedV == null ||
        allowableVoltageDropPercent == null ||
        installationGroup == null ||
        tableId == null ||
        rowId == null ||
        columnId == null ||
        mvPerAperM == null ||
        voltageDropV == null ||
        voltageDropPercent == null ||
        isWithinLimit == null ||
        sourceReferences.isEmpty) {
      throw ArgumentError(
        'Calculated voltage drop requires a complete payload.',
      );
    }
    if (runs! <= 0 || allowableVoltageDropPercent! > 100) {
      throw ArgumentError('Runs and allowable voltage drop are out of range.');
    }
    _nonBlank(tableId!, 'tableId');
    _nonBlank(rowId!, 'rowId');
    _nonBlank(columnId!, 'columnId');
    if (!_close(currentPerRunA!, designCurrentIbA! / runs!)) {
      throw ArgumentError('Current per run must equal Ib divided by runs.');
    }
    final expectedDropV = mvPerAperM! * currentPerRunA! * lengthOneWayM! / 1000;
    final expectedPercent = expectedDropV / voltageUsedV! * 100;
    if (!_close(voltageDropV!, expectedDropV) ||
        !_close(voltageDropPercent!, expectedPercent) ||
        isWithinLimit !=
            (voltageDropPercent! <= allowableVoltageDropPercent!)) {
      throw ArgumentError(
        'Voltage-drop payload contradicts the approved formula.',
      );
    }
    if ((phase == VoltagePhase.singlePhase) !=
        (voltageBasis == VoltageBasis.lineToNeutral)) {
      throw ArgumentError('Phase and voltage basis are inconsistent.');
    }
    _validateTableAndColumn();
    final hasMatchingSource = sourceReferences.any(
      (source) =>
          source.tableId == tableId &&
          source.rowId == rowId &&
          source.columnId == columnId,
    );
    if (!hasMatchingSource) {
      throw ArgumentError(
        'Voltage-drop traceability must identify its table, row and column.',
      );
    }
  }

  void _validateTableAndColumn() {
    final expectedTable = switch ((insulation!, coreType!)) {
      (CableInsulation.pvc, VoltageDropCoreType.singleCore) => '9.1',
      (CableInsulation.pvc, VoltageDropCoreType.multiCore) => '9.2',
      (CableInsulation.xlpe, VoltageDropCoreType.singleCore) => '9.3',
      (CableInsulation.xlpe, VoltageDropCoreType.multiCore) => '9.4',
    };
    if (tableId != expectedTable) {
      throw ArgumentError('Voltage-drop table conflicts with cable facts.');
    }
    final phaseId = phase == VoltagePhase.singlePhase
        ? 'singlePhase'
        : 'threePhase';
    late final String expectedColumn;
    if (coreType == VoltageDropCoreType.multiCore) {
      if (arrangement != null) {
        throw ArgumentError('Multi-core tables do not use arrangement.');
      }
      expectedColumn = '${phaseId}All';
    } else if (installationGroup!.isGroup1_2_5) {
      if (arrangement != null) {
        throw ArgumentError('Groups 1, 2 and 5 use their shared column.');
      }
      expectedColumn = '${phaseId}Group1_2_5';
    } else {
      if (arrangement == null) {
        throw ArgumentError('This single-core route requires arrangement.');
      }
      expectedColumn = '$phaseId${_capitalized(arrangement!.name)}';
    }
    if (columnId != expectedColumn) {
      throw ArgumentError('Voltage-drop column conflicts with route facts.');
    }
  }

  static String _capitalized(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';

  static void _nonBlank(String value, String field) {
    if (value.trim().isEmpty) throw ArgumentError.value(value, field);
  }

  static bool _close(double left, double right) {
    final scale = math.max(1.0, math.max(left.abs(), right.abs()));
    return (left - right).abs() <= 1e-9 * scale;
  }

  Map<String, Object?> toJson() => {
    'status': status.name,
    if (reason != null) 'reason': reason,
    if (identity != null) 'identity': identity!.name,
    if (insulation != null) 'insulation': insulation!.name,
    if (coreType != null) 'coreType': coreType!.name,
    if (phase != null) 'phase': phase!.name,
    if (sizeSqmm != null) 'sizeSqmm': sizeSqmm,
    if (runs != null) 'runs': runs,
    if (designCurrentIbA != null) 'designCurrentIbA': designCurrentIbA,
    if (currentPerRunA != null) 'currentPerRunA': currentPerRunA,
    if (lengthOneWayM != null) 'lengthOneWayM': lengthOneWayM,
    if (voltageBasis != null) 'voltageBasis': voltageBasis!.name,
    if (voltageUsedV != null) 'voltageUsedV': voltageUsedV,
    if (allowableVoltageDropPercent != null)
      'allowableVoltageDropPercent': allowableVoltageDropPercent,
    if (installationGroup != null) 'installationGroup': installationGroup!.name,
    if (arrangement != null) 'arrangement': arrangement!.name,
    if (tableId != null) 'tableId': tableId,
    if (rowId != null) 'rowId': rowId,
    if (columnId != null) 'columnId': columnId,
    if (mvPerAperM != null) 'mvPerAperM': mvPerAperM,
    if (voltageDropV != null) 'voltageDropV': voltageDropV,
    if (voltageDropPercent != null) 'voltageDropPercent': voltageDropPercent,
    if (isWithinLimit != null) 'isWithinLimit': isWithinLimit,
    'sourceReferences': sourceReferences.map((item) => item.toJson()).toList(),
  };

  factory VoltageDropCalculationResult.fromJson(Map<String, Object?> json) {
    final status = VoltageDropCalculationStatus.values.byName(
      json['status'] as String,
    );
    if (status != VoltageDropCalculationStatus.calculated) {
      final extra = json.keys.any(
        (key) =>
            key != 'status' && key != 'reason' && key != 'sourceReferences',
      );
      if (extra || (json['sourceReferences'] as List).isNotEmpty) {
        throw ArgumentError('Unresolved voltage-drop JSON contains values.');
      }
      final reason = json['reason'] as String?;
      return switch (status) {
        VoltageDropCalculationStatus.notCalculated =>
          VoltageDropCalculationResult.notCalculated(reason: reason),
        VoltageDropCalculationStatus.insufficient =>
          VoltageDropCalculationResult.insufficient(reason: reason!),
        VoltageDropCalculationStatus.invalid =>
          VoltageDropCalculationResult.invalid(reason: reason!),
        VoltageDropCalculationStatus.unsupported =>
          VoltageDropCalculationResult.unsupported(reason: reason!),
        VoltageDropCalculationStatus.calculated => throw StateError(
          'unreachable',
        ),
      };
    }
    return VoltageDropCalculationResult.calculated(
      identity: CableRoutingIdentity.values.byName(json['identity'] as String),
      insulation: CableInsulation.values.byName(json['insulation'] as String),
      coreType: VoltageDropCoreType.values.byName(json['coreType'] as String),
      phase: VoltagePhase.values.byName(json['phase'] as String),
      sizeSqmm: (json['sizeSqmm'] as num).toDouble(),
      runs: json['runs'] as int,
      designCurrentIbA: (json['designCurrentIbA'] as num).toDouble(),
      currentPerRunA: (json['currentPerRunA'] as num).toDouble(),
      lengthOneWayM: (json['lengthOneWayM'] as num).toDouble(),
      voltageBasis: VoltageBasis.values.byName(json['voltageBasis'] as String),
      voltageUsedV: (json['voltageUsedV'] as num).toDouble(),
      allowableVoltageDropPercent: (json['allowableVoltageDropPercent'] as num)
          .toDouble(),
      installationGroup: VoltageDropInstallationGroup.values.byName(
        json['installationGroup'] as String,
      ),
      arrangement: json['arrangement'] == null
          ? null
          : CableArrangement.values.byName(json['arrangement'] as String),
      tableId: json['tableId'] as String,
      rowId: json['rowId'] as String,
      columnId: json['columnId'] as String,
      mvPerAperM: (json['mvPerAperM'] as num).toDouble(),
      voltageDropV: (json['voltageDropV'] as num).toDouble(),
      voltageDropPercent: (json['voltageDropPercent'] as num).toDouble(),
      isWithinLimit: json['isWithinLimit'] as bool,
      sourceReferences: (json['sourceReferences'] as List)
          .map(
            (item) => CalculationSourceReference.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
