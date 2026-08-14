import '../enums/conductor_temperature_class.dart';

/// One ambient-temperature range from Master Table 5-43.
///
/// Null means the Master table does not provide a factor for that class in
/// that temperature range. No interpolation or fallback is performed here.
class Table543TemperatureFactor {
  static const String reference = 'Table 5-43';
  static const int baseAmbientTemperatureC = 40;

  final int ambientMinC;
  final int ambientMaxC;
  final double? pvc70C;
  final double? pvc90C;
  final double? xlpeEpr90C;
  final double? mi70C;
  final double? mi105C;

  const Table543TemperatureFactor({
    required this.ambientMinC,
    required this.ambientMaxC,
    required this.pvc70C,
    required this.pvc90C,
    required this.xlpeEpr90C,
    required this.mi70C,
    required this.mi105C,
  });

  factory Table543TemperatureFactor.fromJson(
    Map<String, dynamic> json,
  ) {
    double? value(String key) =>
        (json[key] as num?)?.toDouble();

    return Table543TemperatureFactor(
      ambientMinC: json['ambientMinC'] as int,
      ambientMaxC: json['ambientMaxC'] as int,
      pvc70C: value('pvc70C'),
      pvc90C: value('pvc90C'),
      xlpeEpr90C: value('xlpeEpr90C'),
      mi70C: value('mi70C'),
      mi105C: value('mi105C'),
    );
  }

  double? factorFor(ConductorTemperatureClass temperatureClass) {
    switch (temperatureClass) {
      case ConductorTemperatureClass.pvc70:
        return pvc70C;
      case ConductorTemperatureClass.pvc90:
        return pvc90C;
      case ConductorTemperatureClass.xlpeEpr90:
        return xlpeEpr90C;
      case ConductorTemperatureClass.mi70:
        return mi70C;
      case ConductorTemperatureClass.mi105:
        return mi105C;
    }
  }
}
