 import '../models/cable_input.dart';
import '../models/cable_result.dart';

class CableEngine {
  CableResult calculate(CableInput input) {
    String cableSize;
    String breakerSize;

    final current = input.loadCurrent;

    if (current <= 20) {
      cableSize = "2.5 sq.mm";
      breakerSize = "20 A";
    } else if (current <= 25) {
      cableSize = "4 sq.mm";
      breakerSize = "32 A";
    } else if (current <= 32) {
      cableSize = "6 sq.mm";
      breakerSize = "40 A";
    } else if (current <= 50) {
      cableSize = "10 sq.mm";
      breakerSize = "63 A";
    } else if (current <= 63) {
      cableSize = "16 sq.mm";
      breakerSize = "80 A";
    } else if (current <= 80) {
      cableSize = "25 sq.mm";
      breakerSize = "100 A";
    } else if (current <= 100) {
      cableSize = "35 sq.mm";
      breakerSize = "125 A";
    } else {
      cableSize = "Consult Engineer";
      breakerSize = "Consult Engineer";
    }

    return CableResult(
      cableSize: cableSize,
      breakerSize: breakerSize,
      groundSize: "-",
      neutralSize: "-",
      conduitSize: "-",
      currentCapacity: current,
      voltageDrop: input.voltageDrop,
      pass: true,
    );
  }
}