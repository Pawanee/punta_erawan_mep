 import '../repositories/table_5_8_repository.dart';

class GroupingFactorService {
  final _repository = Table5_8Repository();

  /// Resolves an approved Table 5-8 factor without applying a fallback.
  /// One circuit is explicitly approved as an ungrouped installation.
  Future<double?> resolve({
    required int circuits,
    required bool enclosed,
  }) async {
    if (circuits == 1) {
      return 1.0;
    }

    final data = await _repository.load();

    for (final row in data) {
      if (_matchCircuit(row.circuits, circuits)) {
        return enclosed ? row.enclosedFactor : row.surfaceFactor;
      }
    }

    return null;
  }

  /// Legacy compatibility API. New active calculation flow must use [resolve]
  /// so unsupported circuit counts are surfaced as errors.
  Future<double> getFactor({
    required int circuits,
    required bool enclosed,
  }) async {
    return await resolve(circuits: circuits, enclosed: enclosed) ?? 1.0;
  }

  bool _matchCircuit(String range, int value) {
    if (!range.contains('-')) {
      return int.parse(range) == value;
    }

    final parts = range.split('-');

    final start = int.parse(parts[0]);

    final end = int.parse(parts[1]);

    return value >= start && value <= end;
  }
}
