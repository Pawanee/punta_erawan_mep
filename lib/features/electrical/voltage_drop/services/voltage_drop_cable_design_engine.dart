import '../../cable_design/models/cable_table_row.dart';
import '../../cable_design/repositories/table_5_20_repository.dart';
import '../models/voltage_drop_cable_selection_request.dart';
import '../models/voltage_drop_cable_selection_result.dart';
import 'voltage_drop_cable_selection_service.dart';

/// ============================================================================
/// VOLTAGE DROP CABLE DESIGN ENGINE
///
/// PART 3
///
/// เชื่อม Table 5-20 เข้ากับ Voltage Drop Selection Service
///
/// Engine ทำหน้าที่ orchestration เท่านั้น
/// Logic การเลือกสายอยู่ใน VoltageDropCableSelectionService
/// ============================================================================
class VoltageDropCableDesignEngine {
  VoltageDropCableDesignEngine({
    Table520Repository? cableRepository,
    VoltageDropCableSelectionService? selectionService,
  })  : _cableRepository = cableRepository ?? Table520Repository(),
        _selectionService =
            selectionService ?? VoltageDropCableSelectionService();

  final Table520Repository _cableRepository;
  final VoltageDropCableSelectionService _selectionService;

  Future<VoltageDropCableSelectionResult> design(
    VoltageDropCableSelectionRequest request,
  ) async {
    try {
      final List<CableTableRow> rows =
          await _cableRepository.loadTable(
        cableType: request.cableRequest.cableType,
      );

      if (rows.isEmpty) {
        return VoltageDropCableSelectionResult.error(
          'Table 5-20 ไม่มีข้อมูล',
        );
      }

      return _selectionService.select(
        request: request,
        candidates: rows,
      );
    } catch (e) {
      return VoltageDropCableSelectionResult.error(
        e.toString(),
      );
    }
  }
}
