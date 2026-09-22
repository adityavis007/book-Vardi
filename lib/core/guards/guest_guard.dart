import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/widgets/auth_modal_sheet.dart';
import 'pending_action.dart';

/// Central "Guest Guard" execution interceptor.
///
/// Implements frictionless guest browsing:
/// 1. If user is authenticated: immediately executes [onAuthenticated].
/// 2. If user is guest/unauthenticated:
///    - Saves [action] (including product, variant, quantity, and [onAuthenticated] callback)
///      to [pendingActionProvider].
///    - Presents the contextual [AuthModalBottomSheet] without losing current catalog screen or variant selection.
///    - Upon successful login/registration, retrieves the saved pending intent and automatically
///      fires [onAuthenticated] with the exact original parameters.
///    - If user dismisses or cancels, clears the queue safely.
Future<bool> executeWithAuthGuard(
  BuildContext context,
  WidgetRef ref, {
  required PendingAction action,
  required VoidCallback onAuthenticated,
}) async {
  var authState = ref.read(authControllerProvider);

  // If session is still initializing (cold boot), await first resolved state
  if (authState is AuthLoading || authState is AuthInitial) {
    authState = await ref.read(authControllerProvider.notifier).stream.first;
  }

  // If already authenticated, execute immediately without barrier
  if (authState is AuthAuthenticated) {
    onAuthenticated();
    return true;
  }

  // Register intent with callback in ephemeral queue
  final pendingAction = action.copyWith(onExecute: onAuthenticated);
  ref.read(pendingActionProvider.notifier).setPendingAction(pendingAction);

  // If widget unmounted during initial session resolution, abort
  if (!context.mounted) return false;

  // Present the contextual AuthModalBottomSheet
  final success = await AuthModalBottomSheet.show(context);

  if (success == true) {
    // Atomically consume and execute the captured intent
    final pending =
        ref.read(pendingActionProvider.notifier).consumePendingAction();
    pending?.onExecute?.call();
    return true;
  } else {
    // Clear pending queue on dismissal or cancellation
    ref.read(pendingActionProvider.notifier).clear();
    return false;
  }
}

/// Convenience extension on [WidgetRef] for idiomatic invocation within Riverpod widgets.
extension GuestGuardRefExtension on WidgetRef {
  Future<bool> withAuthGuard(
    BuildContext context, {
    required PendingAction action,
    required VoidCallback onAuthenticated,
  }) {
    return executeWithAuthGuard(
      context,
      this,
      action: action,
      onAuthenticated: onAuthenticated,
    );
  }
}
