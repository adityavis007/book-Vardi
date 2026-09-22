import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../orders/domain/order_model.dart';
import '../../../orders/domain/tracking_step_model.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_carrier_modal.dart';
import '../widgets/admin_invoice_dialog.dart';

/// Fulfillment and logistics operations console for managing customer orders.
class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(adminOrdersFilterProvider);
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        title: Text(
          'Fulfillment Center',
          style: AppTypography.heading2.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Orders',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNavy),
            onPressed: () => ref.invalidate(adminOrdersProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _FulfillmentFilterBar(
            selectedStatus: activeFilter,
            onSelect: (status) {
              ref.read(adminOrdersFilterProvider.notifier).state = status;
            },
          ),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState(activeFilter);
          }
          return RefreshIndicator(
            color: AppColors.primaryNavy,
            onRefresh: () async => ref.invalidate(adminOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _AdminOrderCard(order: order);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryNavy),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.destructiveRed),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load fulfillment queue',
                  style: AppTypography.heading2.copyWith(color: AppColors.primaryNavy),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => ref.invalidate(adminOrdersProvider),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(OrderStatus? filter) {
    final label = filter != null ? filter.displayName : 'Any';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.mintPillBg.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 48,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Orders Found',
              style: AppTypography.heading2.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'There are currently no orders in status "$label".',
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable chip bar for status filtering.
class _FulfillmentFilterBar extends StatelessWidget {
  final OrderStatus? selectedStatus;
  final ValueChanged<OrderStatus?> onSelect;

  const _FulfillmentFilterBar({
    required this.selectedStatus,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final filters = <_StatusFilterItem>[
      const _StatusFilterItem(label: 'All Orders', status: null),
      const _StatusFilterItem(label: 'Pending', status: OrderStatus.pending),
      const _StatusFilterItem(label: 'Confirmed', status: OrderStatus.confirmed),
      const _StatusFilterItem(label: 'Packed', status: OrderStatus.packed),
      const _StatusFilterItem(label: 'Shipped', status: OrderStatus.shipped),
      const _StatusFilterItem(label: 'Out for Delivery', status: OrderStatus.outForDelivery),
      const _StatusFilterItem(label: 'Delivered', status: OrderStatus.delivered),
      const _StatusFilterItem(label: 'Cancelled', status: OrderStatus.cancelled),
    ];

    return Container(
      height: 54,
      color: AppColors.surfaceWhite,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final isSelected = selectedStatus == item.status;
          return ChoiceChip(
            label: Text(item.label),
            selected: isSelected,
            onSelected: (_) => onSelect(item.status),
            selectedColor: AppColors.primaryNavy,
            backgroundColor: AppColors.backgroundSlate,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.primaryNavy,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primaryNavy : AppColors.borderGray,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusFilterItem {
  final String label;
  final OrderStatus? status;
  const _StatusFilterItem({required this.label, required this.status});
}

/// Comprehensive card representing a single order in the fulfillment pipeline.
class _AdminOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;

  const _AdminOrderCard({required this.order});

  @override
  ConsumerState<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends ConsumerState<_AdminOrderCard> {
  bool _isProcessing = false;

  Future<void> _updateStatus(OrderStatus nextStatus) async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updateOrderStatus(widget.order.orderId, nextStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.successGreen,
            content: Text(
              'Order #${widget.order.orderId.substring(0, 8)} marked as ${nextStatus.displayName.toUpperCase()}.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.destructiveRed,
            content: Text('Failed to update status: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId;
    final dateStr =
        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID, Date & Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '#$shortId',
                    style: AppTypography.heading2.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    dateStr,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.orderStatus.badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.orderStatus.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: order.orderStatus.badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Customer and Delivery Recipient
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.backgroundSlate,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_pin_circle_outlined, size: 20, color: AppColors.primaryNavy),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.shippingAddress.fullName} • ${order.shippingAddress.phone}',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      Text(
                        '${order.shippingAddress.city}, ${order.shippingAddress.state} (${order.shippingAddress.pincode})',
                        style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (order.trackingMetadata.carrierName != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        order.trackingMetadata.carrierName!,
                        style: AppTypography.micro.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      Text(
                        'AWB: ${order.trackingMetadata.trackingNumber ?? 'N/A'}',
                        style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Items summary
          Text(
            '${order.totalItemCount} Items:',
            style: AppTypography.micro.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          ...order.items.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x ',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.productName} (${item.variantLabel ?? 'Standard'})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: AppColors.textDark),
                    ),
                  ),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(0)}',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
          if (order.items.length > 3)
            Text(
              '+ ${order.items.length - 3} more items',
              style: AppTypography.micro.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          const Divider(height: 20, color: AppColors.borderGray),

          // Total and Payment info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.paymentMethod,
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: order.paymentStatus.toLowerCase() == 'paid'
                              ? AppColors.mintPillBg
                              : const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.paymentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: order.paymentStatus.toLowerCase() == 'paid'
                                ? AppColors.successGreen
                                : const Color(0xFF856404),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Mode: ${order.deliveryMode}',
                    style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Text(
                '₹${order.pricing.grandTotal.toStringAsFixed(0)}',
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Workflow Bar
          Row(
            children: [
              // Invoice / Packing slip button
              OutlinedButton.icon(
                key: Key('admin_invoice_button_${order.orderId}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('Invoice'),
                onPressed: () => AdminInvoiceDialog.show(context, order),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Status Progression CTA
              Expanded(
                child: _buildProgressionButton(order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionButton(OrderModel order) {
    if (_isProcessing) {
      return const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
        ),
      );
    }

    switch (order.orderStatus) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: AppColors.secondaryAmber,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: const Icon(Icons.inventory_2_outlined, size: 18),
          label: const Text(
            'Pack & Ready',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          onPressed: () => _updateStatus(OrderStatus.packed),
        );

      case OrderStatus.packed:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryAmber,
            foregroundColor: AppColors.primaryNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: const Icon(Icons.local_shipping_rounded, size: 18),
          label: const Text(
            'Dispatch / Ship',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          onPressed: () async {
            await AdminCarrierModal.show(
              context,
              orderId: order.orderId,
              initialCarrier: order.trackingMetadata.carrierName,
              initialTrackingNumber: order.trackingMetadata.trackingNumber,
            );
          },
        );

      case OrderStatus.shipped:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7), // Light blue
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: const Icon(Icons.delivery_dining_rounded, size: 18),
          label: const Text(
            'Out for Delivery',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          onPressed: () => _updateStatus(OrderStatus.outForDelivery),
        );

      case OrderStatus.outForDelivery:
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          icon: const Icon(Icons.check_circle_rounded, size: 18),
          label: const Text(
            'Mark Delivered',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          onPressed: () => _updateStatus(OrderStatus.delivered),
        );

      case OrderStatus.delivered:
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.mintPillBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 18),
              SizedBox(width: 6),
              Text(
                'Delivered & Closed',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      case OrderStatus.cancelled:
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Order Cancelled',
            style: TextStyle(
              color: AppColors.destructiveRed,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
    }
  }
}
