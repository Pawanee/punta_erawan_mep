class Table42GroundingRow {
  const Table42GroundingRow({
    required this.protectiveDeviceThresholdA,
    required this.minimumGroundingConductorSizeSqmm,
  });

  final double protectiveDeviceThresholdA;
  final double minimumGroundingConductorSizeSqmm;

  String get rowId => 'protectiveDeviceThresholdA:$protectiveDeviceThresholdA';
}
