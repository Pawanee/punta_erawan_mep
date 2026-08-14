import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/table_5_43_temperature_factor.dart';

/// Repository for Master Table 5-43 ambient-temperature correction factors.
///
/// This layer only loads and locates the published temperature ranges. It does
/// not choose a CableType or insulation class and does not interpolate values.
class Table543Repository {
  static const String assetPath =
      'lib/assets/json/table_5_43.json';

  Future<List<Table543TemperatureFactor>> loadTable() async {
    final jsonString = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;
    final List<dynamic> rows = json['rows'] as List<dynamic>;

    return rows
        .map(
          (row) => Table543TemperatureFactor.fromJson(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Table543TemperatureFactor?> findByAmbientTemperature(
    double ambientTemperatureC,
  ) async {
    final rows = await loadTable();

    for (final row in rows) {
      if (ambientTemperatureC >= row.ambientMinC &&
          ambientTemperatureC <= row.ambientMaxC) {
        return row;
      }
    }

    return null;
  }
}
