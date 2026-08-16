 import '../enums/cable_type.dart';
import '../enums/core_type.dart';
import '../enums/installation_method.dart';

/// ============================================================================
/// TABLE 5-20 ROW MODEL
/// ----------------------------------------------------------------------------
/// ใช้แทนข้อมูล 1 แถวจากตาราง 5-20 วสท.2564
/// ============================================================================

class CableTableRow {
  /// ชนิดสาย
  final CableType cableType;

  /// วิธีติดตั้ง
  final InstallationMethod installationMethod;

  /// จำนวนตัวนำที่มีกระแสไหล
  final int loadedConductors;

  /// ลักษณะสาย
  final CoreType coreType;

  /// ขนาดหน้าตัดสาย (ตร.มม.)
  final double cableSizeSqmm;

  /// กระแสพิกัด
  final double ampacity;

  /// หมายเหตุ (คงไว้เพื่อรองรับข้อมูลเดิม)
  final String remark;

  /// ตารางอ้างอิง
  final String reference;

  /// Stable identifier of the published ampacity source table.
  final String? sourceTableId;

  /// Display name of the published ampacity source table.
  final String? sourceTableDisplayName;

  /// Published, uncorrected ampacity for this candidate.
  double get baseAmpacity => ampacity;

  const CableTableRow({
    required this.cableType,
    required this.installationMethod,
    required this.loadedConductors,
    required this.coreType,
    required this.cableSizeSqmm,
    required this.ampacity,
    required this.remark,
    required this.reference,
    this.sourceTableId,
    this.sourceTableDisplayName,
  });

  /// ==========================================================================
  /// Cable Arrangement
  ///
  /// เช่น
  /// 1 × 1.5 sq.mm
  /// 2 × 25 sq.mm
  /// 3 × 95 sq.mm
  ///
  /// จำนวนชุดสาย (runs) จะถูกคำนวณใน CableSelectionService
  /// ==========================================================================
  String arrangement(int runs) {
    final size = cableSizeSqmm % 1 == 0
        ? cableSizeSqmm.toInt().toString()
        : cableSizeSqmm.toString();

    return '$runs × $size sq.mm';
  }

  factory CableTableRow.fromJson(Map<String, dynamic> json) {
    return CableTableRow(
      cableType: CableType.values.firstWhere(
        (e) => e.name == json['cableType'],
      ),
      installationMethod: InstallationMethod.values.firstWhere(
        (e) => e.name == json['installationMethod'],
      ),
      loadedConductors: json['loadedConductors'],
      coreType: CoreType.values.firstWhere(
        (e) => e.name == json['coreType'],
      ),
      cableSizeSqmm: (json['cableSizeSqmm'] as num).toDouble(),
      ampacity: (json['ampacity'] as num).toDouble(),
      remark: json['remark'] ?? '',
      reference: json['reference'] ?? 'Table 5-20',
      sourceTableId: json['sourceTableId'],
      sourceTableDisplayName: json['sourceTableDisplayName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cableType': cableType.name,
      'installationMethod': installationMethod.name,
      'loadedConductors': loadedConductors,
      'coreType': coreType.name,
      'cableSizeSqmm': cableSizeSqmm,
      'ampacity': ampacity,
      'remark': remark,
      'reference': reference,
      'sourceTableId': sourceTableId,
      'sourceTableDisplayName': sourceTableDisplayName,
    };
  }

  CableTableRow copyWith({
    CableType? cableType,
    InstallationMethod? installationMethod,
    int? loadedConductors,
    CoreType? coreType,
    double? cableSizeSqmm,
    double? ampacity,
    String? remark,
    String? reference,
    String? sourceTableId,
    String? sourceTableDisplayName,
  }) {
    return CableTableRow(
      cableType: cableType ?? this.cableType,
      installationMethod:
          installationMethod ?? this.installationMethod,
      loadedConductors:
          loadedConductors ?? this.loadedConductors,
      coreType: coreType ?? this.coreType,
      cableSizeSqmm:
          cableSizeSqmm ?? this.cableSizeSqmm,
      ampacity: ampacity ?? this.ampacity,
      remark: remark ?? this.remark,
      reference: reference ?? this.reference,
      sourceTableId: sourceTableId ?? this.sourceTableId,
      sourceTableDisplayName:
          sourceTableDisplayName ?? this.sourceTableDisplayName,
    );
  }

  @override
  String toString() {
    return '''
CableTableRow(
  cableType: $cableType,
  installationMethod: $installationMethod,
  loadedConductors: $loadedConductors,
  coreType: $coreType,
  cableSizeSqmm: $cableSizeSqmm,
  ampacity: $ampacity,
  remark: $remark,
  reference: $reference,
  sourceTableId: $sourceTableId,
  sourceTableDisplayName: $sourceTableDisplayName,
)
''';
  }
}
