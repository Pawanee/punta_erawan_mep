import '../../enums/cable_design_routing_mode.dart';
import '../../enums/core_type.dart';
import '../../enums/cable_shape.dart';
import '../../enums/conductor_temperature_class.dart';
import '../../models/engineering_installation_input.dart';
import '../../models/cable_routing_identity.dart';
import '../enums/cable_design_v2_input_mapping_status.dart';
import '../../../voltage_drop/enums/cable_insulation.dart';
import '../models/cable_design_request_v2.dart';
import '../models/cable_design_v2_input_mapping_result.dart';
import '../models/cable_design_v2_input_state.dart';
import '../models/voltage_drop_continuation_context_v2.dart';

/// UI/domain mapper only; it makes no routing, table, correction, or VD decisions.
class CableDesignV2InputMapper {
  const CableDesignV2InputMapper();

  CableDesignV2InputMappingResult map(CableDesignV2InputState state) {
    final missing = <String>[];
    if (state.loadCurrent == null) missing.add('loadCurrent');
    if (state.phaseSystem == null) missing.add('phaseSystem');
    if (state.loadedConductors == null) missing.add('loadedConductors');
    // IEC 10's multi-core construction is profile-sourced by Table 5-48.
    if (state.identity != CableRoutingIdentity.iec10 &&
        state.coreType == null) {
      missing.add('coreType');
    }
    if (state.ambientTemperature == null) missing.add('ambientTemperature');
    if (state.identity == null) missing.add('identity');
    if (state.environments == null || state.environments!.isEmpty) {
      missing.add('environments');
    }
    if (state.supports == null || state.supports!.isEmpty) {
      missing.add('supports');
    }
    if (missing.isNotEmpty) return _insufficient(missing);
    if (state.loadCurrent! <= 0 || state.loadedConductors! <= 0) {
      return const CableDesignV2InputMappingResult(
        status: CableDesignV2InputMappingStatus.invalid,
        reason: 'Load current and loaded conductors must be greater than zero.',
      );
    }
    if (state.identity == CableRoutingIdentity.iec10) {
      if (state.loadedConductors != 2 && state.loadedConductors != 3) {
        return const CableDesignV2InputMappingResult(
          status: CableDesignV2InputMappingStatus.invalid,
          reason: '60227 IEC 10 supports only two or three loaded conductors.',
        );
      }
      final supplemental = state.supplementalCableProperties;
      final missingSupplemental = <String>[];
      if (supplemental?.cableShape == null) {
        missingSupplemental.add('supplementalCableProperties.cableShape');
      }
      if (supplemental?.insulation == null) {
        missingSupplemental.add('supplementalCableProperties.insulation');
      }
      if (supplemental?.conductorTemperatureClass == null) {
        missingSupplemental.add(
          'supplementalCableProperties.conductorTemperatureClass',
        );
      }
      if (missingSupplemental.isNotEmpty) {
        return _insufficient(missingSupplemental);
      }
    }
    if (state.identity == CableRoutingIdentity.nyy) {
      if (state.loadedConductors != 2 && state.loadedConductors != 3) {
        return const CableDesignV2InputMappingResult(
          status: CableDesignV2InputMappingStatus.invalid,
          reason: 'NYY Group 3 supports only two or three loaded conductors.',
        );
      }
      final supplemental = state.supplementalCableProperties;
      final missingSupplemental = <String>[];
      if (supplemental?.cableShape == null) {
        missingSupplemental.add('supplementalCableProperties.cableShape');
      }
      if (supplemental?.insulation == null) {
        missingSupplemental.add('supplementalCableProperties.insulation');
      }
      if (supplemental?.conductorTemperatureClass == null) {
        missingSupplemental.add(
          'supplementalCableProperties.conductorTemperatureClass',
        );
      }
      if (missingSupplemental.isNotEmpty) {
        return _insufficient(missingSupplemental);
      }
    }
    if (state.identity == CableRoutingIdentity.iec605021) {
      final supplemental = state.supplementalCableProperties;
      final missingIec = <String>[];
      if (state.routingElectricalSystem == null) {
        missingIec.add('routingElectricalSystem');
      }
      if (state.hasOuterSheath == null) {
        missingIec.add('hasOuterSheath');
      }
      if (supplemental?.cableShape == null) {
        missingIec.add('supplementalCableProperties.cableShape');
      }
      if (supplemental?.insulation == null) {
        missingIec.add('supplementalCableProperties.insulation');
      }
      if (supplemental?.conductorTemperatureClass == null) {
        missingIec.add('supplementalCableProperties.conductorTemperatureClass');
      }
      if (missingIec.isNotEmpty) return _insufficient(missingIec);
      if (state.coreType != CoreType.singleCore ||
          state.loadedConductors != 2 && state.loadedConductors != 3 ||
          supplemental!.cableShape != CableShape.round ||
          supplemental.insulation != CableInsulation.xlpe ||
          supplemental.conductorTemperatureClass !=
              ConductorTemperatureClass.xlpeEpr90 ||
          state.hasOuterSheath != true) {
        return const CableDesignV2InputMappingResult(
          status: CableDesignV2InputMappingStatus.invalid,
          reason:
              'IEC 60502-1 is limited to the approved single-core XLPE C4/C5 construction.',
        );
      }
    }
    final request = CableDesignRequestV2(
      loadCurrent: state.loadCurrent!,
      phaseSystem: state.phaseSystem!,
      routingElectricalSystem: state.routingElectricalSystem,
      loadedConductors: state.loadedConductors!,
      coreType: state.identity == CableRoutingIdentity.iec10
          ? CoreType.multiCore
          : state.coreType!,
      ambientTemperature: state.ambientTemperature!,
      routingMode: CableDesignRoutingMode.routingV2,
      identity: state.identity,
      engineeringInstallation: EngineeringInstallationInput(
        environments: state.environments,
        supports: state.supports,
        hasOuterSheath: state.hasOuterSheath,
        spacingAtLeastCableDiameter: state.spacingAtLeastCableDiameter,
        ventilationOpeningPercent: state.ventilationOpeningPercent,
      ),
      supplementalCableProperties: state.supplementalCableProperties,
    );
    if (!state.verifyVoltageDrop) {
      return CableDesignV2InputMappingResult(
        status: CableDesignV2InputMappingStatus.ready,
        ampacityRequest: request,
      );
    }
    final vdMissing = <String>[];
    if (state.voltageDropPhase == null) vdMissing.add('voltageDropPhase');
    if (state.voltageDropInsulation == null) {
      vdMissing.add('voltageDropInsulation');
    }
    if (state.voltageDropCoreType == null) vdMissing.add('voltageDropCoreType');
    final group = state.voltageDropInstallationGroup;
    if (group == null) vdMissing.add('voltageDropInstallationGroup');
    if (state.circuitLengthM == null) vdMissing.add('circuitLengthM');
    if (state.systemVoltage == null) vdMissing.add('systemVoltage');
    if (state.allowableVoltageDropPercent == null) {
      vdMissing.add('allowableVoltageDropPercent');
    }
    if (group != null &&
        state.voltageDropCoreType == CoreType.singleCore &&
        !group.isGroup1_2_5 &&
        state.voltageDropArrangement == null) {
      vdMissing.add('voltageDropArrangement');
    }
    if (vdMissing.isNotEmpty) return _insufficient(vdMissing);
    if (state.circuitLengthM! <= 0 ||
        state.systemVoltage! <= 0 ||
        state.allowableVoltageDropPercent! <= 0) {
      return const CableDesignV2InputMappingResult(
        status: CableDesignV2InputMappingStatus.invalid,
        reason: 'Voltage-drop numeric inputs must be greater than zero.',
      );
    }
    return CableDesignV2InputMappingResult(
      status: CableDesignV2InputMappingStatus.ready,
      ampacityRequest: request,
      voltageDropContext: VoltageDropContinuationContextV2(
        phase: state.voltageDropPhase,
        insulation: state.voltageDropInsulation,
        coreType: state.voltageDropCoreType,
        installationGroup: group,
        arrangement: state.voltageDropArrangement,
        lengthM: state.circuitLengthM,
        systemVoltage: state.systemVoltage,
        allowableVoltageDropPercent: state.allowableVoltageDropPercent,
      ),
    );
  }

  CableDesignV2InputMappingResult _insufficient(List<String> fields) =>
      CableDesignV2InputMappingResult(
        status: CableDesignV2InputMappingStatus.insufficient,
        missingFields: List.unmodifiable(fields),
        reason: 'Explicit V2 input is incomplete.',
      );
}
