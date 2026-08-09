import 'dart:convert';

import 'package:flutter/services.dart';

import '../enums/cable_insulation.dart';
import '../enums/voltage_drop_core_type.dart';
import '../models/voltage_drop_table_entry.dart';

class VoltageDropRepository {
  const VoltageDropRepository();

  Future<List<VoltageDropTableEntry>> loadTable({
    required CableInsulation insulation,
    required VoltageDropCoreType coreType,
  }) async {
    final path = _assetPath(
      insulation: insulation,
      coreType: coreType,
    );

    final jsonString = await rootBundle.loadString(path);
    final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;

    return jsonData
        .map(
          (e) => VoltageDropTableEntry.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  String _assetPath({
    required CableInsulation insulation,
    required VoltageDropCoreType coreType,
  }) {
    if (insulation == CableInsulation.pvc &&
        coreType == VoltageDropCoreType.singleCore) {
      return 'lib/assets/json/voltage_drop/table_9_1.json';
    }

    if (insulation == CableInsulation.pvc &&
        coreType == VoltageDropCoreType.multiCore) {
      return 'lib/assets/json/voltage_drop/table_9_2.json';
    }

    if (insulation == CableInsulation.xlpe &&
        coreType == VoltageDropCoreType.singleCore) {
      return 'lib/assets/json/voltage_drop/table_9_3.json';
    }

    return 'lib/assets/json/voltage_drop/table_9_4.json';
  }
}
