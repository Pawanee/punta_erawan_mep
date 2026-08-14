/// Conductor temperature classes represented in Master Table 5-43.
///
/// This enum is reference-data metadata only. It does not decide which
/// CableType uses which class; that policy belongs to a separate layer.
enum ConductorTemperatureClass {
  pvc70(
    material: 'PVC',
    temperatureC: 70,
    jsonKey: 'pvc70C',
  ),
  pvc90(
    material: 'PVC',
    temperatureC: 90,
    jsonKey: 'pvc90C',
  ),
  xlpeEpr90(
    material: 'XLPE/EPR',
    temperatureC: 90,
    jsonKey: 'xlpeEpr90C',
  ),
  mi70(
    material: 'MI',
    temperatureC: 70,
    jsonKey: 'mi70C',
  ),
  mi105(
    material: 'MI',
    temperatureC: 105,
    jsonKey: 'mi105C',
  );

  final String material;
  final int temperatureC;
  final String jsonKey;

  const ConductorTemperatureClass({
    required this.material,
    required this.temperatureC,
    required this.jsonKey,
  });
}
