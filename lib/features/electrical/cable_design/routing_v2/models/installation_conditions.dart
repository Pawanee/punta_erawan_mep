import '../../enums/core_type.dart';
import '../enums/installation_environment.dart';
import '../enums/installation_support.dart';

/// User-supplied installation facts. Sets allow conflicts to be represented
/// and reported explicitly rather than being silently collapsed.
class InstallationConditions {
  const InstallationConditions({
    required this.environments,
    required this.supports,
    required this.coreType,
    required this.hasOuterSheath,
    this.spacingAtLeastCableDiameter,
    this.ventilationOpeningPercent,
  });

  final Set<InstallationEnvironment> environments;
  final Set<InstallationSupport> supports;
  final CoreType coreType;
  final bool hasOuterSheath;
  final bool? spacingAtLeastCableDiameter;
  final double? ventilationOpeningPercent;
}
