import 'dart:convert';

import 'package:flutter/services.dart';

import '../../enums/cable_shape.dart';
import '../../enums/core_type.dart';
import '../../enums/conductor_temperature_class.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../enums/cable_conductor_construction.dart';
import '../enums/cable_profile_type.dart';
import '../enums/installation_environment.dart';
import '../enums/installation_support.dart';
import '../models/cable_type_profile.dart';

/// Data access for approved Table 5-48 cable engineering facts.
///
/// IEC 60502-1 is intentionally unresolved because it is absent from the
/// approved Table 5-48 source supplied for this phase.
class CableTypeProfileRepository {
  const CableTypeProfileRepository();

  static const String assetPath = 'lib/assets/json/table_5_48.json';

  Future<List<CableTypeProfile>> loadProfiles() async {
    final source = await rootBundle.loadString(assetPath);
    final json = jsonDecode(source) as Map<String, dynamic>;
    return (json['profiles'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList(growable: false);
  }

  Future<CableTypeProfile> profileFor(CableProfileType cableType) async {
    if (cableType == CableProfileType.iec605021) {
      return _unresolvedIec605021();
    }
    return (await loadProfiles()).singleWhere(
      (profile) => profile.cableType == cableType,
    );
  }

  CableTypeProfile _fromJson(Map<String, dynamic> json) {
    return CableTypeProfile(
      cableType: CableProfileType.values.singleWhere(
        (type) => type.code == json['cableCode'],
      ),
      sizeRanges: (json['sizeRanges'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
      conductorConstructions: _enumSet(
        json['conductorConstructions'],
        CableConductorConstruction.values.byName,
      ),
      coreTypes: _enumSet(json['coreTypes'], CoreType.values.byName),
      nominalCoreConfiguration: json['nominalCoreConfiguration'] as String?,
      conductorTemperatureC: json['conductorTemperatureC'] as int?,
      conductorTemperatureClass:
          (json['conductorTemperatureClass'] as String?) == null
          ? null
          : ConductorTemperatureClass.values.byName(
              json['conductorTemperatureClass'] as String,
            ),
      insulation: (json['insulation'] as String?) == null
          ? null
          : CableInsulation.values.byName(json['insulation'] as String),
      hasOuterSheath: json['outerSheath'] as bool?,
      cableShape: (json['cableShape'] as String?) == null
          ? null
          : CableShape.values.byName(json['cableShape'] as String),
      ratedVoltage: json['ratedVoltage'] as String?,
      permittedEnvironments: _enumSet(
        json['permittedEnvironments'],
        InstallationEnvironment.values.byName,
      ),
      permittedSupports: _enumSet(
        json['permittedSupports'],
        InstallationSupport.values.byName,
      ),
      prohibitedEnvironments: _enumSet(
        json['prohibitedEnvironments'],
        InstallationEnvironment.values.byName,
      ),
      prohibitedSupports: _enumSet(
        json['prohibitedSupports'],
        InstallationSupport.values.byName,
      ),
      sourceReferences: (json['sourceReferences'] as List<dynamic>)
          .cast<String>(),
      notes: (json['notes'] as List<dynamic>).cast<String>(),
    );
  }

  Set<T> _enumSet<T>(dynamic rawValues, T Function(String) fromName) {
    return (rawValues as List<dynamic>).cast<String>().map(fromName).toSet();
  }

  CableTypeProfile _unresolvedIec605021() {
    return const CableTypeProfile(
      cableType: CableProfileType.iec605021,
      sizeRanges: {},
      conductorConstructions: {},
      coreTypes: {},
      nominalCoreConfiguration: null,
      conductorTemperatureC: null,
      conductorTemperatureClass: null,
      insulation: null,
      hasOuterSheath: null,
      cableShape: null,
      ratedVoltage: null,
      permittedEnvironments: {},
      permittedSupports: {},
      prohibitedEnvironments: {},
      prohibitedSupports: {},
      sourceReferences: [],
      notes: [
        'Unresolved: approved Table 5-48 source does not define IEC 60502-1.',
      ],
    );
  }
}
