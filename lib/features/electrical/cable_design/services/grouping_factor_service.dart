import '../repositories/table_5_8_repository.dart';

class GroupingFactorService {
  final _repository = Table5_8Repository();

  Future<double> getFactor({
    required int circuits,
    required bool enclosed,
  }) async {
    final data = await _repository.load();

    for (final row in data) {
      if (_matchCircuit(row.circuits, circuits)) {
        return enclosed
            ? row.enclosedFactor
            : row.surfaceFactor;
      }
    }

    return 1.0;
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