import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_modal_sheet.dart';
import '../../data/order_repository.dart';
import '../../domain/order_model.dart';

/// Customer Orders History Screen displaying chronological past orders
/// with live status badges, item thumbnails, and deep-linking to tracking.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    // 1. Guest Guard: Prompt unauthenticated users to login
    if (!authState.isAuthenticated || user == null) {
      return _buildGuestGuardView(context);
    }

    final ordersAsync = ref.watch(userOrdersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: AppTypography.heading2.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyOrdersView(context);
          }
          return RefreshIndicator(
            color: AppColors.primaryNavy,
            onRefresh: () async {
              ref.invalidate(userOrdersStreamProvider);
            },
            child: ListView.separated(
              key: const Key('orders_list_view'),
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _buildOrderCard(context, orders[index]);
              },
            ),
          );
        },
        loading: () => _buildLoadingShimmer(),
        error: (error, _) => _buildErrorView(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildGuestGuardView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: AppTypography.heading2.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        centerTitle: false,
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
                  color: AppColors.mintPillBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Log in to view your orders',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Track live deliveries, view tax invoices, and manage school uniforms & books orders in one place.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                key: const Key('guest_orders_login_btn'),
                onPressed: () => AuthModalBottomSheet.show(context),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Login or Create Account'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No orders placed yet',
              style: AppTypography.heading2.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'When you buy school kits, books, or uniforms, your orders will appear here.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              key: const Key('explore_catalog_btn'),
              onPressed: () => context.go('/'),
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
              child: const Text('Explore Catalog'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt);
    final status = order.orderStatus;

    return InkWell(
      key: Key('order_card_${order.orderId}'),
      onTap: () => context.push('/order/${Uri.encodeComponent(order.orderId)}'),
      borderRadius: AppSpacing.roundedSmall,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.roundedSmall,
          border: Border.all(color: AppColors.borderGray, width: 1.0),
          boxShadow: AppSpacing.elevationSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID + Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Status Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: status.badgeBgColor,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Text(
                    status.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: status.badgeTextColor,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.borderGray),

            // Item Thumbnails + Quantity Summary
            Row(
              children: [
                // Thumbnails preview row
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: order.items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final item = order.items[idx];
                        return ClipRRect(
                          borderRadius: AppSpacing.roundedSmall,
                          child: Container(
                            width: 52,
                            height: 52,
                            color: AppColors.backgroundSlate,
                            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.menu_book_rounded,
                                      size: 20,
                                      color: AppColors.primaryNavy,
                                    ),
                                  )
                                : const Icon(
                                    Icons.menu_book_rounded,
                                    size: 20,
                                    color: AppColors.primaryNavy,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Items Count
                Text(
                  '${order.totalItemCount} ${order.totalItemCount == 1 ? 'item' : 'items'}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.borderGray),

            // Footer: Grand Total + Track Order CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹${order.pricing.grandTotal.toStringAsFixed(0)}',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  key: Key('track_btn_${order.orderId}'),
                  onPressed: () => context.push('/order/${Uri.encodeComponent(order.orderId)}'),
                  icon: const Icon(Icons.local_shipping_outlined, size: 16),
                  label: const Text('Track Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedSmall,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          height: 180,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.roundedSmall,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.destructiveRed),
            const SizedBox(height: AppSpacing.md),
            Text('Failed to load orders', style: AppTypography.heading2),
            const SizedBox(height: AppSpacing.xs),
            Text(error, style: AppTypography.caption, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => ref.invalidate(userOrdersStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
