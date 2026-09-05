import 'package:flutter_test/flutter_test.dart';
import 'package:mep_project/features/electrical/cable_design/enums/core_type.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_shape.dart';
import 'package:mep_project/features/electrical/cable_design/enums/conductor_temperature_class.dart';
import 'package:mep_project/features/electrical/cable_design/enums/phase_system.dart';
import 'package:mep_project/features/electrical/cable_design/enums/cable_design_routing_mode.dart';
import 'package:mep_project/features/electrical/cable_design/models/cable_routing_identity.dart';
import 'package:mep_project/features/electrical/cable_design/models/supplemental_cable_properties_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/cable_design_v2_input_mapping_status.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_environment.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/installation_support.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/enums/routing_electrical_system.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_execution_caller_input.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/models/cable_design_v2_input_state.dart';
import 'package:mep_project/features/electrical/cable_design/routing_v2/services/cable_design_v2_input_mapper.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_arrangement.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/cable_insulation.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_drop_installation_group.dart';
import 'package:mep_project/features/electrical/voltage_drop/enums/voltage_phase.dart';

void main() {
  const mapper = CableDesignV2InputMapper();
  CableDesignV2InputState state({
    CableRoutingIdentity? identity = CableRoutingIdentity.vaf,
    double? loadCurrent = 10,
    int? loadedConductors = 2,
    CoreType? coreType = CoreType.multiCore,
    Set<InstallationEnvironment>? environments = const {
      InstallationEnvironment.surfaceMountedWallOrCeiling,
    },
    Set<InstallationSupport>? supports = const {
      InstallationSupport.surfaceMount,
    },
    bool verifyVoltageDrop = false,
    VoltageDropContinuationContextValues? vd,
    SupplementalCablePropertiesInput? supplemental,
    RoutingElectricalSystem? routingElectricalSystem,
    bool? hasOuterSheath,
  }) => CableDesignV2InputState(
    loadCurrent: loadCurrent,
    phaseSystem: PhaseSystem.singlePhase,
    routingElectricalSystem: routingElectricalSystem,
    loadedConductors: loadedConductors,
    coreType: coreType,
    ambientTemperature: 40,
    identity: identity,
    environments: environments,
    supports: supports,
    hasOuterSheath: hasOuterSheath,
    verifyVoltageDrop: verifyVoltageDrop,
    voltageDropPhase: vd?.phase,
    voltageDropInsulation: vd?.insulation,
    voltageDropCoreType: vd?.coreType,
    voltageDropInstallationGroup: vd?.group,
    voltageDropArrangement: vd?.arrangement,
    circuitLengthM: vd?.lengthM,
    systemVoltage: vd?.systemVoltage,
    allowableVoltageDropPercent: vd?.allowable,
    supplementalCableProperties: supplemental,
  );

  test('VAF and VAF-G ampacity-only mapping is ready without VD facts', () {
    for (final identity in [
      CableRoutingIdentity.vaf,
      CableRoutingIdentity.vafG,
    ]) {
      final result = mapper.map(state(identity: identity));
      expect(result.status, CableDesignV2InputMappingStatus.ready);
      expect(result.ampacityRequest!.identity, identity);
      expect(result.voltageDropContext, isNull);
    }
  });

  test('maps explicit VD context independently from ampacity facts', () {
    final a = mapper.map(state());
    final b = mapper.map(
      state(
        verifyVoltageDrop: true,
        vd: const VoltageDropContinuationContextValues(),
      ),
    );
    expect(b.status, CableDesignV2InputMappingStatus.ready);
    expect(b.ampacityRequest!.identity, a.ampacityRequest!.identity);
    expect(b.ampacityRequest!.loadCurrent, a.ampacityRequest!.loadCurrent);
    expect(
      b.ampacityRequest!.ambientTemperature,
      a.ampacityRequest!.ambientTemperature,
    );
    expect(
      b.voltageDropContext!.installationGroup,
      VoltageDropInstallationGroup.group1,
    );
    expect(b.voltageDropContext!.insulation, CableInsulation.pvc);
  });

  test(
    'fails closed for missing required input and invalid numeric values',
    () {
      expect(
        mapper.map(state(identity: null)).status,
        CableDesignV2InputMappingStatus.insufficient,
      );
      expect(
        mapper.map(state(environments: null)).status,
        CableDesignV2InputMappingStatus.insufficient,
      );
      expect(
        mapper.map(state(supports: null)).status,
        CableDesignV2InputMappingStatus.insufficient,
      );
      expect(
        mapper.map(state(verifyVoltageDrop: true)).status,
        CableDesignV2InputMappingStatus.insufficient,
      );
      expect(
        mapper.map(state(loadCurrent: 0)).status,
        CableDesignV2InputMappingStatus.invalid,
      );
    },
  );

  test(
    'fails closed when single-core VD arrangement is required but absent',
    () {
      final result = mapper.map(
        CableDesignV2InputState(
          loadCurrent: 10,
          phaseSystem: PhaseSystem.singlePhase,
          loadedConductors: 2,
          coreType: CoreType.multiCore,
          ambientTemperature: 40,
          identity: CableRoutingIdentity.vaf,
          environments: const {
            InstallationEnvironment.surfaceMountedWallOrCeiling,
          },
          supports: const {InstallationSupport.surfaceMount},
          verifyVoltageDrop: true,
          voltageDropPhase: VoltagePhase.singlePhase,
          voltageDropInsulation: CableInsulation.pvc,
          voltageDropCoreType: CoreType.singleCore,
          voltageDropInstallationGroup: VoltageDropInstallationGroup.group3,
          circuitLengthM: 30,
          systemVoltage: 230,
          allowableVoltageDropPercent: 3,
        ),
      );
      expect(result.status, CableDesignV2InputMappingStatus.insufficient);
      expect(result.missingFields, contains('voltageDropArrangement'));
    },
  );

  test(
    'passes supplemental properties through without defaults and is caller compatible',
    () {
      const supplemental = SupplementalCablePropertiesInput(
        cableShape: CableShape.round,
      );
      final result = mapper.map(state(supplemental: supplemental));
      expect(
        result.ampacityRequest!.supplementalCableProperties,
        same(supplemental),
      );
      final caller = CableDesignExecutionCallerInput(
        routingMode: CableDesignRoutingMode.routingV2,
        routingV2CableRequest: result.ampacityRequest,
        routingV2VoltageDropContext: result.voltageDropContext,
      );
      expect(caller.routingV2CableRequest, same(result.ampacityRequest));
      expect(caller.routingMode, CableDesignRoutingMode.routingV2);
    },
  );

  test('IEC 10 requires only unresolved supplemental facts', () {
    final incomplete = mapper.map(
      state(identity: CableRoutingIdentity.iec10, coreType: null),
    );
    expect(incomplete.status, CableDesignV2InputMappingStatus.insufficient);
    expect(
      incomplete.missingFields,
      containsAll(<String>[
        'supplementalCableProperties.cableShape',
        'supplementalCableProperties.insulation',
        'supplementalCableProperties.conductorTemperatureClass',
      ]),
    );

    const supplemental = SupplementalCablePropertiesInput(
      cableShape: CableShape.round,
      insulation: CableInsulation.pvc,
      conductorTemperatureClass: ConductorTemperatureClass.pvc70,
    );
    final ready = mapper.map(
      state(
        identity: CableRoutingIdentity.iec10,
        coreType: null,
        supplemental: supplemental,
      ),
    );
    expect(ready.status, CableDesignV2InputMappingStatus.ready);
    expect(ready.ampacityRequest!.coreType, CoreType.multiCore);
    expect(
      ready.ampacityRequest!.supplementalCableProperties,
      same(supplemental),
    );
  });

  test('IEC 10 accepts only the approved C6 and C7 loaded-conductor facts', () {
    const supplemental = SupplementalCablePropertiesInput(
      cableShape: CableShape.round,
      insulation: CableInsulation.pvc,
      conductorTemperatureClass: ConductorTemperatureClass.pvc70,
    );
    for (final loaded in [2, 3]) {
      final result = mapper.map(
        state(
          identity: CableRoutingIdentity.iec10,
          loadedConductors: loaded,
          supplemental: supplemental,
        ),
      );
      expect(result.status, CableDesignV2InputMappingStatus.ready);
      expect(result.ampacityRequest!.loadedConductors, loaded);
      expect(result.ampacityRequest!.phaseSystem, PhaseSystem.singlePhase);
      expect(result.voltageDropContext, isNull);
    }
    expect(
      mapper
          .map(
            state(
              identity: CableRoutingIdentity.iec10,
              loadedConductors: 4,
              supplemental: supplemental,
            ),
          )
          .status,
      CableDesignV2InputMappingStatus.invalid,
    );
  });

  test(
    'NYY maps only explicit single-core C2/C3 facts without VD inference',
    () {
      const supplemental = SupplementalCablePropertiesInput(
        cableShape: CableShape.round,
        insulation: CableInsulation.pvc,
        conductorTemperatureClass: ConductorTemperatureClass.pvc70,
      );
      for (final loaded in [2, 3]) {
        final result = mapper.map(
          state(
            identity: CableRoutingIdentity.nyy,
            coreType: CoreType.singleCore,
            loadedConductors: loaded,
            supplemental: supplemental,
          ),
        );
        expect(result.status, CableDesignV2InputMappingStatus.ready);
        expect(result.ampacityRequest!.loadedConductors, loaded);
        expect(result.ampacityRequest!.phaseSystem, PhaseSystem.singlePhase);
        expect(result.voltageDropContext, isNull);
      }
    },
  );

  test(
    'NYY requires supplemental facts and rejects unsupported loaded count',
    () {
      for (final supplemental in <SupplementalCablePropertiesInput>[
        const SupplementalCablePropertiesInput(
          insulation: CableInsulation.pvc,
          conductorTemperatureClass: ConductorTemperatureClass.pvc70,
        ),
        const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          conductorTemperatureClass: ConductorTemperatureClass.pvc70,
        ),
        const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          insulation: CableInsulation.pvc,
        ),
      ]) {
        expect(
          mapper
              .map(
                state(
                  identity: CableRoutingIdentity.nyy,
                  coreType: CoreType.singleCore,
                  supplemental: supplemental,
                ),
              )
              .status,
          CableDesignV2InputMappingStatus.insufficient,
        );
      }
      final unsupported = mapper.map(
        state(
          identity: CableRoutingIdentity.nyy,
          coreType: CoreType.singleCore,
          loadedConductors: 4,
          supplemental: const SupplementalCablePropertiesInput(
            cableShape: CableShape.round,
            insulation: CableInsulation.pvc,
            conductorTemperatureClass: ConductorTemperatureClass.pvc70,
          ),
        ),
      );
      expect(unsupported.status, CableDesignV2InputMappingStatus.invalid);
    },
  );

  test('IEC 60502-1 maps explicit C4/C5 construction without VD inference', () {
    const supplemental = SupplementalCablePropertiesInput(
      cableShape: CableShape.round,
      insulation: CableInsulation.xlpe,
      conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
    );
    for (final loaded in [2, 3]) {
      final result = mapper.map(
        state(
          identity: CableRoutingIdentity.iec605021,
          coreType: CoreType.singleCore,
          loadedConductors: loaded,
          routingElectricalSystem: RoutingElectricalSystem.singlePhaseAc,
          hasOuterSheath: true,
          supplemental: supplemental,
        ),
      );
      expect(result.status, CableDesignV2InputMappingStatus.ready);
      expect(
        result.ampacityRequest!.routingElectricalSystem,
        RoutingElectricalSystem.singlePhaseAc,
      );
      expect(
        result.ampacityRequest!.engineeringInstallation!.hasOuterSheath,
        true,
      );
      expect(result.voltageDropContext, isNull);
    }
  });

  test('IEC 60502-1 requires every explicit construction fact', () {
    const complete = SupplementalCablePropertiesInput(
      cableShape: CableShape.round,
      insulation: CableInsulation.xlpe,
      conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
    );
    final missing = [
      state(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        hasOuterSheath: true,
        supplemental: complete,
      ),
      state(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        routingElectricalSystem: RoutingElectricalSystem.singlePhaseAc,
        supplemental: complete,
      ),
      state(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        routingElectricalSystem: RoutingElectricalSystem.singlePhaseAc,
        hasOuterSheath: true,
        supplemental: const SupplementalCablePropertiesInput(
          insulation: CableInsulation.xlpe,
          conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
        ),
      ),
    ];
    for (final input in missing) {
      expect(
        mapper.map(input).status,
        CableDesignV2InputMappingStatus.insufficient,
      );
    }
  });

  test('IEC 60502-1 rejects C8/C9, PVC, and unsheathed variants', () {
    const complete = SupplementalCablePropertiesInput(
      cableShape: CableShape.round,
      insulation: CableInsulation.xlpe,
      conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
    );
    for (final input in [
      state(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.multiCore,
        routingElectricalSystem: RoutingElectricalSystem.singlePhaseAc,
        hasOuterSheath: true,
        supplemental: complete,
      ),
      state(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        routingElectricalSystem: RoutingElectricalSystem.singlePhaseAc,
        hasOuterSheath: false,
        supplemental: complete,
      ),
      state(
        identity: CableRoutingIdentity.iec605021,
        coreType: CoreType.singleCore,
        routingElectricalSystem: RoutingElectricalSystem.singlePhaseAc,
        hasOuterSheath: true,
        supplemental: const SupplementalCablePropertiesInput(
          cableShape: CableShape.round,
          insulation: CableInsulation.pvc,
          conductorTemperatureClass: ConductorTemperatureClass.xlpeEpr90,
        ),
      ),
    ]) {
      expect(mapper.map(input).status, CableDesignV2InputMappingStatus.invalid);
    }
  });
}

class VoltageDropContinuationContextValues {
  const VoltageDropContinuationContextValues({
    this.phase = VoltagePhase.singlePhase,
    this.insulation = CableInsulation.pvc,
    this.coreType = CoreType.multiCore,
    this.group = VoltageDropInstallationGroup.group1,
    this.arrangement,
    this.lengthM = 30,
    this.systemVoltage = 230,
    this.allowable = 3,
  });
  final VoltagePhase phase;
  final CableInsulation insulation;
  final CoreType coreType;
  final VoltageDropInstallationGroup group;
  final CableArrangement? arrangement;
  final double lengthM;
  final double systemVoltage;
  final double allowable;
}
