/// ============================================================================
/// GROUPING FACTOR MODEL
///
/// Table 5-8
/// ตัวคูณลดกระแสจากการเดินหลายวงจร
/// ============================================================================

class GroupingFactor {
  final String circuits;

  final double enclosedFactor;

  final double surfaceFactor;

  const GroupingFactor({
    required this.circuits,
    required this.enclosedFactor,
    required this.surfaceFactor,
  });

  factory GroupingFactor.fromJson(
    Map<String, dynamic> json,
  ) {
    return GroupingFactor(
      circuits: json['circuits'],
      enclosedFactor:
          (json['enclosedFactor'] as num).toDouble(),
      surfaceFactor:
          (json['surfaceFactor'] as num).toDouble(),
    );
  }
}