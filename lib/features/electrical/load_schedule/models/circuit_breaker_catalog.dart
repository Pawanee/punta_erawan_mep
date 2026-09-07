import '../enums/breaker_type.dart';

class CircuitBreakerCatalog {
  static const String version = 'load-schedule-cb-catalog-v1';

  static const List<double> mcbRatingsA = [
    6,
    10,
    16,
    20,
    25,
    32,
    40,
    50,
    63,
    80,
    100,
    125,
  ];

  static const List<double> mccbRatingsA = [
    16,
    20,
    25,
    32,
    40,
    50,
    63,
    80,
    100,
    125,
    160,
    200,
    225,
    250,
    315,
    400,
    500,
    630,
    800,
    1000,
    1250,
    1600,
  ];

  static List<double> ratingsFor(BreakerType type) => switch (type) {
    BreakerType.mcb => mcbRatingsA,
    BreakerType.mccb => mccbRatingsA,
  };

  static bool contains(BreakerType type, double ratingA) =>
      ratingsFor(type).contains(ratingA);
}
