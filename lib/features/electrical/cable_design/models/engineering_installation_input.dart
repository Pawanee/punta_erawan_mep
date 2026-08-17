import '../routing_v2/enums/installation_environment.dart';
import '../routing_v2/enums/installation_support.dart';

/// Explicit physical installation facts at the production-domain boundary.
///
/// This model intentionally uses physical facts rather than a raw Table 5-47
/// group. Null fields are unknown and must never be defaulted by an adapter.
class EngineeringInstallationInput {
  const EngineeringInstallationInput({
    this.environments,
    this.supports,
    this.hasOuterSheath,
    this.spacingAtLeastCableDiameter,
    this.ventilationOpeningPercent,
  });

  final Set<InstallationEnvironment>? environments;
  final Set<InstallationSupport>? supports;
  final bool? hasOuterSheath;
  final bool? spacingAtLeastCableDiameter;
  final double? ventilationOpeningPercent;
}
