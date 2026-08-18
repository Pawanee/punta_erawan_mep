import '../../enums/core_type.dart';
import '../../../voltage_drop/enums/voltage_drop_core_type.dart';
import '../../../voltage_drop/models/voltage_drop_request.dart';
import '../../../voltage_drop/repositories/voltage_drop_repository.dart';
import '../../../voltage_drop/services/voltage_drop_calculation_service.dart';
import '../enums/ampacity_routing_status.dart';
import '../enums/voltage_drop_verification_status_v2.dart';
import '../models/ampacity_design_result_v2.dart';
import '../models/voltage_drop_continuation_context_v2.dart';
import '../models/voltage_drop_verification_result_v2.dart';

/// Independent V2 voltage-drop boundary; it is not used by the active engine.
class VoltageDropContinuationServiceV2 {
  VoltageDropContinuationServiceV2({
    VoltageDropRepository? repository,
    VoltageDropCalculationService? calculation,
  }) : _repository = repository ?? const VoltageDropRepository(),
       _calculation = calculation ?? const VoltageDropCalculationService();
  final VoltageDropRepository _repository;
  final VoltageDropCalculationService _calculation;

  Future<VoltageDropVerificationResultV2> verify({
    required AmpacityDesignResultV2 ampacity,
    VoltageDropContinuationContextV2? context,
  }) async {
    if (ampacity.status != AmpacityRoutingStatus.resolved ||
        ampacity.selected == null) {
      return const VoltageDropVerificationResultV2(
        status: VoltageDropVerificationStatusV2.notVerified,
        reason: 'Ampacity is not resolved.',
      );
    }
    if (context == null)
      return const VoltageDropVerificationResultV2(
        status: VoltageDropVerificationStatusV2.notVerified,
        reason: 'Voltage-drop context is not supplied.',
      );
    if (context.installationGroup == null ||
        context.insulation == null ||
        context.coreType == null ||
        context.phase == null ||
        context.systemVoltage == null ||
        context.lengthM == null ||
        context.allowableVoltageDropPercent == null) {
      return const VoltageDropVerificationResultV2(
        status: VoltageDropVerificationStatusV2.insufficient,
        reason: 'Voltage-drop context is incomplete.',
      );
    }
    final core = switch (context.coreType!) {
      CoreType.singleCore => VoltageDropCoreType.singleCore,
      CoreType.multiCore => VoltageDropCoreType.multiCore,
    };
    final selected = ampacity.selected!;
    final result = _calculation.calculate(
      request: VoltageDropRequest(
        insulation: context.insulation!,
        coreType: core,
        phase: context.phase!,
        sizeSqmm: selected.candidate.sizeSqmm,
        currentA: selected.currentPerRun,
        lengthM: context.lengthM!,
        systemVoltage: context.systemVoltage!,
        allowableVoltageDropPercent: context.allowableVoltageDropPercent!,
        installationGroup: context.installationGroup!,
        arrangement: context.arrangement,
      ),
      rows: await _repository.loadTable(
        insulation: context.insulation!,
        coreType: core,
      ),
    );
    if (!result.isSuccess)
      return VoltageDropVerificationResultV2(
        status: VoltageDropVerificationStatusV2.unsupported,
        reason: result.message,
      );
    return VoltageDropVerificationResultV2(
      status: result.isWithinLimit!
          ? VoltageDropVerificationStatusV2.verified
          : VoltageDropVerificationStatusV2.failed,
      reason: result.message,
      tableId: result.table,
      mvPerAperM: result.mvPerAperM,
      voltageDropV: result.voltageDropV,
      voltageDropPercent: result.voltageDropPercent,
      allowableVoltageDropPercent: context.allowableVoltageDropPercent,
      marginPercent:
          context.allowableVoltageDropPercent! - result.voltageDropPercent!,
      sourceReferences: [result.table!],
    );
  }
}
