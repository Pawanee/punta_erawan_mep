 import '../models/voltage_drop_cable_selection_result.dart';
import '../models/voltage_drop_design_result.dart';

/// ============================================================================
/// VOLTAGE DROP RESULT INTEGRATION SERVICE
///
/// PART 7 / PART 9.4
///
/// รวมผลจาก Auto Cable Selection ให้เป็น Final Design Result
///
/// Reference แยกเป็น:
/// - Ampacity Reference      -> Table 5-20
/// - Voltage Drop Reference  -> Table 9.1 - 9.4
/// ============================================================================

class VoltageDropResultIntegrationService {
  const VoltageDropResultIntegrationService();

  VoltageDropDesignResult integrate({
    required VoltageDropCableSelectionResult selectionResult,
    required double loadCurrent,
    required double cableLengthM,
  }) {
    if (!selectionResult.isSuccess) {
      return VoltageDropDesignResult.error(
        selectionResult.message,
      );
    }

    final runs = selectionResult.runs;
    final ampacityPerRun = selectionResult.ampacity;
    final requiredCurrent = selectionResult.requiredCurrent;
    final groupingFactor = selectionResult.groupingFactor;
    final temperatureFactor = selectionResult.temperatureFactor;
    final baseAmpacityPerRun = selectionResult.baseAmpacityPerRun;
    final correctedAmpacityPerRun = selectionResult.correctedAmpacityPerRun;
    final cableSize = selectionResult.cableSizeSqmm;
    final voltageDropV = selectionResult.voltageDropV;
    final voltageDropPercent = selectionResult.voltageDropPercent;
    final mvPerAperM = selectionResult.mvPerAperM;
    final arrangement = selectionResult.cableArrangement;

    final ampacityReference =
    selectionResult.ampacityReference ??
    selectionResult.reference;

final voltageDropReference =
    selectionResult.voltageDropReference ??
    selectionResult.reference;

    if (runs == null || runs <= 0) {
      return VoltageDropDesignResult.error(
        'ไม่พบจำนวน Parallel Run ที่ถูกต้อง',
      );
    }

    if (ampacityPerRun == null || ampacityPerRun <= 0) {
      return VoltageDropDesignResult.error(
        'ไม่พบค่า Ampacity ที่ถูกต้อง',
      );
    }

    if (requiredCurrent == null || requiredCurrent <= 0) {
      return VoltageDropDesignResult.error(
        'ไม่พบ Required Current ที่ถูกต้อง',
      );
    }

    if (groupingFactor == null || groupingFactor <= 0) {
      return VoltageDropDesignResult.error(
        'ไม่พบ Grouping Factor ที่ถูกต้อง',
      );
    }

    if (loadCurrent <= 0 || cableLengthM <= 0) {
      return VoltageDropDesignResult.error(
        'Load Current และ Cable Length ต้องมากกว่า 0',
      );
    }

    if (cableSize == null ||
        voltageDropV == null ||
        voltageDropPercent == null ||
        mvPerAperM == null ||
        arrangement == null) {
      return VoltageDropDesignResult.error(
        'ผลการเลือกสายมีข้อมูลไม่ครบ',
      );
    }

    if (ampacityReference == null ||
        ampacityReference.isEmpty) {
      return VoltageDropDesignResult.error(
        'ไม่พบ Ampacity Reference',
      );
    }

    if (voltageDropReference == null ||
        voltageDropReference.isEmpty) {
      return VoltageDropDesignResult.error(
        'ไม่พบ Voltage Drop Reference',
      );
    }

    // Actual current flowing in each parallel run.
    // Required Current remains separate and is used for ampacity design.
    final currentPerRun =
        loadCurrent / runs;

    final totalAmpacity =
        ampacityPerRun * runs;

    return VoltageDropDesignResult.success(
      loadCurrent: loadCurrent,
      groupingFactor: groupingFactor,
      temperatureFactor: temperatureFactor,
      baseAmpacityPerRun: baseAmpacityPerRun,
      correctedAmpacityPerRun: correctedAmpacityPerRun,
      cableType: selectionResult.cableType,
      conductorTemperatureClass: selectionResult.conductorTemperatureClass,
      ambientTemperatureC: selectionResult.ambientTemperatureC,
      groupingCircuits: selectionResult.groupingCircuits,
      groupingReference: selectionResult.groupingReference,
      temperatureReference: selectionResult.temperatureReference,
      requiredCurrent: requiredCurrent,
      runs: runs,
      currentPerRun: currentPerRun,
      cableSizeSqmm: cableSize,
      ampacityPerRun: ampacityPerRun,
      totalAmpacity: totalAmpacity,
      cableArrangement: arrangement,
      cableLengthM: cableLengthM,
      voltageDropV: voltageDropV,
      voltageDropPercent: voltageDropPercent,
      mvPerAperM: mvPerAperM,

      ampacityReference: ampacityReference,
      voltageDropReference: voltageDropReference,

      // Legacy compatibility
      reference: ampacityReference,
    );
  }
}
