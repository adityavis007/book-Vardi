import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/price_breakup_model.dart';

/// Pricing summary breakdown card component for Cart and Checkout screens.
/// Displays:
/// - Items Total (Subtotal)
/// - School Bulk Discount (if applicable)
/// - Coupon Discount (if applicable)
/// - Estimated Shipping ("FREE" in green when eligible, else standard fee)
/// - Total Payable in 18px Bold
/// - Promo code coupon input with "APPLY" action and applied coupon state
/// - Total savings callout badge
class PriceBreakupCard extends StatefulWidget {
  /// The pricing calculation engine data model.
  final PriceBreakupModel priceBreakup;

  /// Callback when user submits a coupon code.
  final ValueChanged<String>? onApplyCoupon;

  /// Callback to remove currently applied coupon.
  final VoidCallback? onRemoveCoupon;

  /// Currently applied coupon code string, if any.
  final String? appliedCouponCode;

  /// Whether coupon validation is loading.
  final bool isCouponLoading;

  /// Optional coupon validation error message to display beneath input.
  final String? couponErrorMessage;

  /// Whether to display the coupon entry section.
  final bool showCouponSection;

  /// Custom title for the summary card (defaults to "Price Details").
  final String title;

  const PriceBreakupCard({
    super.key,
    required this.priceBreakup,
    this.onApplyCoupon,
    this.onRemoveCoupon,
    this.appliedCouponCode,
    this.isCouponLoading = false,
    this.couponErrorMessage,
    this.showCouponSection = true,
    this.title = 'Price Details',
  });

  /// Utility to format currency values using Indian locale conventions (₹).
  static String formatCurrency(double amount) {
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

  @override
  State<PriceBreakupCard> createState() => _PriceBreakupCardState();
}

class _PriceBreakupCardState extends State<PriceBreakupCard> {
  late final TextEditingController _couponController;

  @override
  void initState() {
    super.initState();
    _couponController = TextEditingController();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _handleApply() {
    final code = _couponController.text.trim();
    if (code.isNotEmpty && widget.onApplyCoupon != null) {
      widget.onApplyCoupon!(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pb = widget.priceBreakup;
    final bool hasBulkDiscount = pb.schoolBulkDiscount > 0;
    final bool hasCouponDiscount = pb.couponDiscount > 0;
    final bool hasSavings = pb.totalDiscounts > 0 || pb.isFreeDelivery;

    double totalSavings = pb.totalDiscounts;
    if (pb.isFreeDelivery) {
      totalSavings += PriceBreakupModel.standardDeliveryCharge;
    }

    return Container(
      key: const Key('price_breakup_card'),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray, width: 1.0),
        boxShadow: AppSpacing.elevationSm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            widget.title,
            style: AppTypography.heading2.copyWith(
              color: AppColors.textDark,
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderGray, height: 1, thickness: 1),
          const SizedBox(height: AppSpacing.md),

          // 1. Items Total
          _buildRow(
            label: 'Items Total',
            value: PriceBreakupCard.formatCurrency(pb.subtotal),
            valueKey: const Key('price_breakup_subtotal_value'),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. School Bulk Discount (if applicable)
          if (hasBulkDiscount) ...[
            _buildRow(
              label: 'School Bulk Discount',
              value: '-${PriceBreakupCard.formatCurrency(pb.schoolBulkDiscount)}',
              valueColor: AppColors.successGreen,
              valueKey: const Key('price_breakup_bulk_discount_value'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // 3. Coupon Discount (if applicable)
          if (hasCouponDiscount) ...[
            _buildRow(
              label: widget.appliedCouponCode != null
                  ? 'Coupon Discount (${widget.appliedCouponCode})'
                  : 'Coupon Discount',
              value: '-${PriceBreakupCard.formatCurrency(pb.couponDiscount)}',
              valueColor: AppColors.successGreen,
              valueKey: const Key('price_breakup_coupon_discount_value'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // 4. Estimated Shipping
          _buildShippingRow(pb),

          // Free Delivery Incentive progress pill (if near threshold)
          if (pb.subtotal > 0 && pb.amountToFreeDelivery > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.categoryPillBg,
                borderRadius: AppSpacing.roundedSmall,
                border: Border.all(
                  color: AppColors.categoryPillBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 16,
                    color: AppColors.primaryNavy,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Add ${PriceBreakupCard.formatCurrency(pb.amountToFreeDelivery)} more for FREE Delivery',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderGray, height: 1, thickness: 1),
          const SizedBox(height: AppSpacing.md),

          // 5. Total Payable (18px Bold)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Total Payable',
                style: AppTypography.heading2.copyWith(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                PriceBreakupCard.formatCurrency(pb.grandTotal),
                key: const Key('price_breakup_grand_total_value'),
                style: AppTypography.heading1.copyWith(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '(Inclusive of all taxes)',
            style: AppTypography.micro.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // 6. Savings Callout Badge
          if (hasSavings && totalSavings > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              key: const Key('price_breakup_savings_banner'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5), // Emerald-50
                borderRadius: AppSpacing.roundedSmall,
                border: Border.all(
                  color: const Color(0xFFA7F3D0), // Emerald-200
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'You will save ${PriceBreakupCard.formatCurrency(totalSavings)} on this order',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF065F46), // Emerald-800
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 7. Promo Code Coupon Section
          if (widget.showCouponSection) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildCouponSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    Color? valueColor,
    Key? valueKey,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          key: valueKey,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildShippingRow(PriceBreakupModel pb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Estimated Shipping',
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (pb.isFreeDelivery)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                PriceBreakupCard.formatCurrency(PriceBreakupModel.standardDeliveryCharge),
                style: AppTypography.bodyRegular.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textMuted,
                  fontSize: 12.0,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'FREE',
                key: const Key('price_breakup_free_shipping_tag'),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.successGreen,
                ),
              ),
            ],
          )
        else
          Text(
            pb.deliveryCharge > 0
                ? PriceBreakupCard.formatCurrency(pb.deliveryCharge)
                : 'FREE',
            key: const Key('price_breakup_shipping_value'),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: pb.deliveryCharge == 0
                  ? AppColors.successGreen
                  : AppColors.textDark,
            ),
          ),
      ],
    );
  }

  Widget _buildCouponSection() {
    final isApplied = widget.appliedCouponCode != null &&
        widget.appliedCouponCode!.trim().isNotEmpty;

    if (isApplied) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: AppSpacing.roundedSmall,
          border: Border.all(
            color: const Color(0xFF86EFAC),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_rounded,
              size: 18,
              color: AppColors.successGreen,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.appliedCouponCode!.toUpperCase(),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Coupon applied successfully',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.successGreen,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              key: const Key('price_breakup_remove_coupon'),
              behavior: HitTestBehavior.opaque,
              onTap: widget.onRemoveCoupon,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'REMOVE',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.destructiveRed,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44.0,
          decoration: BoxDecoration(
            color: AppColors.backgroundSlate,
            borderRadius: AppSpacing.roundedSmall,
            border: Border.all(
              color: widget.couponErrorMessage != null
                  ? AppColors.destructiveRed
                  : AppColors.borderGray,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.local_offer_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: TextField(
                  key: const Key('price_breakup_coupon_input'),
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    hintStyle: AppTypography.bodyRegular.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 13.0,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 10.0,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _handleApply(),
                ),
              ),
              GestureDetector(
                key: const Key('price_breakup_apply_coupon'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.isCouponLoading ? null : _handleApply,
                child: Container(
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.borderGray, width: 1.0),
                    ),
                  ),
                  child: widget.isCouponLoading
                      ? const SizedBox(
                          width: 16.0,
                          height: 16.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryNavy,
                            ),
                          ),
                        )
                      : Text(
                          'APPLY',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                            fontSize: 13.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        if (widget.couponErrorMessage != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.couponErrorMessage!,
            key: const Key('price_breakup_coupon_error'),
            style: AppTypography.caption.copyWith(
              color: AppColors.destructiveRed,
              fontSize: 12.0,
            ),
          ),
        ],
      ],
    );
  }
}
