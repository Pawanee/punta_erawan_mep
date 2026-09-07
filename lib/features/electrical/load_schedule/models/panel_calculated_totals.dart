class PanelCalculatedTotals {
  PanelCalculatedTotals({
    required this.connectedVaR,
    required this.connectedVaS,
    required this.connectedVaT,
    required this.totalConnectedVa,
    this.demandLoadVa,
  }) {
    final values = [
      connectedVaR,
      connectedVaS,
      connectedVaT,
      totalConnectedVa,
      ?demandLoadVa,
    ];
    if (values.any((value) => value < 0 || !value.isFinite)) {
      throw ArgumentError('Calculated totals must be finite and non-negative.');
    }
  }

  final double connectedVaR;
  final double connectedVaS;
  final double connectedVaT;
  final double totalConnectedVa;
  final double? demandLoadVa;

  Map<String, Object?> toJson() => {
    'connectedVaR': connectedVaR,
    'connectedVaS': connectedVaS,
    'connectedVaT': connectedVaT,
    'totalConnectedVa': totalConnectedVa,
    if (demandLoadVa != null) 'demandLoadVa': demandLoadVa,
  };

  factory PanelCalculatedTotals.fromJson(Map<String, Object?> json) =>
      PanelCalculatedTotals(
        connectedVaR: (json['connectedVaR'] as num).toDouble(),
        connectedVaS: (json['connectedVaS'] as num).toDouble(),
        connectedVaT: (json['connectedVaT'] as num).toDouble(),
        totalConnectedVa: (json['totalConnectedVa'] as num).toDouble(),
        demandLoadVa: (json['demandLoadVa'] as num?)?.toDouble(),
      );
}
