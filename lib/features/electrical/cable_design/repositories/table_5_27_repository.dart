import 'dart:convert';

import 'package:flutter/services.dart';

import '../enums/core_type.dart';
import '../enums/installation_method.dart';
import '../models/table_5_27_row.dart';

/// Repository for Master Table 5-27.
///
/// Responsibilities:
/// - load the approved Table 5-27 JSON asset;
/// - map table cells to typed rows;
/// - preserve the table's Group 1/2, 2/3 loaded-conductor and core-type
///   structure.
///
/// This repository does not decide CableType → XLPE policy and does not apply
/// grouping or ambient-temperature corrections.
class Table527Repository {
  static const String assetPath =
      'lib/assets/json/table_5_27.json';

  Future<List<Table527Row>> loadTable() async {
    final jsonString = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;
    final List<dynamic> rows = json['rows'] as List<dynamic>;

    final result = <Table527Row>[];

    for (final item in rows) {
      final row = item as Map<String, dynamic>;

      for (final config in _configs) {
        final value = (((row[config.groupKey]
                as Map<String, dynamic>)[config.loadedKey]
            as Map<String, dynamic>)[config.coreKey]);

        if (value == null) {
          continue;
        }

        result.add(
          Table527Row(
            cableSizeSqmm: (row['sizeSqmm'] as num).toDouble(),
            installationMethod: config.installationMethod,
            loadedConductors: config.loadedConductors,
            coreType: config.coreType,
            ampacity: (value as num).toDouble(),
          ),
        );
      }
    }

    return result;
  }
}

class _Table527Config {
  final InstallationMethod installationMethod;
  final int loadedConductors;
  final CoreType coreType;
  final String groupKey;
  final String loadedKey;
  final String coreKey;

  const _Table527Config({
    required this.installationMethod,
    required this.loadedConductors,
    required this.coreType,
    required this.groupKey,
    required this.loadedKey,
    required this.coreKey,
  });
}

const List<_Table527Config> _configs = [
  _Table527Config(
    installationMethod: InstallationMethod.group1,
    loadedConductors: 2,
    coreType: CoreType.singleCore,
    groupKey: 'group1',
    loadedKey: 'twoLoaded',
    coreKey: 'singleCore',
  ),
  _Table527Config(
    installationMethod: InstallationMethod.group1,
    loadedConductors: 2,
    coreType: CoreType.multiCore,
    groupKey: 'group1',
    loadedKey: 'twoLoaded',
    coreKey: 'multiCore',
  ),
  _Table527Config(
    installationMethod: InstallationMethod.group1,
    loadedConductors: 3,
    coreType: CoreType.singleCore,
    groupKey: 'group1',
    loadedKey: 'threeLoaded',
    coreKey: 'singleCore',
  ),
  _Table527Config(
    installationMethod: InstallationMethod.group1,
    loadedConductors: 3,
    coreType: CoreType.multiCore,
    groupKey: 'group1',
    loadedKey: 'threeLoaded',
    coreKey: 'multiCore',
  ),
  _Table527Config(
    installationMethod: InstallationMethod.group2,
    loadedConductors: 2,
    coreType: CoreType.singleCore,
    groupKey: 'group2',
    loadedKey: 'twoLoaded',
    coreKey: 'singleCore',
  ),
  _Table527Config(
    installationMethod: InstallationMethod.group2,
    loadedConductors: 2,
    coreType: CoreType.multiCore,
    groupKey: 'group2',
    loadedKey: 'twoLoaded',
    coreKey: 'multiCore',
  ),
  _Table527Config(
    installationMethod: InstallationMethod.group2,
    loadedConductors: 3,
    coreType: CoreType.singleCore,
    groupKey: 'group2',
    loadedKey: 'threeLoaded',
    coreKey: 'singleCore',
  ),
  _Table527Config(
    installationMethod: InstallationMethod.group2,
    loadedConductors: 3,
    coreType: CoreType.multiCore,
    groupKey: 'group2',
    loadedKey: 'threeLoaded',
    coreKey: 'multiCore',
  ),
];
