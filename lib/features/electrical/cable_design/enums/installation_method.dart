 /// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module : Electrical
/// Feature : Cable Design
/// File : installation_method.dart
///
/// Version : 1.0.0
/// OFOR : OFOR-050 Revision-3
///
/// Description
/// ----------------------------------------------------------------------------
/// กลุ่มการติดตั้งสายไฟฟ้า (Installation Group)
///
/// ใช้อ้างอิงตามตาราง 5-20 วสท.2564
///
/// หมายเหตุ
/// ----------------------------------------------------------------------------
/// เดิมใช้ชื่อ Method A / Method B
///
/// ปรับเป็น Group 1 / Group 2
///
/// เพื่อให้ตรงกับ
///
/// • Table 5-20
/// • JSON Database
/// • Repository
/// • Cable Selection Algorithm
/// • Cable Design Engine
///
/// ============================================================================

enum InstallationMethod {
  /// --------------------------------------------------------------------------
  /// Group 1
  /// --------------------------------------------------------------------------
  ///
  /// อ้างอิงคอลัมน์ Group 1 ใน Table 5-20
  ///
  group1(
    code: 'G1',
    displayName: 'Group 1',
    description: 'Installation Group 1',
  ),

  /// --------------------------------------------------------------------------
  /// Group 2
  /// --------------------------------------------------------------------------
  ///
  /// อ้างอิงคอลัมน์ Group 2 ใน Table 5-20
  ///
  group2(
    code: 'G2',
    displayName: 'Group 2',
    description: 'Installation Group 2',
  );

  /// รหัสที่ใช้ภายในระบบ
  final String code;

  /// ชื่อสำหรับแสดงผลบนหน้าจอ
  final String displayName;

  /// คำอธิบาย
  final String description;

  const InstallationMethod({
    required this.code,
    required this.displayName,
    required this.description,
  });

  /// ========================================================================
  /// ค้นหาจาก Code
  /// ========================================================================
  static InstallationMethod fromCode(String code) {
    return InstallationMethod.values.firstWhere(
      (e) => e.code == code,
      orElse: () => InstallationMethod.group1,
    );
  }

  /// ========================================================================
  /// ค้นหาจากชื่อ Enum
  /// ========================================================================
  static InstallationMethod fromName(String name) {
    return InstallationMethod.values.firstWhere(
      (e) => e.name == name,
      orElse: () => InstallationMethod.group1,
    );
  }

  @override
  String toString() => displayName;
}