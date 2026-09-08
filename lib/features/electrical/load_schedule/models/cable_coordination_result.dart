import 'dart:math' as math;

import '../../cable_design/enums/conductor_temperature_class.dart';
import '../../cable_design/enums/core_type.dart';
import '../../cable_design/models/cable_routing_identity.dart';
import '../../voltage_drop/enums/cable_insulation.dart';
import '../enums/cable_selection_status.dart';
import 'calculation_source_reference.dart';

class CableCoordinationResult {
  CableCoordinationResult._({
    required this.status,
    this.reason,
    this.identity,
    this.insulation,
    this.conductorTemperatureClass,
    this.coreType,
    this.loadedConductors,
    this.sizeSqmm,
    this.runs,
    this.baseAmpacityPerRunA,
    this.correctedAmpacityPerRunA,
    this.totalCorrectedCapacityIzA,
    this.designCurrentIbA,
    this.breakerRatedCurrentInA,
    this.tableId,
    this.installationGroupNumber,
    this.sourceColumnId,
    this.groupingFactor,
    this.temperatureFactor,
    List<CalculationSourceReference> sourceReferences = const [],
  }) : sourceReferences = List.unmodifiable(sourceReferences) {
    _validate();
  }

  factory CableCoordinationResult.coordinated({
    required CableRoutingIdentity identity,
    required CableInsulation insulation,
    required ConductorTemperatureClass conductorTemperatureClass,
    required CoreType coreType,
    required int loadedConductors,
    required double sizeSqmm,
    required int runs,
    required double baseAmpacityPerRunA,
    required double correctedAmpacityPerRunA,
    required double totalCorrectedCapacityIzA,
    required double designCurrentIbA,
    required double breakerRatedCurrentInA,
    required String tableId,
    required int installationGroupNumber,
    required List<CalculationSourceReference> sourceReferences,
    String? sourceColumnId,
    double? groupingFactor,
    double? temperatureFactor,
  }) => CableCoordinationResult._(
    status: CableSelectionStatus.coordinated,
    identity: identity,
    insulation: insulation,
    conductorTemperatureClass: conductorTemperatureClass,
    coreType: coreType,
    loadedConductors: loadedConductors,
    sizeSqmm: sizeSqmm,
    runs: runs,
    baseAmpacityPerRunA: baseAmpacityPerRunA,
    correctedAmpacityPerRunA: correctedAmpacityPerRunA,
    totalCorrectedCapacityIzA: totalCorrectedCapacityIzA,
    designCurrentIbA: designCurrentIbA,
    breakerRatedCurrentInA: breakerRatedCurrentInA,
    tableId: tableId,
    installationGroupNumber: installationGroupNumber,
    sourceColumnId: sourceColumnId,
    groupingFactor: groupingFactor,
    temperatureFactor: temperatureFactor,
    sourceReferences: sourceReferences,
  );

  factory CableCoordinationResult.notCalculated({String? reason}) =>
      CableCoordinationResult._(
        status: CableSelectionStatus.notCalculated,
        reason: reason,
      );

  factory CableCoordinationResult.insufficient({required String reason}) =>
      CableCoordinationResult._(
        status: CableSelectionStatus.insufficient,
        reason: reason,
      );

  factory CableCoordinationResult.invalid({required String reason}) =>
      CableCoordinationResult._(
        status: CableSelectionStatus.invalid,
        reason: reason,
      );

  factory CableCoordinationResult.noMatch({required String reason}) =>
      CableCoordinationResult._(
        status: CableSelectionStatus.noMatch,
        reason: reason,
      );

  factory CableCoordinationResult.unsupported({required String reason}) =>
      CableCoordinationResult._(
        status: CableSelectionStatus.unsupported,
        reason: reason,
      );

  factory CableCoordinationResult.ambiguous({required String reason}) =>
      CableCoordinationResult._(
        status: CableSelectionStatus.ambiguous,
        reason: reason,
      );

  final CableSelectionStatus status;
  final String? reason;
  final CableRoutingIdentity? identity;
  final CableInsulation? insulation;
  final ConductorTemperatureClass? conductorTemperatureClass;
  final CoreType? coreType;
  final int? loadedConductors;
  final double? sizeSqmm;
  final int? runs;
  final double? baseAmpacityPerRunA;
  final double? correctedAmpacityPerRunA;
  final double? totalCorrectedCapacityIzA;
  final double? designCurrentIbA;
  final double? breakerRatedCurrentInA;
  final String? tableId;
  final int? installationGroupNumber;
  final String? sourceColumnId;
  final double? groupingFactor;
  final double? temperatureFactor;
  final List<CalculationSourceReference> sourceReferences;

  static const approvedTableIds = {'5-20', '5-23', '5-27', '5-29'};

  void _validate() {
    final values = [
      ?sizeSqmm,
      ?baseAmpacityPerRunA,
      ?correctedAmpacityPerRunA,
      ?totalCorrectedCapacityIzA,
      ?designCurrentIbA,
      ?breakerRatedCurrentInA,
      ?groupingFactor,
      ?temperatureFactor,
    ];
    if (values.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError(
        'Cable coordination values must be finite and positive.',
      );
    }
    final engineeringValuesPresent =
        identity != null ||
        insulation != null ||
        conductorTemperatureClass != null ||
        coreType != null ||
        loadedConductors != null ||
        sizeSqmm != null ||
        runs != null ||
        baseAmpacityPerRunA != null ||
        correctedAmpacityPerRunA != null ||
        totalCorrectedCapacityIzA != null ||
        designCurrentIbA != null ||
        breakerRatedCurrentInA != null ||
        tableId != null ||
        installationGroupNumber != null ||
        sourceColumnId != null ||
        groupingFactor != null ||
        temperatureFactor != null;
    if (status != CableSelectionStatus.coordinated) {
      if (engineeringValuesPresent || sourceReferences.isNotEmpty) {
        throw ArgumentError(
          'Unresolved cable result cannot contain engineering values.',
        );
      }
      if (status != CableSelectionStatus.notCalculated &&
          (reason == null || reason!.trim().isEmpty)) {
        throw ArgumentError('Fail-closed cable result requires a reason.');
      }
      return;
    }
    if (reason != null ||
        identity == null ||
        insulation == null ||
        conductorTemperatureClass == null ||
        coreType == null ||
        loadedConductors == null ||
        sizeSqmm == null ||
        runs == null ||
        baseAmpacityPerRunA == null ||
        correctedAmpacityPerRunA == null ||
        totalCorrectedCapacityIzA == null ||
        designCurrentIbA == null ||
        breakerRatedCurrentInA == null ||
        tableId == null ||
        installationGroupNumber == null ||
        sourceReferences.isEmpty) {
      throw ArgumentError(
        'Coordinated cable requires a complete typed payload.',
      );
    }
    if (loadedConductors! <= 0 || runs! <= 0 || installationGroupNumber! <= 0) {
      throw ArgumentError(
        'Cable counts and installation group must be positive.',
      );
    }
    if (!approvedTableIds.contains(tableId)) {
      throw ArgumentError('Cable result uses an unapproved ampacity table.');
    }
    _validateSourceCompatibility();
    final expectedCorrected =
        baseAmpacityPerRunA! *
        (groupingFactor ?? 1.0) *
        (temperatureFactor ?? 1.0);
    if (!_close(expectedCorrected, correctedAmpacityPerRunA!)) {
      throw ArgumentError(
        'Corrected ampacity must match the recorded correction factors.',
      );
    }
    final expectedTotal = correctedAmpacityPerRunA! * runs!;
    if (!_close(expectedTotal, totalCorrectedCapacityIzA!)) {
      throw ArgumentError(
        'Total Iz must equal corrected ampacity per run x runs.',
      );
    }
    if (designCurrentIbA! > breakerRatedCurrentInA! &&
        !_close(designCurrentIbA!, breakerRatedCurrentInA!)) {
      throw ArgumentError('Cable coordination requires Ib <= In.');
    }
    if (breakerRatedCurrentInA! > totalCorrectedCapacityIzA! &&
        !_close(breakerRatedCurrentInA!, totalCorrectedCapacityIzA!)) {
      throw ArgumentError('Cable coordination requires In <= Iz.');
    }
  }

  void _validateSourceCompatibility() {
    final pvcTable = tableId == '5-20' || tableId == '5-23';
    if (pvcTable != (insulation == CableInsulation.pvc) ||
        pvcTable !=
            (conductorTemperatureClass == ConductorTemperatureClass.pvc70)) {
      throw ArgumentError(
        'Ampacity table conflicts with insulation or temperature class.',
      );
    }
    final airTable = tableId == '5-20' || tableId == '5-27';
    final permittedGroups = airTable ? const {1, 2} : const {5, 6};
    if (!permittedGroups.contains(installationGroupNumber)) {
      throw ArgumentError('Ampacity table conflicts with installation group.');
    }
    if (loadedConductors != 2 && loadedConductors != 3) {
      throw ArgumentError('Only two or three loaded conductors are approved.');
    }
    final permittedIdentities = switch (tableId) {
      '5-20' => const {
        CableRoutingIdentity.iec01,
        CableRoutingIdentity.iec02,
        CableRoutingIdentity.iec05,
        CableRoutingIdentity.iec06,
        CableRoutingIdentity.iec10,
        CableRoutingIdentity.nyy,
        CableRoutingIdentity.nyyG,
        CableRoutingIdentity.vct,
        CableRoutingIdentity.vctG,
      },
      '5-23' => const {
        CableRoutingIdentity.nyy,
        CableRoutingIdentity.nyyG,
        CableRoutingIdentity.vct,
        CableRoutingIdentity.vctG,
        CableRoutingIdentity.iec605021,
      },
      '5-27' || '5-29' => const {CableRoutingIdentity.iec605021},
      _ => const <CableRoutingIdentity>{},
    };
    if (!permittedIdentities.contains(identity)) {
      throw ArgumentError('Ampacity table conflicts with cable identity.');
    }
  }

  bool _close(double left, double right) {
    final scale = math.max(1.0, math.max(left.abs(), right.abs()));
    return (left - right).abs() <= 1e-9 * scale;
  }

  Map<String, Object?> toJson() => {
    'status': status.name,
    if (reason != null) 'reason': reason,
    if (identity != null) 'identity': identity!.name,
    if (insulation != null) 'insulation': insulation!.name,
    if (conductorTemperatureClass != null)
      'conductorTemperatureClass': conductorTemperatureClass!.name,
    if (coreType != null) 'coreType': coreType!.name,
    if (loadedConductors != null) 'loadedConductors': loadedConductors,
    if (sizeSqmm != null) 'sizeSqmm': sizeSqmm,
    if (runs != null) 'runs': runs,
    if (baseAmpacityPerRunA != null) 'baseAmpacityPerRunA': baseAmpacityPerRunA,
    if (correctedAmpacityPerRunA != null)
      'correctedAmpacityPerRunA': correctedAmpacityPerRunA,
    if (totalCorrectedCapacityIzA != null)
      'totalCorrectedCapacityIzA': totalCorrectedCapacityIzA,
    if (designCurrentIbA != null) 'designCurrentIbA': designCurrentIbA,
    if (breakerRatedCurrentInA != null)
      'breakerRatedCurrentInA': breakerRatedCurrentInA,
    if (tableId != null) 'tableId': tableId,
    if (installationGroupNumber != null)
      'installationGroupNumber': installationGroupNumber,
    if (sourceColumnId != null) 'sourceColumnId': sourceColumnId,
    if (groupingFactor != null) 'groupingFactor': groupingFactor,
    if (temperatureFactor != null) 'temperatureFactor': temperatureFactor,
    'sourceReferences': sourceReferences.map((item) => item.toJson()).toList(),
  };

  factory CableCoordinationResult.fromJson(Map<String, Object?> json) {
    final status = CableSelectionStatus.values.byName(json['status'] as String);
    if (status != CableSelectionStatus.coordinated) {
      final hasEngineeringValues = json.keys.any(
        (key) =>
            key != 'status' && key != 'reason' && key != 'sourceReferences',
      );
      if (hasEngineeringValues ||
          (json['sourceReferences'] as List).isNotEmpty) {
        throw ArgumentError(
          'Unresolved cable JSON cannot contain engineering values.',
        );
      }
      final reason = json['reason'] as String?;
      return switch (status) {
        CableSelectionStatus.notCalculated =>
          CableCoordinationResult.notCalculated(reason: reason),
        CableSelectionStatus.insufficient =>
          CableCoordinationResult.insufficient(reason: reason!),
        CableSelectionStatus.invalid => CableCoordinationResult.invalid(
          reason: reason!,
        ),
        CableSelectionStatus.noMatch => CableCoordinationResult.noMatch(
          reason: reason!,
        ),
        CableSelectionStatus.unsupported => CableCoordinationResult.unsupported(
          reason: reason!,
        ),
        CableSelectionStatus.ambiguous => CableCoordinationResult.ambiguous(
          reason: reason!,
        ),
        CableSelectionStatus.coordinated => throw StateError('unreachable'),
      };
    }
    return CableCoordinationResult.coordinated(
      identity: CableRoutingIdentity.values.byName(json['identity'] as String),
      insulation: CableInsulation.values.byName(json['insulation'] as String),
      conductorTemperatureClass: ConductorTemperatureClass.values.byName(
        json['conductorTemperatureClass'] as String,
      ),
      coreType: CoreType.values.byName(json['coreType'] as String),
      loadedConductors: json['loadedConductors'] as int,
      sizeSqmm: (json['sizeSqmm'] as num).toDouble(),
      runs: json['runs'] as int,
      baseAmpacityPerRunA: (json['baseAmpacityPerRunA'] as num).toDouble(),
      correctedAmpacityPerRunA: (json['correctedAmpacityPerRunA'] as num)
          .toDouble(),
      totalCorrectedCapacityIzA: (json['totalCorrectedCapacityIzA'] as num)
          .toDouble(),
      designCurrentIbA: (json['designCurrentIbA'] as num).toDouble(),
      breakerRatedCurrentInA: (json['breakerRatedCurrentInA'] as num)
          .toDouble(),
      tableId: json['tableId'] as String,
      installationGroupNumber: json['installationGroupNumber'] as int,
      sourceColumnId: json['sourceColumnId'] as String?,
      groupingFactor: (json['groupingFactor'] as num?)?.toDouble(),
      temperatureFactor: (json['temperatureFactor'] as num?)?.toDouble(),
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
