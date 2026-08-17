import '../../enums/core_type.dart';
import '../../../voltage_drop/enums/cable_arrangement.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../../../voltage_drop/enums/voltage_drop_installation_group.dart';
import '../../../voltage_drop/enums/voltage_phase.dart';

/// Independently supplied, approved inputs required to continue to VD routing.
/// This contract is not inferred from any ampacity table or source column.
class VoltageDropContinuationContextV2 {
  const VoltageDropContinuationContextV2({
    required this.installationGroup,
    required this.arrangement,
    required this.insulation,
    required this.coreType,
    required this.phase,
    required this.systemVoltage,
    required this.lengthM,
  });

  final VoltageDropInstallationGroup installationGroup;
  final CableArrangement? arrangement;
  final CableInsulation insulation;
  final CoreType coreType;
  final VoltagePhase phase;
  final double systemVoltage;
  final double lengthM;
}
