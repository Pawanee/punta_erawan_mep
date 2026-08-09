 /// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module  : Electrical
/// Feature : Cable Design
/// File    : cable_design_result.dart
///
/// Cable Design Result
///
/// ผลลัพธ์จากการออกแบบสายไฟ
///
/// ============================================================================

class CableDesignResult {
  /// --------------------------------------------------------------------------
  /// สถานะการคำนวณ
  /// --------------------------------------------------------------------------

  final bool isSuccess;

  /// ข้อความแจ้งผล
  final String message;

  /// --------------------------------------------------------------------------
  /// Input / Calculation
  /// --------------------------------------------------------------------------

  /// Load Current ก่อนคำนวณตัวคูณลด (A)
  final double? loadCurrent;

  /// จำนวนวงจรที่จัดกลุ่ม
  final int? groupingCircuits;

  /// Grouping Factor
  final double? groupingFactor;

  /// กระแสที่ต้องการหลังคิด Grouping Factor (A)
  final double? requiredCurrent;

  /// --------------------------------------------------------------------------
  /// Cable Selection
  /// --------------------------------------------------------------------------

  /// ขนาดสายต่อ 1 เส้น (sq.mm)
  final double? cableSizeSqmm;

  /// Ampacity ของสายต่อ 1 Run จาก Table 5-20 (A)
  final double? ampacity;

  /// จำนวน Parallel Run
  final int? parallelRuns;

  /// Ampacity รวมทุก Parallel Run (A)
  final double? totalAmpacity;

  /// Ampacity หลังตัวคูณลดรวมทุก Parallel Run (A)
  final double? deratedAmpacity;

  /// รูปแบบการจัดสาย
  ///
  /// ตัวอย่าง:
  /// 1 × 70 sq.mm
  /// 2 × 95 sq.mm
  /// 3 × 120 sq.mm
  final String? cableArrangement;

  /// ตารางอ้างอิง
  final String? reference;

  // ==========================================================================
  // CONSTRUCTOR
  // ==========================================================================

  const CableDesignResult({
    required this.isSuccess,
    required this.message,

    this.loadCurrent,
    this.groupingCircuits,
    this.groupingFactor,
    this.requiredCurrent,

    this.cableSizeSqmm,
    this.ampacity,
    this.parallelRuns,
    this.totalAmpacity,
    this.deratedAmpacity,

    this.cableArrangement,
    this.reference,
  });

  // ==========================================================================
  // SUCCESS
  // ==========================================================================

  factory CableDesignResult.success({
    required double loadCurrent,
    required int groupingCircuits,
    required double groupingFactor,
    required double requiredCurrent,

    required double cableSizeSqmm,
    required double ampacity,
    required int parallelRuns,
    required double totalAmpacity,
    required double deratedAmpacity,

    required String cableArrangement,
    required String reference,
  }) {
    return CableDesignResult(
      isSuccess: true,

      message: 'Cable selected successfully.',

      loadCurrent: loadCurrent,
      groupingCircuits: groupingCircuits,
      groupingFactor: groupingFactor,
      requiredCurrent: requiredCurrent,

      cableSizeSqmm: cableSizeSqmm,
      ampacity: ampacity,
      parallelRuns: parallelRuns,
      totalAmpacity: totalAmpacity,
      deratedAmpacity: deratedAmpacity,

      cableArrangement: cableArrangement,
      reference: reference,
    );
  }

  // ==========================================================================
  // ERROR
  // ==========================================================================

  factory CableDesignResult.error(
    String message, {
    double? loadCurrent,
    int? groupingCircuits,
    double? groupingFactor,
    double? requiredCurrent,
  }) {
    return CableDesignResult(
      isSuccess: false,
      message: message,

      loadCurrent: loadCurrent,
      groupingCircuits: groupingCircuits,
      groupingFactor: groupingFactor,
      requiredCurrent: requiredCurrent,
    );
  }
}