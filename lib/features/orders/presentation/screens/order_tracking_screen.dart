import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/order_repository.dart';
import '../../domain/order_model.dart';
import '../../domain/tracking_step_model.dart';

/// Real-time Order Tracking Screen displaying live vertical milestone timeline,
/// courier partner AWB credentials, order items breakdown, and cancellation actions.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _isCancelling = false;

  Future<void> _handleCancelOrder(OrderModel order) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel order ${order.orderId}?',
              style: AppTypography.bodyRegular,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                hintText: 'e.g. Ordered incorrect size, changed mind',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructiveRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isCancelling = true);
    try {
      final reason = reasonController.text.trim().isEmpty
          ? 'Customer requested cancellation via app'
          : reasonController.text.trim();

      await ref
          .read(ordersRepositoryProvider)
          .cancelOrder(order.orderId, reason);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Order ${order.orderId} was successfully cancelled.'),
            backgroundColor: AppColors.primaryNavy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${e.toString()}'),
            backgroundColor: AppColors.destructiveRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderTrackingStreamProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        title: Text(
          'Track Order',
          style: AppTypography.heading2.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => context.pop(),
        ),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return _buildNotFoundView(context);
          }
          return RefreshIndicator(
            color: AppColors.primaryNavy,
            onRefresh: () async {
              ref.invalidate(orderTrackingStreamProvider(widget.orderId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Order Status Header Card
                  _buildHeaderCard(order),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Vertical Milestone Timeline Card
                  _buildTimelineCard(order),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Courier Partner Info (if available)
                  if (order.trackingMetadata.carrierName != null ||
                      order.trackingMetadata.trackingNumber != null) ...[
                    _buildCarrierCard(order),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // 4. Delivery Address Card
                  _buildAddressCard(order),
                  const SizedBox(height: AppSpacing.md),

                  // 5. Ordered Items Summary Card
                  _buildItemsCard(order),
                  const SizedBox(height: AppSpacing.md),

                  // 6. Pricing Summary Card
                  _buildPricingCard(order),
                  const SizedBox(height: AppSpacing.lg),

                  // 7. Cancellation & Action Buttons
                  if (order.orderStatus == OrderStatus.confirmed ||
                      order.orderStatus == OrderStatus.packed)
                    _buildCancellationAction(order),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryNavy),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.destructiveRed),
                const SizedBox(height: AppSpacing.md),
                Text('Error loading tracking updates', style: AppTypography.heading2),
                const SizedBox(height: AppSpacing.xs),
                Text(error.toString(), style: AppTypography.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(OrderModel order) {
    final status = order.orderStatus;
    final deliveryDateFormat = DateFormat('EEEE, dd MMM yyyy');
    final formattedEstDate = deliveryDateFormat.format(order.estimatedDeliveryDate);

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.orderId,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.badgeBgColor,
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Text(
                  status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: status.badgeTextColor,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status == OrderStatus.delivered
                      ? 'Delivered on $formattedEstDate'
                      : 'Estimated Delivery: $formattedEstDate',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(OrderModel order) {
    final steps = order.buildTrackingSteps();

    return Container(
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
          Text(
            'Fulfillment Journey',
            style: AppTypography.heading2.copyWith(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dot + Connecting line column
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: step.isCompleted
                                ? (step.status == OrderStatus.cancelled
                                    ? AppColors.destructiveRed
                                    : AppColors.primaryNavy)
                                : AppColors.borderGray,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            step.status == OrderStatus.cancelled
                                ? Icons.close_rounded
                                : Icons.check_rounded,
                            size: 14,
                            color: step.isCompleted ? Colors.white : Colors.transparent,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2.0,
                              color: step.isCompleted
                                  ? AppColors.primaryNavy
                                  : AppColors.borderGray,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Step Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: AppTypography.bodyMedium.copyWith(
                                color: step.isCompleted
                                    ? AppColors.primaryNavy
                                    : AppColors.textSecondary,
                                fontWeight: step.isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.description,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (step.timestamp != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(step.timestamp!),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCarrierCard(OrderModel order) {
    final meta = order.trackingMetadata;

    return Container(
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
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: AppColors.primaryNavy),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Courier & Dispatch Details',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderGray),
          if (meta.carrierName != null) ...[
            Text('Carrier: ${meta.carrierName!}', style: AppTypography.bodyRegular),
            const SizedBox(height: 4),
          ],
          if (meta.trackingNumber != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text('AWB Number: ${meta.trackingNumber!}', style: AppTypography.bodyRegular),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Copy Tracking Number',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: meta.trackingNumber!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tracking number copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard(OrderModel order) {
    final addr = order.shippingAddress;

    return Container(
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
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primaryNavy),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Delivery Address',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderGray),
          Text(addr.fullName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('${addr.addressLine1}, ${addr.city}, ${addr.state} - ${addr.pincode}',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text('Phone: ${addr.phone}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildItemsCard(OrderModel order) {
    return Container(
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
          Text(
            'Ordered Items (${order.totalItemCount})',
            style: AppTypography.heading2.copyWith(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 20, color: AppColors.borderGray),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (_, __) => const Divider(height: 16, color: AppColors.borderGray),
            itemBuilder: (context, idx) {
              final item = order.items[idx];
              return Row(
                children: [
                  ClipRRect(
                    borderRadius: AppSpacing.roundedSmall,
                    child: Container(
                      width: 50,
                      height: 50,
                      color: AppColors.backgroundSlate,
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.primaryNavy,
                              ),
                            )
                          : const Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.primaryNavy,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.variantLabel != null)
                          Text(
                            'Size/Variant: ${item.variantLabel!}',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        Text(
                          'Qty: ${item.quantity}',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(OrderModel order) {
    final p = order.pricing;

    return Container(
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
          Text(
            'Payment Summary',
            style: AppTypography.heading2.copyWith(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 20, color: AppColors.borderGray),
          _priceRow('Subtotal', '₹${p.subtotal.toStringAsFixed(0)}'),
          if (p.couponDiscount > 0)
            _priceRow('Coupon Discount', '-₹${p.couponDiscount.toStringAsFixed(0)}', isGreen: true),
          if (p.schoolBulkDiscount > 0)
            _priceRow('School Bulk Discount', '-₹${p.schoolBulkDiscount.toStringAsFixed(0)}', isGreen: true),
          _priceRow('Delivery Charge', p.deliveryCharge == 0 ? 'FREE' : '₹${p.deliveryCharge.toStringAsFixed(0)}'),
          const Divider(height: 16, color: AppColors.borderGray),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Grand Total (${order.paymentMethod})',
                  style: AppTypography.heading2.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '₹${p.grandTotal.toStringAsFixed(0)}',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isGreen ? const Color(0xFF0F5132) : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationAction(OrderModel order) {
    return OutlinedButton.icon(
      key: const Key('cancel_order_btn'),
      onPressed: _isCancelling ? null : () => _handleCancelOrder(order),
      icon: _isCancelling
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.destructiveRed),
            )
          : const Icon(Icons.cancel_outlined, color: AppColors.destructiveRed),
      label: Text(
        _isCancelling ? 'Cancelling...' : 'Cancel Order',
        style: const TextStyle(color: AppColors.destructiveRed, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.destructiveRed),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedSmall),
      ),
    );
  }

  Widget _buildNotFoundView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text('Order Not Found', style: AppTypography.heading2),
            const SizedBox(height: AppSpacing.xs),
            Text('No order matching ID ${widget.orderId} was found.', style: AppTypography.bodyRegular),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Orders'),
            ),
          ],
        ),
      ),
    );
  }
}
