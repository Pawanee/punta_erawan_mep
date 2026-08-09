import '../enums/cable_insulation.dart';
import '../enums/voltage_drop_core_type.dart';

class VoltageDropTableEntry {
  const VoltageDropTableEntry({
    required this.table,
    required this.insulation,
    required this.coreType,
    required this.temperatureC,
    required this.sizeSqmm,
    this.singlePhaseGroup1_2_5,
    this.singlePhaseTouching,
    this.singlePhaseSpaced,
    this.threePhaseGroup1_2_5,
    this.threePhaseTrefoil,
    this.threePhaseFlat,
    this.threePhaseSpaced,
    this.singlePhaseAll,
    this.threePhaseAll,
  });

  final String table;
  final CableInsulation insulation;
  final VoltageDropCoreType coreType;
  final int temperatureC;
  final double sizeSqmm;

  final double? singlePhaseGroup1_2_5;
  final double? singlePhaseTouching;
  final double? singlePhaseSpaced;

  final double? threePhaseGroup1_2_5;
  final double? threePhaseTrefoil;
  final double? threePhaseFlat;
  final double? threePhaseSpaced;

  final double? singlePhaseAll;
  final double? threePhaseAll;

  factory VoltageDropTableEntry.fromJson(Map<String, dynamic> json) {
    return VoltageDropTableEntry(
      table: json['table'] as String,
      insulation: _parseInsulation(json['insulation'] as String),
      coreType: _parseCoreType(json['coreType'] as String),
      temperatureC: (json['temperatureC'] as num).toInt(),
      sizeSqmm: (json['sizeSqmm'] as num).toDouble(),
      singlePhaseGroup1_2_5: _toDouble(
        json['singlePhaseGroup1_2_5'] ?? json['singlePhaseGroup125'],
      ),
      singlePhaseTouching: _toDouble(json['singlePhaseTouching']),
      singlePhaseSpaced: _toDouble(json['singlePhaseSpaced']),
      threePhaseGroup1_2_5: _toDouble(
        json['threePhaseGroup1_2_5'] ?? json['threePhaseGroup125'],
      ),
      threePhaseTrefoil: _toDouble(json['threePhaseTrefoil']),
      threePhaseFlat: _toDouble(json['threePhaseFlat']),
      threePhaseSpaced: _toDouble(json['threePhaseSpaced']),
      singlePhaseAll: _toDouble(json['singlePhaseAll']),
      threePhaseAll: _toDouble(json['threePhaseAll']),
    );
  }

  static double? _toDouble(dynamic value) {
    return value == null ? null : (value as num).toDouble();
  }

  static CableInsulation _parseInsulation(String value) {
    switch (value) {
      case 'PVC':
        return CableInsulation.pvc;
      case 'XLPE':
        return CableInsulation.xlpe;
      default:
        throw FormatException('Unknown insulation: $value');
    }
  }

  static VoltageDropCoreType _parseCoreType(String value) {
    switch (value) {
      case 'singleCore':
        return VoltageDropCoreType.singleCore;
      case 'multiCore':
        return VoltageDropCoreType.multiCore;
      default:
        throw FormatException('Unknown core type: $value');
    }
  }
}
