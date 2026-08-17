import '../../voltage_drop/enums/cable_insulation.dart';
import '../enums/cable_shape.dart';
import '../enums/conductor_temperature_class.dart';
import '../enums/core_type.dart';

/// Source-supported intrinsic facts supplied only when a Table 5-48 profile
/// does not establish them. Profile facts remain authoritative.
class SupplementalCablePropertiesInput {
  const SupplementalCablePropertiesInput({
    this.cableShape,
    this.coreType,
    this.insulation,
    this.conductorTemperatureClass,
    this.hasOuterSheath,
  });

  final CableShape? cableShape;
  final CoreType? coreType;
  final CableInsulation? insulation;
  final ConductorTemperatureClass? conductorTemperatureClass;
  final bool? hasOuterSheath;
}
