/// Approved ampacity source tables.
///
/// This enum identifies the reference data source only.
/// It does not contain engineering values or calculation logic.
enum AmpacityTable {
  /// PVC 70°C baseline ampacity table.
  table520,
  table521,

  /// XLPE/EPR 90°C baseline ampacity table.
  table527,
}
