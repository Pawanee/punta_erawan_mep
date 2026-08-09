 import 'dart:convert';

import 'package:flutter/services.dart';

import '../enums/cable_type.dart';
import '../enums/core_type.dart';
import '../enums/installation_method.dart';
import '../models/cable_table_row.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module : Electrical
/// Feature : Cable Design
/// File : table520_repository.dart
///
/// OFOR-051
///
/// Description
/// ----------------------------------------------------------------------------
///
/// Repository สำหรับอ่านข้อมูล Table 5-20
///
/// หน้าที่
///
/// • อ่าน JSON
/// • Mapping JSON → CableTableRow
/// • Return List<CableTableRow>
///
/// Repository นี้ไม่มีหน้าที่
///
/// ✗ เลือกสาย
/// ✗ คำนวณ
/// ✗ Filter
/// ✗ Sort
///
/// ============================================================================

class Table520Repository {
  static const String _assetPath =
      'lib/assets/json/table_5_20.json';

  Future<List<CableTableRow>> loadTable({
    required CableType cableType,
  }) async {
    final jsonString =
        await rootBundle.loadString(_assetPath);

    final Map<String, dynamic> json =
        jsonDecode(jsonString);

    final List<dynamic> rows =
        json[_JsonKey.rows] as List<dynamic>;

    final List<CableTableRow> result = [];

    for (final dynamic item in rows) {
      final Map<String, dynamic> row =
          item as Map<String, dynamic>;

      final double cableSize =
          (row[_JsonKey.sizeSqmm] as num).toDouble();

      for (final config in configList) {
        final dynamic ampacity =
            (((row[config.groupKey]
                    as Map<String, dynamic>)[config.loadedKey]
                as Map<String, dynamic>)[config.coreKey]);

        if (ampacity == null) {
          continue;
        }

        result.add(
          CableTableRow(
            cableType: cableType,

            installationMethod:
                config.installationMethod,

            loadedConductors:
                config.loadedConductors,

            coreType: config.coreType,

            cableSizeSqmm: cableSize,

            ampacity:
                (ampacity as num).toDouble(),

            remark: '',

            reference: 'Table 5-20',
          ),
        );
      }
    }

    return result;
  }
}

/// ============================================================================
/// JSON Keys
/// ============================================================================

class _JsonKey {
  static const rows = 'rows';

  static const sizeSqmm = 'sizeSqmm';

  static const group1 = 'group1';
  static const group2 = 'group2';

  static const twoLoaded = 'twoLoaded';
  static const threeLoaded = 'threeLoaded';

  static const singleCore = 'singleCore';
  static const multiCore = 'multiCore';
}

/// ============================================================================
/// Configuration สำหรับ Mapping ตาราง 5-20
/// ============================================================================

class _Config {
  final InstallationMethod installationMethod;

  final int loadedConductors;

  final CoreType coreType;

  final String groupKey;

  final String loadedKey;

  final String coreKey;

  const _Config({
    required this.installationMethod,
    required this.loadedConductors,
    required this.coreType,
    required this.groupKey,
    required this.loadedKey,
    required this.coreKey,
  });
}

/// ============================================================================
/// Mapping Configuration
///
/// ตาราง 5-20
///
/// 2 Groups
/// 2 Loaded Conductors
/// 2 Core Types
///
/// รวมทั้งหมด 8 รูปแบบ
/// ============================================================================

const List<_Config> configList = [
  // ---------------------------------------------------------------------------
  // GROUP 1
  // ---------------------------------------------------------------------------

  _Config(
    installationMethod: InstallationMethod.group1,
    loadedConductors: 2,
    coreType: CoreType.singleCore,
    groupKey: _JsonKey.group1,
    loadedKey: _JsonKey.twoLoaded,
    coreKey: _JsonKey.singleCore,
  ),

  _Config(
    installationMethod: InstallationMethod.group1,
    loadedConductors: 2,
    coreType: CoreType.multiCore,
    groupKey: _JsonKey.group1,
    loadedKey: _JsonKey.twoLoaded,
    coreKey: _JsonKey.multiCore,
  ),

  _Config(
    installationMethod: InstallationMethod.group1,
    loadedConductors: 3,
    coreType: CoreType.singleCore,
    groupKey: _JsonKey.group1,
    loadedKey: _JsonKey.threeLoaded,
    coreKey: _JsonKey.singleCore,
  ),

  _Config(
    installationMethod: InstallationMethod.group1,
    loadedConductors: 3,
    coreType: CoreType.multiCore,
    groupKey: _JsonKey.group1,
    loadedKey: _JsonKey.threeLoaded,
    coreKey: _JsonKey.multiCore,
  ),

  // ---------------------------------------------------------------------------
  // GROUP 2
  // ---------------------------------------------------------------------------

  _Config(
    installationMethod: InstallationMethod.group2,
    loadedConductors: 2,
    coreType: CoreType.singleCore,
    groupKey: _JsonKey.group2,
    loadedKey: _JsonKey.twoLoaded,
    coreKey: _JsonKey.singleCore,
  ),

  _Config(
    installationMethod: InstallationMethod.group2,
    loadedConductors: 2,
    coreType: CoreType.multiCore,
    groupKey: _JsonKey.group2,
    loadedKey: _JsonKey.twoLoaded,
    coreKey: _JsonKey.multiCore,
  ),

  _Config(
    installationMethod: InstallationMethod.group2,
    loadedConductors: 3,
    coreType: CoreType.singleCore,
    groupKey: _JsonKey.group2,
    loadedKey: _JsonKey.threeLoaded,
    coreKey: _JsonKey.singleCore,
  ),

  _Config(
    installationMethod: InstallationMethod.group2,
    loadedConductors: 3,
    coreType: CoreType.multiCore,
    groupKey: _JsonKey.group2,
    loadedKey: _JsonKey.threeLoaded,
    coreKey: _JsonKey.multiCore,
  ),
];