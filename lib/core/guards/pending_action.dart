import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported types of transactional user intents that require authentication.
enum PendingActionType {
  addToCart,
  buyNow,
  toggleWishlist,
  openCart,
  openOrders,
  openProfile,
}

/// Ephemeral action object holding intent state across the "Guest Guard" auth flow.
@immutable
class PendingAction {
  final PendingActionType type;
  final String? productId;
  final String? variantId;
  final int quantity;
  final Map<String, dynamic>? extraPayload;
  final VoidCallback? onExecute;

  const PendingAction({
    required this.type,
    this.productId,
    this.variantId,
    this.quantity = 1,
    this.extraPayload,
    this.onExecute,
  });

  PendingAction copyWith({
    PendingActionType? type,
    String? productId,
    String? variantId,
    int? quantity,
    Map<String, dynamic>? extraPayload,
    VoidCallback? onExecute,
  }) {
    return PendingAction(
      type: type ?? this.type,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      extraPayload: extraPayload ?? this.extraPayload,
      onExecute: onExecute ?? this.onExecute,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingAction &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          productId == other.productId &&
          variantId == other.variantId &&
          quantity == other.quantity;

  @override
  int get hashCode =>
      type.hashCode ^
      productId.hashCode ^
      variantId.hashCode ^
      quantity.hashCode;

  @override
  String toString() =>
      'PendingAction(type: ${type.name}, productId: $productId, variantId: $variantId, qty: $quantity)';
}

/// StateNotifier holding the ephemeral pending action during login/registration.
class PendingActionNotifier extends StateNotifier<PendingAction?> {
  PendingActionNotifier() : super(null);

  /// Capture a pending intent before showing the Auth Intercept Sheet
  void setPendingAction(PendingAction action) {
    state = action;
  }

  /// Retrieve and clear the current pending intent upon successful auth
  PendingAction? consumePendingAction() {
    final action = state;
    state = null;
    return action;
  }

  /// Clear the pending action if user dismisses or cancels
  void clear() {
    state = null;
  }
}

/// Riverpod provider for active PendingAction
final pendingActionProvider =
    StateNotifierProvider<PendingActionNotifier, PendingAction?>((ref) {
  return PendingActionNotifier();
});
