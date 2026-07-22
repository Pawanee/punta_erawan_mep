class CableResult {
  final String cableSize;

  final String breakerSize;

  final String groundSize;

  final String neutralSize;

  final String conduitSize;

  final double currentCapacity;

  final double voltageDrop;

  final bool pass;

  CableResult({
    required this.cableSize,
    required this.breakerSize,
    required this.groundSize,
    required this.neutralSize,
    required this.conduitSize,
    required this.currentCapacity,
    required this.voltageDrop,
    required this.pass,
  });
}