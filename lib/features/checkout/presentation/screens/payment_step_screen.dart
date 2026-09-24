import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:book_vardi/core/constants/app_colors.dart';
import 'package:book_vardi/core/constants/app_spacing.dart';
import 'package:book_vardi/core/theme/app_typography.dart';
import 'package:book_vardi/shared/widgets/custom_button.dart';
import '../../domain/address_model.dart';
import '../controllers/checkout_controller.dart';

/// Step 3 Screen in the Checkout Pipeline: Payment Method Selection & Final Review.
class PaymentStepScreen extends ConsumerStatefulWidget {
  final VoidCallback? onPayPressed;
  final VoidCallback? onBack;
  final VoidCallback? onChangeAddress;
  final bool showAppBar;

  const PaymentStepScreen({
    super.key,
    this.onPayPressed,
    this.onBack,
    this.onChangeAddress,
    this.showAppBar = true,
  });

  @override
  ConsumerState<PaymentStepScreen> createState() => _PaymentStepScreenState();
}

class _PaymentStepScreenState extends ConsumerState<PaymentStepScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure active checkout step is Step 3 (Payment)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(checkoutControllerProvider.notifier);
      final currentStep = ref.read(checkoutControllerProvider).currentStep;
      if (currentStep != CheckoutStep.payment) {
        controller.goToStep(CheckoutStep.payment);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    ref.listen<CheckoutState>(checkoutControllerProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        _showRetryDialog(context, next.errorMessage!);
      }
    });

    final checkoutState = ref.watch(checkoutControllerProvider);
    final selectedMethod = checkoutState.paymentMethod;
    final selectedAddress = checkoutState.selectedAddress;
    final pricing = checkoutState.pricing;
    final isCod = selectedMethod == PaymentMethodType.cod;

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Payment Method'),
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        ref.read(checkoutControllerProvider.notifier).previousStep();
                        widget.onBack!();
                      },
                    )
                  : null,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Step 3 of 3 Progress Indicator
            _buildStepProgressBar(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // 1. Security Assurance Banner
                  _buildSecurityBanner(),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Delivery Address Snapshot Summary Card
                  if (selectedAddress != null) ...[
                    _buildAddressSummaryCard(context, selectedAddress),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // 3. Payment Method Radio Selection Group
                  _buildPaymentMethodSection(context, selectedMethod),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Detailed Pricing Breakdown Card (Dynamic COD Fee)
                  _buildPriceBreakdownCard(checkoutState),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),

            // 5. Sticky Bottom Action Bar
            _buildStickyBottomBar(
              context: context,
              grandTotal: pricing.grandTotal,
              isCod: isCod,
              isLoading: checkoutState.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgressBar() {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Step 3 of 3: Payment & Confirmation',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SSL Encrypted',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const ClipRRect(
            borderRadius: AppSpacing.roundedFull,
            child: LinearProgressIndicator(
              value: 1.0,
              minHeight: 6.0,
              backgroundColor: AppColors.borderGray,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Emerald-50
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: const Color(0xFFBBF7D0)), // Emerald-200
      ),
      child: Row(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '256-bit SSL Encrypted Transaction',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534), // Emerald-800
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Your card, UPI, and banking details are never stored on our servers.',
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF15803D), // Emerald-700
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSummaryCard(BuildContext context, AddressModel address) {
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
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.primaryNavy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Delivering To',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              TextButton(
                key: const Key('change_address_button'),
                onPressed: () {
                  ref.read(checkoutControllerProvider.notifier).previousStep();
                  if (widget.onChangeAddress != null) {
                    widget.onChangeAddress!();
                  } else if (widget.onBack != null) {
                    widget.onBack!();
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'CHANGE',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${address.fullName} • +91 ${address.phone}',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            address.formattedAddress,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(
    BuildContext context,
    PaymentMethodType currentMethod,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'Select Payment Option',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Divider(height: AppSpacing.md),

          // 1. UPI Option
          _buildPaymentOptionTile(
            key: const Key('payment_method_upi'),
            type: PaymentMethodType.upi,
            current: currentMethod,
            title: 'UPI (Google Pay, PhonePe, Paytm, Any UPI ID)',
            subtitle: 'Instant & free bank-to-bank transfer',
            icon: Icons.qr_code_2_outlined,
            iconColor: const Color(0xFF0F9D58),
            popularBadge: 'RECOMMENDED',
          ),
          const Divider(height: 1),

          // 2. Credit / Debit Card Option
          _buildPaymentOptionTile(
            key: const Key('payment_method_card'),
            type: PaymentMethodType.card,
            current: currentMethod,
            title: 'Credit / Debit Card (Visa, MasterCard, RuPay)',
            subtitle: 'Pay securely using any debit or credit card',
            icon: Icons.credit_card_outlined,
            iconColor: AppColors.primaryNavy,
          ),
          const Divider(height: 1),

          // 3. Net Banking Option
          _buildPaymentOptionTile(
            key: const Key('payment_method_netBanking'),
            type: PaymentMethodType.netBanking,
            current: currentMethod,
            title: 'Net Banking',
            subtitle: 'Supports 50+ major Indian banks',
            icon: Icons.account_balance_outlined,
            iconColor: const Color(0xFF3B82F6),
          ),
          const Divider(height: 1),

          // 4. Cash on Delivery (COD) Option (with ₹40 fee pill)
          _buildPaymentOptionTile(
            key: const Key('payment_method_cod'),
            type: PaymentMethodType.cod,
            current: currentMethod,
            title: 'Cash on Delivery (COD)',
            subtitle: 'Pay in cash at your doorstep upon delivery',
            icon: Icons.payments_outlined,
            iconColor: AppColors.secondaryAmber,
            trailingPill: '+ ₹40 Handling Fee',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required Key key,
    required PaymentMethodType type,
    required PaymentMethodType current,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    String? trailingPill,
    String? popularBadge,
  }) {
    final isSelected = type == current;
    return InkWell(
      key: key,
      onTap: () {
        ref.read(checkoutControllerProvider.notifier).selectPaymentMethod(type);
      },
      child: Container(
        color: isSelected ? const Color(0xFFF0F4FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Radio<PaymentMethodType>(
              value: type,
              groupValue: current,
              activeColor: AppColors.primaryNavy,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(checkoutControllerProvider.notifier)
                      .selectPaymentMethod(val);
                }
              },
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: AppSpacing.roundedMicro,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (popularBadge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.12),
                            borderRadius: AppSpacing.roundedMicro,
                          ),
                          child: Text(
                            popularBadge,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (trailingPill != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAmber.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.roundedSmall,
                        border: Border.all(
                          color: AppColors.secondaryAmber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        trailingPill,
                        key: const Key('cod_handling_fee_pill'),
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFFB45309), // Amber-700
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdownCard(CheckoutState state) {
    final pb = state.basePricing;
    final effectiveDelivery = state.effectiveDeliveryCharge;
    final codFee = state.codHandlingFee;
    final grandTotal = state.pricing.grandTotal;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Summary',
            style: AppTypography.heading2.copyWith(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // Subtotal
          _buildSummaryRow(
            label: 'Items Total (${state.totalItemCount} items)',
            value: _formatCurrency(pb.subtotal),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Discounts (if any)
          if (pb.totalDiscounts > 0) ...[
            _buildSummaryRow(
              label: 'Discounts Applied',
              value: '-${_formatCurrency(pb.totalDiscounts)}',
              valueColor: AppColors.successGreen,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Delivery Charge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery (${state.deliveryMode.displayName})',
                style: AppTypography.bodyRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                effectiveDelivery == 0
                    ? 'FREE'
                    : _formatCurrency(effectiveDelivery),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: effectiveDelivery == 0
                      ? AppColors.successGreen
                      : AppColors.textDark,
                ),
              ),
            ],
          ),

          // Dynamic COD Handling Fee Line (only visible when COD is active)
          if (codFee > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'COD Handling Fee',
                      style: AppTypography.bodyRegular.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Tooltip(
                      message:
                          'Courier cash handling & collection verification charge',
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  '+${_formatCurrency(codFee)}',
                  key: const Key('price_breakup_cod_fee_value'),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // Total Payable (Grand Total)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                key: const Key('payment_grand_total_text'),
                child: Text(
                  _formatCurrency(grandTotal),
                  style: AppTypography.heading1.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
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
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar({
    required BuildContext context,
    required double grandTotal,
    required bool isCod,
    required bool isLoading,
  }) {
    final buttonLabel = isCod
        ? 'Place Order via COD • ${_formatCurrency(grandTotal)}'
        : 'Pay ${_formatCurrency(grandTotal)}';

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
            key: const Key('payment_primary_button'),
            text: buttonLabel,
            isLoading: isLoading,
            onPressed: () {
              if (widget.onPayPressed != null) {
                widget.onPayPressed!();
              } else {
                ref.read(checkoutControllerProvider.notifier).placeOrder();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRetryDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          key: const Key('payment_retry_dialog'),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedLarge,
          ),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.destructiveRed,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Payment Unsuccessful',
                  style: AppTypography.heading2.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              key: const Key('retry_dialog_change_method_button'),
              onPressed: () {
                ref.read(checkoutControllerProvider.notifier).setError(null);
                Navigator.of(ctx).pop();
              },
              child: const Text('Change Method'),
            ),
            ElevatedButton(
              key: const Key('retry_dialog_retry_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: AppColors.surfaceWhite,
              ),
              onPressed: () {
                ref.read(checkoutControllerProvider.notifier).setError(null);
                Navigator.of(ctx).pop();
                ref.read(checkoutControllerProvider.notifier).placeOrder();
              },
              child: const Text('Retry Payment'),
            ),
          ],
        );
      },
    );
  }
}
