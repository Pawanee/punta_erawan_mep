/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module : Electrical
/// Feature : Cable Design
/// File : core_type.dart
///
/// Description
/// ----------------------------------------------------------------------------
///
/// ลักษณะตัวนำของสายไฟ
///
/// ใช้ร่วมกันทั้ง
///
/// • UI
/// • JSON Database
/// • Repository
/// • Cable Design Engine
///
/// ============================================================================

enum CoreType {
  /// =========================================================================
  /// Single Core
  /// =========================================================================
  singleCore(
    code: 'SC',
    displayName: 'Single Core',
    thaiName: 'แกนเดียว',
    description: 'สายไฟชนิดแกนเดียว',
  ),

  /// =========================================================================
  /// Multi Core
  /// =========================================================================
  multiCore(
    code: 'MC',
    displayName: 'Multi Core',
    thaiName: 'หลายแกน',
    description: 'สายไฟชนิดหลายแกน',
  );

  /// Code สำหรับเก็บในฐานข้อมูล
  final String code;

  /// ชื่อภาษาอังกฤษ
  final String displayName;

  /// ชื่อภาษาไทย
  final String thaiName;

  /// คำอธิบาย
  final String description;

  const CoreType({
    required this.code,
    required this.displayName,
    required this.thaiName,
    required this.description,
  });

  /// ========================================================================
  /// ค้นหา Enum จาก Code
  /// ========================================================================
  static CoreType fromCode(String code) {
    return CoreType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => CoreType.singleCore,
    );
  }

  /// ========================================================================
  /// ค้นหาจากชื่อ Enum
  /// ========================================================================
  static CoreType fromName(String name) {
    return CoreType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CoreType.singleCore,
    );
  }

  @override
  String toString() => displayName;
}