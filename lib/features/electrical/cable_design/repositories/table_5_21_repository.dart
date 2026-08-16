import 'dart:convert';

import 'package:flutter/services.dart';

import '../enums/cable_shape.dart';
import '../enums/conductor_temperature_class.dart';
import '../enums/core_type.dart';
import '../enums/electrical_system_applicability.dart';
import '../models/table_5_21_column.dart';
import '../models/table_5_21_data.dart';
import '../models/table_5_21_row.dart';
import '../../voltage_drop/enums/cable_insulation.dart';

/// Data access for Master Table 5-21.
///
/// This repository loads and filters published table cells only. It never
/// interpolates, estimates, substitutes a different table, or applies factors.
class Table521Repository {
  static const String assetPath = 'lib/assets/json/table_5_21.json';

  Future<Table521Data> loadTable() async {
    final jsonString = await rootBundle.loadString(assetPath);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final columns = (json['columns'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_columnFromJson)
        .toList(growable: false);
    final rows = (json['rows'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_rowFromJson)
        .toList(growable: false);
    return Table521Data(columns: columns, rows: rows);
  }

  /// Looks up a single published cell from its exact Table 5-21 dimensions.
  /// Returns null for an unavailable source cell, a non-existent column, or
  /// dimensions that do not identify exactly one published source column.
  Future<double?> lookup({
    required double sizeSqmm,
    required CableShape cableShape,
    required CoreType coreType,
    required CableInsulation insulation,
    required ConductorTemperatureClass conductorTemperatureClass,
    required int loadedConductors,
    required ElectricalSystemApplicability systemApplicability,
    String? cableTypeCode,
  }) async {
    final data = await loadTable();
    final column = data.columns.where((candidate) {
      final matchesDimensions =
          candidate.cableShape == cableShape &&
          candidate.coreType == coreType &&
          candidate.insulation == insulation &&
          candidate.conductorTemperatureClass == conductorTemperatureClass &&
          candidate.loadedConductors == loadedConductors &&
          candidate.systemApplicability == systemApplicability;
      final matchesCableType = cableTypeCode == null
          ? candidate.applicableCableTypeCodes.isEmpty
          : candidate.applicableCableTypeCodes.contains(cableTypeCode);
      return matchesDimensions && matchesCableType;
    }).toList();

    if (column.length != 1) {
      return null;
    }
    final row = data.rows.where((row) => row.sizeSqmm == sizeSqmm).toList();
    if (row.length != 1) {
      return null;
    }
    return row.single.ampacityForColumn(column.single.id);
  }

  /// Looks up one published cell by its exact source-column identity.
  /// Returns null for an unavailable cell or an unknown size/column; it does
  /// not substitute another column or ampacity table.
  Future<double?> lookupByColumnId({
    required double sizeSqmm,
    required String columnId,
  }) async {
    final data = await loadTable();
    if (!data.columns.any((column) => column.id == columnId)) {
      return null;
    }
    final row = data.rows.where((row) => row.sizeSqmm == sizeSqmm).toList();
    if (row.length != 1) {
      return null;
    }
    return row.single.ampacityForColumn(columnId);
  }

  Table521Column _columnFromJson(Map<String, dynamic> json) {
    return Table521Column(
      id: json['id'] as String,
      cableShape: CableShape.values.byName(json['shape'] as String),
      coreType: CoreType.values.byName(json['coreType'] as String),
      insulation: CableInsulation.values.byName(json['insulation'] as String),
      conductorTemperatureClass: ConductorTemperatureClass.values.byName(
        json['conductorTemperatureClass'] as String,
      ),
      loadedConductors: json['loadedConductors'] as int,
      systemApplicability: ElectricalSystemApplicability.values.byName(
        json['systemApplicability'] as String,
      ),
      applicableCableTypeCodes:
          (json['applicableCableTypeCodes'] as List<dynamic>).cast<String>(),
    );
  }

  Table521Row _rowFromJson(Map<String, dynamic> json) {
    final ampacity = json['ampacity'] as Map<String, dynamic>;
    return Table521Row(
      sizeSqmm: (json['sizeSqmm'] as num).toDouble(),
      ampacityByColumnId: ampacity.map(
        (id, value) => MapEntry(id, (value as num?)?.toDouble()),
      ),
    );
  }
}
