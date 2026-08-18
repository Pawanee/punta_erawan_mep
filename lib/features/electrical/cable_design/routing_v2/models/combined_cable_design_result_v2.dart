import '../enums/combined_cable_design_status_v2.dart';
import 'ampacity_design_result_v2.dart';
import 'voltage_drop_verification_result_v2.dart';

class CombinedCableDesignResultV2 {
  const CombinedCableDesignResultV2({
    required this.status,
    required this.ampacityResult,
    required this.voltageDropResult,
  });
  final CombinedCableDesignStatusV2 status;
  final AmpacityDesignResultV2 ampacityResult;
  final VoltageDropVerificationResultV2 voltageDropResult;
}
