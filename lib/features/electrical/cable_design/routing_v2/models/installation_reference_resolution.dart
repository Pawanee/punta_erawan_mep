import 'installation_reference.dart';

enum InstallationReferenceResolutionStatus {
  resolved,
  insufficient,
  ambiguous,
  noMatch,
}

/// Deterministic resolution outcome; [reference] is set only for one match.
class InstallationReferenceResolution {
  const InstallationReferenceResolution({
    required this.status,
    required this.matches,
  });

  final InstallationReferenceResolutionStatus status;
  final List<InstallationReference> matches;

  InstallationReference? get reference =>
      status == InstallationReferenceResolutionStatus.resolved
      ? matches.single
      : null;
}
