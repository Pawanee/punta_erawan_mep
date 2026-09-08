import '../../cable_design/enums/cable_shape.dart';
import '../../cable_design/enums/conductor_temperature_class.dart';
import '../../cable_design/enums/core_type.dart';
import '../../cable_design/models/cable_routing_identity.dart';
import '../../cable_design/models/engineering_installation_input.dart';
import '../../cable_design/models/supplemental_cable_properties_input.dart';
import '../../cable_design/routing_v2/enums/installation_environment.dart';
import '../../cable_design/routing_v2/enums/installation_support.dart';
import '../../voltage_drop/enums/cable_insulation.dart';

/// Explicit user engineering facts for Load Schedule ampacity routing.
/// No installation, temperature, grouping, or construction defaults are used.
class CableCoordinationInput {
  CableCoordinationInput({
    required this.identity,
    required this.coreType,
    required this.ambientTemperatureC,
    required Set<InstallationEnvironment> environments,
    required Set<InstallationSupport> supports,
    required this.groupedCircuitCount,
    this.hasOuterSheath,
    this.spacingAtLeastCableDiameter,
    this.ventilationOpeningPercent,
    this.cableShape,
    this.insulation,
    this.conductorTemperatureClass,
  }) : environments = Set.unmodifiable(environments),
       supports = Set.unmodifiable(supports) {
    if (!ambientTemperatureC.isFinite) {
      throw ArgumentError.value(
        ambientTemperatureC,
        'ambientTemperatureC',
        'Must be finite.',
      );
    }
    if (environments.isEmpty || supports.isEmpty) {
      throw ArgumentError(
        'Installation environments and supports are required.',
      );
    }
    if (groupedCircuitCount <= 0) {
      throw ArgumentError.value(
        groupedCircuitCount,
        'groupedCircuitCount',
        'Must be positive.',
      );
    }
    if (ventilationOpeningPercent != null &&
        (!ventilationOpeningPercent!.isFinite ||
            ventilationOpeningPercent! < 0 ||
            ventilationOpeningPercent! > 100)) {
      throw ArgumentError.value(
        ventilationOpeningPercent,
        'ventilationOpeningPercent',
        'Must be finite and between 0 and 100.',
      );
    }
  }

  final CableRoutingIdentity identity;
  final CoreType coreType;
  final double ambientTemperatureC;
  final Set<InstallationEnvironment> environments;
  final Set<InstallationSupport> supports;
  final int groupedCircuitCount;
  final bool? hasOuterSheath;
  final bool? spacingAtLeastCableDiameter;
  final double? ventilationOpeningPercent;
  final CableShape? cableShape;
  final CableInsulation? insulation;
  final ConductorTemperatureClass? conductorTemperatureClass;

  EngineeringInstallationInput toEngineeringInstallation() =>
      EngineeringInstallationInput(
        environments: environments,
        supports: supports,
        hasOuterSheath: hasOuterSheath,
        spacingAtLeastCableDiameter: spacingAtLeastCableDiameter,
        ventilationOpeningPercent: ventilationOpeningPercent,
        groupedCircuitCount: groupedCircuitCount,
      );

  SupplementalCablePropertiesInput toSupplementalProperties() =>
      SupplementalCablePropertiesInput(
        cableShape: cableShape,
        coreType: coreType,
        insulation: insulation,
        conductorTemperatureClass: conductorTemperatureClass,
        hasOuterSheath: hasOuterSheath,
      );

  Map<String, Object?> toJson() => {
    'identity': identity.name,
    'coreType': coreType.name,
    'ambientTemperatureC': ambientTemperatureC,
    'environments': environments.map((item) => item.name).toList()..sort(),
    'supports': supports.map((item) => item.name).toList()..sort(),
    'groupedCircuitCount': groupedCircuitCount,
    if (hasOuterSheath != null) 'hasOuterSheath': hasOuterSheath,
    if (spacingAtLeastCableDiameter != null)
      'spacingAtLeastCableDiameter': spacingAtLeastCableDiameter,
    if (ventilationOpeningPercent != null)
      'ventilationOpeningPercent': ventilationOpeningPercent,
    if (cableShape != null) 'cableShape': cableShape!.name,
    if (insulation != null) 'insulation': insulation!.name,
    if (conductorTemperatureClass != null)
      'conductorTemperatureClass': conductorTemperatureClass!.name,
  };

  factory CableCoordinationInput.fromJson(
    Map<String, Object?> json,
  ) => CableCoordinationInput(
    identity: CableRoutingIdentity.values.byName(json['identity'] as String),
    coreType: CoreType.values.byName(json['coreType'] as String),
    ambientTemperatureC: (json['ambientTemperatureC'] as num).toDouble(),
    environments: (json['environments'] as List)
        .map((item) => InstallationEnvironment.values.byName(item as String))
        .toSet(),
    supports: (json['supports'] as List)
        .map((item) => InstallationSupport.values.byName(item as String))
        .toSet(),
    groupedCircuitCount: json['groupedCircuitCount'] as int,
    hasOuterSheath: json['hasOuterSheath'] as bool?,
    spacingAtLeastCableDiameter: json['spacingAtLeastCableDiameter'] as bool?,
    ventilationOpeningPercent: (json['ventilationOpeningPercent'] as num?)
        ?.toDouble(),
    cableShape: json['cableShape'] == null
        ? null
        : CableShape.values.byName(json['cableShape'] as String),
    insulation: json['insulation'] == null
        ? null
        : CableInsulation.values.byName(json['insulation'] as String),
    conductorTemperatureClass: json['conductorTemperatureClass'] == null
        ? null
        : ConductorTemperatureClass.values.byName(
            json['conductorTemperatureClass'] as String,
          ),
  );
}
