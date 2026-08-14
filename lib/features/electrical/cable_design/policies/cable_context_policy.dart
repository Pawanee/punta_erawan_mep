 import '../enums/cable_type.dart';
import '../../voltage_drop/models/cable_context.dart';

/// ============================================================================
/// PUNTA ERAWAN MEP
///
/// Module  : Electrical
/// Feature : Cable Design
/// File    : cable_context_policy.dart
///
/// OFOR-007C.7B
///
/// Description
/// ----------------------------------------------------------------------------
///
/// Contract for resolving an approved engineering CableContext from a
/// CableType.
///
/// This layer owns engineering policy.
///
/// It is intentionally separated from:
/// - reference-data repositories;
/// - calculation services;
/// - UI;
/// - JSON data.
///
/// No CableType mapping is embedded in this contract.
/// Concrete policy implementations must provide the approved mapping.
/// ============================================================================

abstract interface class CableContextPolicy {
  /// Resolves the approved engineering context for [cableType].
  ///
  /// Implementations must return only an approved CableContext.
  ///
  /// If no approved mapping exists, the implementation must not guess.
  CableContext resolve(CableType cableType);
}