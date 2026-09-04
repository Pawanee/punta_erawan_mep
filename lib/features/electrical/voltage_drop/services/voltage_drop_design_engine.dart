import 'package:flutter/foundation.dart';

import '../models/voltage_drop_cable_selection_request.dart';
import '../models/voltage_drop_design_result.dart';
import 'voltage_drop_cable_design_engine.dart';
import 'voltage_drop_result_integration_service.dart';

/// ============================================================================
/// VOLTAGE DROP DESIGN ENGINE
///
/// PART 8 - Main Engine Integration
///
/// หน้าที่ของ Engine ชั้นนี้คือ orchestration เท่านั้น:
///
/// Input Request
///   -> PART 3/6 Cable Design Engine
///   -> PART 7 Result Integration
///   -> Final VoltageDropDesignResult
///
/// ไม่มีการสร้างสูตร Voltage Drop ใหม่ และไม่มีการเลือกสายซ้ำ
/// ============================================================================
class VoltageDropDesignEngine {
  VoltageDropDesignEngine({
    VoltageDropCableDesignEngine? cableDesignEngine,
    VoltageDropResultIntegrationService? resultIntegrationService,
  }) : cableDesignEngine = cableDesignEngine ?? VoltageDropCableDesignEngine(),
       resultIntegrationService =
           resultIntegrationService ??
           const VoltageDropResultIntegrationService();

  final VoltageDropCableDesignEngine cableDesignEngine;
  final VoltageDropResultIntegrationService resultIntegrationService;

  /// ออกแบบสายแบบครบกระบวนการ และคืนผลชุดเดียวสำหรับ UI
  Future<VoltageDropDesignResult> design(
    VoltageDropCableSelectionRequest request,
  ) async {
    try {
      if (request.cableRequest.loadCurrent <= 0) {
        return VoltageDropDesignResult.error('Load Current ต้องมากกว่า 0 A');
      }

      if (request.voltageDropEnabled && request.lengthM <= 0) {
        return VoltageDropDesignResult.error('Length ต้องมากกว่า 0 m');
      }

      final selectionResult = await cableDesignEngine.design(request);

      return resultIntegrationService.integrate(
        selectionResult: selectionResult,
        loadCurrent: request.cableRequest.loadCurrent,
        cableLengthM: request.lengthM,
      );
    } catch (e) {
      debugPrint('Voltage Drop Design Engine error: $e');
      return VoltageDropDesignResult.error(
        'ไม่สามารถคำนวณได้ กรุณาตรวจสอบข้อมูลที่ป้อน',
      );
    }
  }
}
