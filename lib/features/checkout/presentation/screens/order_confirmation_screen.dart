import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/order_repository.dart';
import '../../domain/order_model.dart';

/// Screen displayed upon successful placement of an order (Step 4 / Final Confirmation).
///
/// Features:
/// - Animated green checkmark badge with tactile bounce feedback.
/// - Prominent Order ID display (e.g. `#BV-2026-9812`) with tap-to-copy action.
/// - Dynamic estimated delivery date and delivery mode pill badge.
/// - Detailed ordered items summary list with variant & school tags.
/// - Delivery destination address snapshot.
/// - Full financial payment and price summary.
/// - Actions: "Track Order" and "Continue Shopping".
/// - Prevents hardware/gesture back navigation into the completed checkout stack.
class OrderConfirmationScreen extends ConsumerStatefulWidget {
  /// Unique order identifier.
  final String orderId;

  /// Optional preloaded [OrderModel] passed via navigation extra.
  final OrderModel? order;

  /// Optional callback invoked when "Track Order" action is tapped.
  final VoidCallback? onTrackOrder;

  /// Optional callback invoked when "Continue Shopping" action is tapped.
  final VoidCallback? onContinueShopping;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    this.order,
    this.onTrackOrder,
    this.onContinueShopping,
  });

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static String _formatCurrency(double amount) {
    try {
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
      ).format(amount);
    } catch (_) {
      final isWhole = amount.truncateToDouble() == amount;
      return '₹${isWhole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}';
    }
  }

  void _handleTrackOrder() {
    if (widget.onTrackOrder != null) {
      widget.onTrackOrder!();
    } else {
      context.push('/order/${widget.orderId}');
    }
  }

  void _handleContinueShopping() {
    if (widget.onContinueShopping != null) {
      widget.onContinueShopping!();
    } else {
      context.go('/');
    }
  }

  void _copyOrderIdToClipboard(String id) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ID $id copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedSmall,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Disable popping back into checkout stack
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleContinueShopping();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundSlate,
        body: SafeArea(
          child: widget.order != null
              ? _buildLoadedContent(context, widget.order!)
              : ref.watch(orderByIdProvider(widget.orderId)).when(
                    data: (fetchedOrder) {
                      if (fetchedOrder != null) {
                        return _buildLoadedContent(context, fetchedOrder);
                      }
                      return _buildFallbackContent(context);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                      ),
                    ),
                    error: (_, __) => _buildFallbackContent(context),
                  ),
        ),
        bottomNavigationBar: _buildStickyBottomBar(context),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, OrderModel order) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      children: [
        const SizedBox(height: AppSpacing.md),

        // 1. Animated Success Checkmark & Header
        _buildSuccessHeader(),
        const SizedBox(height: AppSpacing.xl),

        // 2. Order Reference & Estimated Delivery Card
        _buildOrderInfoCard(order),
        const SizedBox(height: AppSpacing.lg),

        // 3. Delivery Address Snapshot Card
        _buildDeliveryAddressCard(order),
        const SizedBox(height: AppSpacing.lg),

        // 4. Ordered Items Summary Card
        _buildItemsSummaryCard(order),
        const SizedBox(height: AppSpacing.lg),

        // 5. Financial Breakdown & Payment Method Summary Card
        _buildPaymentSummaryCard(order),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildFallbackContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.md),
        _buildSuccessHeader(),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: AppSpacing.roundedMedium,
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            children: [
              Text(
                'Order ID: ${widget.orderId}',
                key: const Key('order_confirmation_id_text'),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your order has been recorded in our system. You can track updates via your registered phone number.',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.successGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.successGreen.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.surfaceWhite,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Text(
                'Order Placed Successfully!',
                key: const Key('order_confirmation_success_title'),
                textAlign: TextAlign.center,
                style: AppTypography.heading1.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Thank you for shopping with Book Vardi! A confirmation SMS and email have been dispatched.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyRegular.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfoCard(OrderModel order) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');
    final formattedDate = dateFormat.format(order.estimatedDeliveryDate);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Column(
        children: [
          // Order ID with Copy action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Order Reference',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              InkWell(
                onTap: () => _copyOrderIdToClipboard(order.orderId),
                borderRadius: AppSpacing.roundedMicro,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          order.orderId,
                          key: const Key('order_confirmation_id_text'),
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.copy_outlined,
                        size: 14,
                        color: AppColors.primaryNavy,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),

          // Estimated Delivery
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF), // Blue-50
                  borderRadius: AppSpacing.roundedMicro,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Delivery',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      key: const Key('order_confirmation_estimated_delivery'),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.12),
                  borderRadius: AppSpacing.roundedSmall,
                ),
                child: Text(
                  order.orderStatus,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard(OrderModel order) {
    final addr = order.shippingAddress;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.primaryNavy,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Delivery Address',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${addr.fullName} • +91 ${addr.phone}',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            addr.formattedAddress,
            key: const Key('order_confirmation_shipping_address'),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSummaryCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Items Ordered (${order.totalItemCount})',
                  key: const Key('order_confirmation_items_summary'),
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSlate,
                      borderRadius: AppSpacing.roundedMicro,
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: const Icon(
                      Icons.checkroom_outlined,
                      size: 20,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.schoolName} • ${item.variantLabel} • Qty: ${item.quantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatCurrency(item.totalPrice),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(OrderModel order) {
    final pricing = order.pricing;
    final isCod = order.paymentMethod == 'COD';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Payment Details',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (isCod ? AppColors.secondaryAmber : AppColors.successGreen)
                      .withOpacity(0.12),
                  borderRadius: AppSpacing.roundedMicro,
                ),
                child: Text(
                  isCod ? 'Cash on Delivery' : 'Paid via Online',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCod
                        ? const Color(0xFFB45309)
                        : AppColors.successGreen,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          _buildRow('Items Total', _formatCurrency(pricing.subtotal)),
          if (pricing.totalDiscounts > 0) ...[
            const SizedBox(height: 4),
            _buildRow(
              'Discounts',
              '-${_formatCurrency(pricing.totalDiscounts)}',
              valueColor: AppColors.successGreen,
            ),
          ],
          const SizedBox(height: 4),
          _buildRow(
            'Delivery Fee',
            pricing.deliveryCharge == 0
                ? 'FREE'
                : _formatCurrency(pricing.deliveryCharge),
            valueColor: pricing.deliveryCharge == 0
                ? AppColors.successGreen
                : AppColors.textDark,
          ),
          if (isCod) ...[
            const SizedBox(height: 4),
            _buildRow(
              'COD Handling Fee',
              '+₹40',
              valueColor: const Color(0xFFB45309),
            ),
          ],
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Total Amount',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatCurrency(pricing.grandTotal),
                key: const Key('order_confirmation_price_summary'),
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          top: BorderSide(color: AppColors.borderGray, width: 1),
        ),
        boxShadow: AppSpacing.shadowNavBar,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomButton(
            key: const Key('order_confirmation_track_button'),
            text: 'Track Order',
            icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
            onPressed: _handleTrackOrder,
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomButton.outline(
            key: const Key('order_confirmation_continue_shopping_button'),
            text: 'Continue Shopping',
            onPressed: _handleContinueShopping,
          ),
        ],
      ),
    );
  }
}
