import '../../enums/cable_shape.dart';
import '../../enums/conductor_temperature_class.dart';
import '../../enums/core_type.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';

/// Additional source-supported facts supplied when the profile cannot
/// establish a required table dimension.
class RoutingCablePropertiesInput {
  const RoutingCablePropertiesInput({
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
