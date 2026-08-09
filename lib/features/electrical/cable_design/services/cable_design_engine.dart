 import '../models/cable_design_request.dart';
import '../models/cable_design_result.dart';
import '../models/cable_table_row.dart';
import '../repositories/table_5_20_repository.dart';
import '../services/cable_selection_service.dart';
import 'grouping_factor_service.dart';
import '../enums/installation_method.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module  : Electrical
/// Feature : Cable Design
/// File    : cable_design_engine.dart
///
/// Cable Design Engine
///
/// หน้าที่
/// 1. Load Grouping Factor จาก Table 5-8
/// 2. คำนวณ Required Current
/// 3. Load Table 5-20
/// 4. เรียก CableSelectionService
/// 5. คำนวณ Parallel Runs
/// 6. คำนวณ Total Ampacity
/// 7. คำนวณ Derated Ampacity
/// 8. คืน CableDesignResult
///
/// Engine ไม่ทำ Logic เลือกขนาดสายโดยตรง
/// Logic การเลือกสายอยู่ใน CableSelectionService
///
/// ============================================================================

class CableDesignEngine {
  CableDesignEngine({
    Table520Repository? repository,
    CableSelectionService? selectionService,
    GroupingFactorService? groupService,
  })  : _repository = repository ?? Table520Repository(),
        _selectionService =
            selectionService ?? const CableSelectionService(),
        _groupService = groupService ?? GroupingFactorService();

  final Table520Repository _repository;

  final CableSelectionService _selectionService;

  final GroupingFactorService _groupService;

  // ==========================================================================
  // DESIGN CABLE
  // ==========================================================================

  Future<CableDesignResult> design(
    CableDesignRequest request,
  ) async {
    try {
      // ----------------------------------------------------------------------
      // Validate Request
      // ----------------------------------------------------------------------

      if (!validate(request)) {
        return CableDesignResult.error(
          'Load Current ต้องมากกว่า 0 A',
          loadCurrent: request.loadCurrent,
          groupingCircuits: request.groupingCircuits,
        );
      }

      // ----------------------------------------------------------------------
      // Load Grouping Factor
      // ----------------------------------------------------------------------
      //
      // Group 1 = Enclosed
      // Group 2 = Surface
      //
      // ----------------------------------------------------------------------

      final groupingFactor = await _groupService.getFactor(
        circuits: request.groupingCircuits,
        enclosed:
            request.installationMethod == InstallationMethod.group1,
      );

      // ----------------------------------------------------------------------
      // ตรวจสอบ Grouping Factor
      // ----------------------------------------------------------------------

      if (groupingFactor <= 0) {
        return CableDesignResult.error(
          'Grouping Factor ไม่ถูกต้อง',
          loadCurrent: request.loadCurrent,
          groupingCircuits: request.groupingCircuits,
          groupingFactor: groupingFactor,
        );
      }

      // ----------------------------------------------------------------------
      // Calculate Required Current
      // ----------------------------------------------------------------------
      //
      // Required Current = Load Current / Grouping Factor
      //
      // ตัวอย่าง:
      //
      // Load = 100 A
      // Factor = 0.50
      //
      // Required = 100 / 0.50
      //          = 200 A
      //
      // ----------------------------------------------------------------------

      final requiredCurrent =
          request.loadCurrent / groupingFactor;

      // ----------------------------------------------------------------------
      // Load Table 5-20
      // ----------------------------------------------------------------------

      final List<CableTableRow> rows =
          await _repository.loadTable(
        cableType: request.cableType,
      );

      // ----------------------------------------------------------------------
      // ไม่มีข้อมูล Table
      // ----------------------------------------------------------------------

      if (rows.isEmpty) {
        return CableDesignResult.error(
          'Table 5-20 ไม่มีข้อมูล',
          loadCurrent: request.loadCurrent,
          groupingCircuits: request.groupingCircuits,
          groupingFactor: groupingFactor,
          requiredCurrent: requiredCurrent,
        );
      }

      // ----------------------------------------------------------------------
      // Select Cable
      // ----------------------------------------------------------------------
      //
      // SelectionService รับ Required Current
      // ผ่าน effectiveCurrent
      //
      // Factor จะไม่ถูกคำนวณซ้ำ
      //
      // ----------------------------------------------------------------------

      final CableTableRow? cable =
          _selectionService.select(
        request: request,
        rows: rows,
        effectiveCurrent: requiredCurrent,
      );

      // ----------------------------------------------------------------------
      // ไม่พบสายที่เหมาะสม
      // ----------------------------------------------------------------------

      if (cable == null) {
        return CableDesignResult.error(
          'ไม่พบขนาดสายที่เหมาะสม',
          loadCurrent: request.loadCurrent,
          groupingCircuits: request.groupingCircuits,
          groupingFactor: groupingFactor,
          requiredCurrent: requiredCurrent,
        );
      }

      // ----------------------------------------------------------------------
      // Calculate Parallel Runs
      // ----------------------------------------------------------------------
      //
      // หาจำนวนสายขนานจาก Required Current
      // เทียบกับ Ampacity ของสาย 1 Run
      //
      // ตัวอย่าง:
      //
      // Required Current = 250 A
      // Cable Ampacity  = 143 A
      //
      // 250 / 143 = 1.748
      //
      // Parallel Runs = 2
      //
      // ----------------------------------------------------------------------

      final int parallelRuns =
          (requiredCurrent / cable.ampacity).ceil();

      // ----------------------------------------------------------------------
      // Safety Check
      // ----------------------------------------------------------------------

      if (parallelRuns < 1) {
        return CableDesignResult.error(
          'จำนวน Parallel Run ไม่ถูกต้อง',
          loadCurrent: request.loadCurrent,
          groupingCircuits: request.groupingCircuits,
          groupingFactor: groupingFactor,
          requiredCurrent: requiredCurrent,
        );
      }

      // ----------------------------------------------------------------------
      // Total Ampacity
      // ----------------------------------------------------------------------
      //
      // ความสามารถรวมของสายทุก Parallel Run
      //
      // Total Ampacity =
      // Ampacity ต่อ Run × จำนวน Run
      //
      // ----------------------------------------------------------------------

      final totalAmpacity =
          cable.ampacity * parallelRuns;

      // ----------------------------------------------------------------------
      // Derated Ampacity
      // ----------------------------------------------------------------------
      //
      // ความสามารถรวมหลังคิด Grouping Factor
      //
      // Derated Ampacity =
      // Total Ampacity × Grouping Factor
      //
      // ----------------------------------------------------------------------

      final deratedAmpacity =
          totalAmpacity * groupingFactor;

      // ----------------------------------------------------------------------
      // Success
      // ----------------------------------------------------------------------

      return CableDesignResult.success(
        loadCurrent: request.loadCurrent,
        groupingCircuits: request.groupingCircuits,
        groupingFactor: groupingFactor,
        requiredCurrent: requiredCurrent,

        cableSizeSqmm: cable.cableSizeSqmm,
        ampacity: cable.ampacity,
        parallelRuns: parallelRuns,
        totalAmpacity: totalAmpacity,
        deratedAmpacity: deratedAmpacity,

        cableArrangement: cable.remark,
        reference: cable.reference,
      );
    } catch (e) {
      // --------------------------------------------------------------------
      // Error
      // --------------------------------------------------------------------

      return CableDesignResult.error(
        e.toString(),
        loadCurrent: request.loadCurrent,
        groupingCircuits: request.groupingCircuits,
      );
    }
  }

  // ==========================================================================
  // HAS CANDIDATE
  // ==========================================================================

  Future<bool> hasCandidate(
    CableDesignRequest request,
  ) async {
    final List<CableTableRow> rows =
        await _repository.loadTable(
      cableType: request.cableType,
    );

    return _selectionService.hasCandidate(
      request: request,
      rows: rows,
    );
  }

  // ==========================================================================
  // MAX AMPACITY
  // ==========================================================================

  Future<double> maxAmpacity(
    CableDesignRequest request,
  ) async {
    final List<CableTableRow> rows =
        await _repository.loadTable(
      cableType: request.cableType,
    );

    return _selectionService.maxAmpacity(
      request: request,
      rows: rows,
    );
  }

  // ==========================================================================
  // CANDIDATES
  // ==========================================================================

  Future<List<CableTableRow>> candidates(
    CableDesignRequest request,
  ) async {
    final List<CableTableRow> rows =
        await _repository.loadTable(
      cableType: request.cableType,
    );

    return _selectionService.filter(
      request: request,
      rows: rows,
    );
  }

  // ==========================================================================
  // VALIDATE
  // ==========================================================================

  bool validate(
    CableDesignRequest request,
  ) {
    return request.loadCurrent > 0;
  }
}