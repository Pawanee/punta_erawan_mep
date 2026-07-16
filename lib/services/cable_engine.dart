 import '../models/cable_input.dart';
import '../models/cable_result.dart';

class CableEngine {
  CableResult calculate(CableInput input) {
    return CableResult(
      cableSize: "Not Calculated",
      breakerSize: "Not Calculated",
      groundSize: "Not Calculated",
      neutralSize: "Not Calculated",
      conduitSize: "Not Calculated",
      currentCapacity: input.loadCurrent,
      voltageDrop: input.voltageDrop,
      pass: false,
    );
  }
}