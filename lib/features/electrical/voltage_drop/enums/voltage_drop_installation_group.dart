/// ============================================================================
/// VOLTAGE DROP INSTALLATION GROUP
///
/// อ้างอิงกลุ่มการติดตั้งตามหัวตาราง 9.1 และ 9.3
///
/// หมายเหตุสำคัญ
/// - Table 9.1 / 9.3 รวม Group 1, 2 และ 5 ไว้ในคอลัมน์เดียวกัน
/// - ดังนั้น Group 1, Group 2 และ Group 5 ใช้ค่าตารางเดียวกัน
/// - ห้ามเรียกคอลัมน์นี้ว่า "Group 1.25" เพราะ 1.25 เป็นค่าบางรายการ
///   ในตาราง ไม่ใช่ชื่อ Group
/// ============================================================================
enum VoltageDropInstallationGroup {
  group1(
    code: 'G1',
    displayName: 'Group 1',
  ),
  group2(
    code: 'G2',
    displayName: 'Group 2',
  ),
  group3(
    code: 'G3',
    displayName: 'Group 3',
  ),
  group4(
    code: 'G4',
    displayName: 'Group 4',
  ),
  group5(
    code: 'G5',
    displayName: 'Group 5',
  ),
  group6(
    code: 'G6',
    displayName: 'Group 6',
  ),
  group7(
    code: 'G7',
    displayName: 'Group 7',
  );

  final String code;
  final String displayName;

  const VoltageDropInstallationGroup({
    required this.code,
    required this.displayName,
  });

  /// Table 9.1 / 9.3: Group 1, 2 and 5 share one column.
  bool get isGroup1_2_5 =>
      this == VoltageDropInstallationGroup.group1 ||
      this == VoltageDropInstallationGroup.group2 ||
      this == VoltageDropInstallationGroup.group5;

  @override
  String toString() => displayName;
}
