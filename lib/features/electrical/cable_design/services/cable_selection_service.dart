 import '../models/cable_design_request.dart';
import '../models/cable_table_row.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module  : Electrical
/// Feature : Cable Design
/// File    : cable_selection_service.dart
///
/// Cable Selection Service
///
/// หน้าที่:
/// เลือกขนาดสายไฟจากข้อมูล Table 5-20
///
/// หลักการ:
/// 1. รับ Effective Current จาก CableDesignEngine
/// 2. ไม่คำนวณ Grouping Factor ซ้ำ
/// 3. พยายามเลือกสาย 1 Run ก่อน
/// 4. ถ้า 1 Run ไม่พอ ให้เพิ่ม Parallel Run
/// 5. ในแต่ละจำนวน Run เลือกสายขนาดเล็กที่สุดที่ผ่าน
/// 6. สายเดี่ยวสูงสุดที่อนุญาต = 240 sq.mm
///
/// ตัวอย่าง:
///
/// Load Current      = 250 A
/// Grouping Factor   = 1.00
/// Effective Current = 250 A
///
/// Table 5-20:
/// 95 sq.mm = 143 A
/// 120 sq.mm = ...
/// 185 sq.mm = 213 A
/// 240 sq.mm = 249 A
///
/// 1 × 240 = 249 A  -> ไม่พอ
///
/// 2 × 95 = 286 A   -> ผ่าน
///
/// ผลลัพธ์:
/// 2 × 95 sq.mm
///
/// ============================================================================

class CableSelectionService {
  const CableSelectionService();

  /// ขนาดสายเดี่ยวสูงสุดที่อนุญาต
  static const double _maxSingleCableSize = 240.0;

  /// จำนวน Parallel สูงสุด
  static const int _maxParallelRuns = 20;

  // ==========================================================================
  // SELECT CABLE
  // ==========================================================================

  CableTableRow? select({
    required CableDesignRequest request,
    required List<CableTableRow> rows,
    double? effectiveCurrent,
  }) {
    // ------------------------------------------------------------------------
    // Effective Current
    // ------------------------------------------------------------------------
    //
    // ถ้า Engine ส่ง effectiveCurrent มา
    // ให้ใช้ค่าที่ Engine คำนวณแล้ว
    //
    // ถ้าไม่ได้ส่งมา ให้ใช้ Load Current
    //
    // ห้ามคูณ / หาร Grouping Factor ที่นี่อีก
    // ------------------------------------------------------------------------

    final requiredCurrent =
        effectiveCurrent ?? request.loadCurrent;

    // ------------------------------------------------------------------------
    // Validate Current
    // ------------------------------------------------------------------------

    if (requiredCurrent <= 0) {
      return null;
    }

    // ------------------------------------------------------------------------
    // Filter Table 5-20
    // ------------------------------------------------------------------------

    final candidates = rows.where((row) {
      return row.cableType == request.cableType &&
          row.installationMethod == request.installationMethod &&
          row.loadedConductors == request.loadedConductors &&
          row.coreType == request.coreType &&
          row.cableSizeSqmm <= _maxSingleCableSize;
    }).toList();

    // ------------------------------------------------------------------------
    // ไม่มีข้อมูล
    // ------------------------------------------------------------------------

    if (candidates.isEmpty) {
      return null;
    }

    // ------------------------------------------------------------------------
    // เรียงสายจากเล็ก → ใหญ่
    // ------------------------------------------------------------------------

    candidates.sort(
      (a, b) => a.cableSizeSqmm.compareTo(b.cableSizeSqmm),
    );

    // =========================================================================
    // PARALLEL CABLE SELECTION
    // =========================================================================
    //
    // หลักการ:
    //
    // Run 1:
    //   หาสายเส้นเล็กที่สุดที่รับ Required Current ได้
    //
    // ถ้าไม่มี:
    //
    // Run 2:
    //   หาสายเส้นเล็กที่สุดที่
    //
    //   ampacity × 2 >= Required Current
    //
    // ถ้าไม่มี:
    //
    // Run 3:
    //   หาสายเส้นเล็กที่สุดที่
    //
    //   ampacity × 3 >= Required Current
    //
    // ทำแบบนี้จนถึง 20 Runs
    //
    // =========================================================================

    for (int runs = 1; runs <= _maxParallelRuns; runs++) {
      for (final cable in candidates) {
        // --------------------------------------------------------------------
        // Ampacity รวมของ Parallel
        // --------------------------------------------------------------------

        final totalAmpacity =
            cable.ampacity * runs;

        // --------------------------------------------------------------------
        // ถ้า Ampacity รวมไม่พอ → ไปดูสายขนาดใหญ่ขึ้น
        // --------------------------------------------------------------------

        if (totalAmpacity < requiredCurrent) {
          continue;
        }

        // --------------------------------------------------------------------
        // พบสายที่เหมาะสม
        // --------------------------------------------------------------------

        final size = _formatCableSize(
          cable.cableSizeSqmm,
        );

        return cable.copyWith(
          remark: '$runs × $size sq.mm',
        );
      }
    }

    // ------------------------------------------------------------------------
    // ไม่พบสายที่เหมาะสมภายใน 20 Parallel Runs
    // ------------------------------------------------------------------------

    return null;
  }

  // ==========================================================================
  // FORMAT CABLE SIZE
  // ==========================================================================

  String _formatCableSize(double size) {
    if (size == size.roundToDouble()) {
      return size.toInt().toString();
    }

    return size.toString();
  }

  // ==========================================================================
  // FILTER ONLY
  // ==========================================================================

  List<CableTableRow> filter({
    required CableDesignRequest request,
    required List<CableTableRow> rows,
  }) {
    return rows.where((row) {
      return row.cableType == request.cableType &&
          row.installationMethod == request.installationMethod &&
          row.loadedConductors == request.loadedConductors &&
          row.coreType == request.coreType;
    }).toList();
  }

  // ==========================================================================
  // HAS CANDIDATE
  // ==========================================================================

  bool hasCandidate({
    required CableDesignRequest request,
    required List<CableTableRow> rows,
  }) {
    return filter(
      request: request,
      rows: rows,
    ).isNotEmpty;
  }

  // ==========================================================================
  // MAX AMPACITY
  // ==========================================================================

  double maxAmpacity({
    required CableDesignRequest request,
    required List<CableTableRow> rows,
  }) {
    final filtered = filter(
      request: request,
      rows: rows,
    );

    if (filtered.isEmpty) {
      return 0;
    }

    filtered.sort(
      (a, b) => b.ampacity.compareTo(a.ampacity),
    );

    return filtered.first.ampacity;
  }
}