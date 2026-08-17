import 'dart:convert';

import 'package:flutter/services.dart';

import '../../enums/core_type.dart';
import '../enums/installation_environment.dart';
import '../enums/installation_support.dart';
import '../models/installation_conditions.dart';
import '../models/installation_reference.dart';
import '../models/installation_reference_resolution.dart';

/// Data access and deterministic resolution for Master Table 5-47.
///
/// Resolution never assigns a group by precedence.
class InstallationReferenceRepository {
  static const String assetPath = 'lib/assets/json/table_5_47.json';

  Future<List<InstallationReference>> loadReferences() async {
    final source = await rootBundle.loadString(assetPath);
    final json = jsonDecode(source) as Map<String, dynamic>;
    return (json['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList(growable: false);
  }

  Future<InstallationReferenceResolution> resolve(
    InstallationConditions conditions,
  ) async {
    final references = await loadReferences();
    if (conditions.environments.isEmpty || conditions.supports.isEmpty) {
      return const InstallationReferenceResolution(
        status: InstallationReferenceResolutionStatus.insufficient,
        matches: [],
      );
    }
    final potentialMatches = references
        .where((reference) => _matchesBase(reference, conditions))
        .toList(growable: false);
    if (_hasMissingRequiredConstraint(potentialMatches, conditions)) {
      return InstallationReferenceResolution(
        status: InstallationReferenceResolutionStatus.insufficient,
        matches: potentialMatches,
      );
    }
    final matches = potentialMatches
        .where((reference) => _matches(reference, conditions))
        .toList(growable: false);
    final status = switch (matches.length) {
      0 => InstallationReferenceResolutionStatus.noMatch,
      1 => InstallationReferenceResolutionStatus.resolved,
      _ => InstallationReferenceResolutionStatus.ambiguous,
    };
    return InstallationReferenceResolution(status: status, matches: matches);
  }

  bool _matches(
    InstallationReference reference,
    InstallationConditions conditions,
  ) {
    if (!_matchesBase(reference, conditions)) {
      return false;
    }
    if (reference.minimumCableDiameterSpacing &&
        conditions.spacingAtLeastCableDiameter != true) {
      return false;
    }
    if (conditions.supports.contains(InstallationSupport.ventilatedCableTray) &&
        reference.supports.contains(InstallationSupport.ventilatedCableTray) &&
        (conditions.ventilationOpeningPercent == null ||
            conditions.ventilationOpeningPercent! <
                reference.minimumVentilationOpeningPercent!)) {
      return false;
    }
    return true;
  }

  bool _matchesBase(
    InstallationReference reference,
    InstallationConditions conditions,
  ) {
    return reference.coreTypes.contains(conditions.coreType) &&
        (reference.outerSheathRequired == null ||
            reference.outerSheathRequired == conditions.hasOuterSheath) &&
        conditions.environments.any(reference.environments.contains) &&
        conditions.supports.any(reference.supports.contains);
  }

  bool _hasMissingRequiredConstraint(
    List<InstallationReference> references,
    InstallationConditions conditions,
  ) {
    return references.any(
      (reference) =>
          reference.minimumCableDiameterSpacing &&
              conditions.spacingAtLeastCableDiameter == null ||
          reference.supports.contains(
                InstallationSupport.ventilatedCableTray,
              ) &&
              conditions.supports.contains(
                InstallationSupport.ventilatedCableTray,
              ) &&
              conditions.ventilationOpeningPercent == null,
    );
  }

  InstallationReference _fromJson(Map<String, dynamic> json) {
    return InstallationReference(
      group: json['group'] as int,
      coreTypes: (json['coreTypes'] as List<dynamic>)
          .cast<String>()
          .map(CoreType.values.byName)
          .toSet(),
      outerSheathRequired: switch (json['outerSheath'] as String) {
        'required' => true,
        'any' => null,
        _ => throw FormatException('Unknown outer-sheath requirement.'),
      },
      environments: (json['environments'] as List<dynamic>)
          .cast<String>()
          .map(InstallationEnvironment.values.byName)
          .toSet(),
      supports: (json['supports'] as List<dynamic>)
          .cast<String>()
          .map(InstallationSupport.values.byName)
          .toSet(),
      minimumCableDiameterSpacing:
          json['minimumCableDiameterSpacing'] as bool? ?? false,
      minimumVentilationOpeningPercent:
          (json['minimumVentilationOpeningPercent'] as num?)?.toDouble(),
      notes: (json['notes'] as List<dynamic>).cast<String>(),
      sourceReference: 'Table 5-47',
    );
  }
}
