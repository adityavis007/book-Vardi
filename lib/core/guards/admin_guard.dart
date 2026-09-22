import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/widgets/auth_modal_sheet.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../theme/app_typography.dart';

/// Provider determining whether the current active session has Administrator privileges.
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null && user.isAdmin;
});

/// GoRouter redirect guard protecting administrative route families.
String? adminRouteRedirect(BuildContext context, GoRouterState state, Ref ref) {
  final location = state.matchedLocation;
  if (!location.startsWith('/admin')) {
    return null;
  }

  // Exclude the access denied screen itself from redirect loop
  if (location == '/admin/access-denied') {
    return null;
  }

  final user = ref.read(currentUserProvider);
  final isAuth = ref.read(isAuthenticatedProvider);

  if (!isAuth || user == null || !user.isAdmin) {
    return '/admin/access-denied';
  }

  return null;
}

/// Fallback screen presented when an unauthorized user attempts to access `/admin`.
class AdminAccessDeniedScreen extends ConsumerWidget {
  const AdminAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roleText = user == null ? 'Guest' : user.role.toValue();

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        title: Text(
          'Security Notice',
          style: AppTypography.heading2.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2), // Light red badge
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 64,
                  color: AppColors.destructiveRed,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Administrator Access Required',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The section you are attempting to open is restricted to authorized Book Vardi operations staff. Your current account role is: "$roleText".',
                style: AppTypography.bodyRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                key: const Key('admin_return_home_btn'),
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('Return to Customer Store'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedSmall,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const Key('admin_switch_account_btn'),
                onPressed: () {
                  AuthModalBottomSheet.show(context);
                },
                child: const Text('Sign In with Admin Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
