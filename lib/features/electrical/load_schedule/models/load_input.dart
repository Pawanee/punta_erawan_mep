enum LoadInputKind { directVa, directCurrentA, quantityTimesWatts }

class LoadInput {
  LoadInput._({
    required this.kind,
    this.apparentPowerVa,
    this.currentA,
    this.quantity,
    this.wattsPerUnit,
    this.powerFactor,
  }) {
    _validate();
  }

  factory LoadInput.directVa(double apparentPowerVa) => LoadInput._(
    kind: LoadInputKind.directVa,
    apparentPowerVa: apparentPowerVa,
  );

  factory LoadInput.directCurrentA(double currentA) =>
      LoadInput._(kind: LoadInputKind.directCurrentA, currentA: currentA);

  factory LoadInput.quantityTimesWatts({
    required int quantity,
    required double wattsPerUnit,
    required double powerFactor,
  }) => LoadInput._(
    kind: LoadInputKind.quantityTimesWatts,
    quantity: quantity,
    wattsPerUnit: wattsPerUnit,
    powerFactor: powerFactor,
  );

  final LoadInputKind kind;
  final double? apparentPowerVa;
  final double? currentA;
  final int? quantity;
  final double? wattsPerUnit;
  final double? powerFactor;

  void _validate() {
    final valid = switch (kind) {
      LoadInputKind.directVa =>
        apparentPowerVa != null &&
            apparentPowerVa! > 0 &&
            currentA == null &&
            quantity == null &&
            wattsPerUnit == null &&
            powerFactor == null,
      LoadInputKind.directCurrentA =>
        currentA != null &&
            currentA! > 0 &&
            apparentPowerVa == null &&
            quantity == null &&
            wattsPerUnit == null &&
            powerFactor == null,
      LoadInputKind.quantityTimesWatts =>
        quantity != null &&
            quantity! > 0 &&
            wattsPerUnit != null &&
            wattsPerUnit! > 0 &&
            powerFactor != null &&
            powerFactor! > 0 &&
            powerFactor! <= 1 &&
            apparentPowerVa == null &&
            currentA == null,
    };
    if (!valid) {
      throw ArgumentError(
        'LoadInput is incomplete or contains invalid values.',
      );
    }
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    if (apparentPowerVa != null) 'apparentPowerVa': apparentPowerVa,
    if (currentA != null) 'currentA': currentA,
    if (quantity != null) 'quantity': quantity,
    if (wattsPerUnit != null) 'wattsPerUnit': wattsPerUnit,
    if (powerFactor != null) 'powerFactor': powerFactor,
  };

  factory LoadInput.fromJson(Map<String, Object?> json) {
    final kind = LoadInputKind.values.byName(json['kind'] as String);
    return switch (kind) {
      LoadInputKind.directVa => LoadInput.directVa(
        (json['apparentPowerVa'] as num).toDouble(),
      ),
      LoadInputKind.directCurrentA => LoadInput.directCurrentA(
        (json['currentA'] as num).toDouble(),
      ),
      LoadInputKind.quantityTimesWatts => LoadInput.quantityTimesWatts(
        quantity: json['quantity'] as int,
        wattsPerUnit: (json['wattsPerUnit'] as num).toDouble(),
        powerFactor: (json['powerFactor'] as num).toDouble(),
      ),
    };
  }
}
