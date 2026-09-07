import 'dart:convert';

import 'package:flutter/services.dart';

import '../enums/core_type.dart';
import '../models/underground_ampacity_row.dart';

/// Source-faithful loader shared by Tables 5-23 and 5-29.
class UndergroundAmpacityRepository {
  const UndergroundAmpacityRepository({
    required this.tableId,
    required this.assetPath,
  });

  final String tableId;
  final String assetPath;

  Future<List<UndergroundAmpacityRow>> loadTable() async {
    final source = await rootBundle.loadString(assetPath);
    final json = jsonDecode(source) as Map<String, dynamic>;
    final rows = <UndergroundAmpacityRow>[];

    for (final raw
        in (json['rows'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final size = (raw['sizeSqmm'] as num).toDouble();
      _appendForBothCoreTypes(
        rows,
        size: size,
        group: 5,
        loaded: 2,
        ampacity: (raw['group5TwoLoaded'] as num).toDouble(),
      );
      _appendForBothCoreTypes(
        rows,
        size: size,
        group: 5,
        loaded: 3,
        ampacity: (raw['group5ThreeLoaded'] as num).toDouble(),
      );
      for (final loaded in const [2, 3]) {
        _appendForBothCoreTypes(
          rows,
          size: size,
          group: 6,
          loaded: loaded,
          ampacity: (raw['group6UpToThreeLoaded'] as num).toDouble(),
        );
      }
    }

    return List.unmodifiable(rows);
  }

  void _appendForBothCoreTypes(
    List<UndergroundAmpacityRow> rows, {
    required double size,
    required int group,
    required int loaded,
    required double ampacity,
  }) {
    for (final coreType in const [CoreType.singleCore, CoreType.multiCore]) {
      rows.add(
        UndergroundAmpacityRow(
          tableId: tableId,
          sizeSqmm: size,
          installationGroupNumber: group,
          loadedConductors: loaded,
          coreType: coreType,
          ampacity: ampacity,
        ),
      );
    }
  }
}
