/// UI-facing outcomes for a V2 cable-design execution.
///
/// These states preserve engineering outcome semantics without calculating or
/// selecting anything in the presentation layer.
enum CableDesignV2PresentationStatus {
  initial,
  needsInput,
  invalidInput,
  ampacityResolved,
  ampacityUnresolved,
  voltageDropNotVerified,
  voltageDropInsufficient,
  voltageDropVerified,
  voltageDropFailed,
  unsupported,
}
