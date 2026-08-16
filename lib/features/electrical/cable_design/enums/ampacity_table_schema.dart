/// Identifies the published column structure of an ampacity reference table.
///
/// This is metadata only. It neither defines a table's values nor transforms
/// one table schema into another.
enum AmpacityTableSchema {
  groupCoreLoadedConductors,
  surfaceMounted,
  underground,
  cableTray,
  flexibleCable,
  mineralInsulated,
}
