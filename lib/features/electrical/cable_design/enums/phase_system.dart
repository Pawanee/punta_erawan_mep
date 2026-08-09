/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Phase System
///
/// ระบบไฟฟ้า
///
/// ============================================================================
enum PhaseSystem {
  singlePhase,
  threePhase,
}

extension PhaseSystemExtension on PhaseSystem {
  String get displayName {
    switch (this) {
      case PhaseSystem.singlePhase:
        return '1Ø';

      case PhaseSystem.threePhase:
        return '3Ø';
    }
  }
}