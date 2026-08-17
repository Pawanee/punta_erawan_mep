import '../../enums/core_type.dart';
import '../enums/installation_environment.dart';
import '../enums/installation_support.dart';

/// Published installation-group characteristics from Master Table 5-47.
class InstallationReference {
  const InstallationReference({
    required this.group,
    required this.coreTypes,
    required this.outerSheathRequired,
    required this.environments,
    required this.supports,
    required this.minimumCableDiameterSpacing,
    required this.minimumVentilationOpeningPercent,
    required this.notes,
    required this.sourceReference,
  });

  final int group;
  final Set<CoreType> coreTypes;
  final bool? outerSheathRequired;
  final Set<InstallationEnvironment> environments;
  final Set<InstallationSupport> supports;
  final bool minimumCableDiameterSpacing;
  final double? minimumVentilationOpeningPercent;
  final List<String> notes;
  final String sourceReference;
}
