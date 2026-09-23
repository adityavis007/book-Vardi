import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/guards/guest_guard.dart';
import '../../../../core/guards/pending_action.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../domain/cart_item_model.dart';
import '../../domain/price_breakup_model.dart';
import '../controllers/cart_controller.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/price_breakup_card.dart';

/// Full Cart Screen matching the Book Vardi design reference image:
/// - AppBar with "Your Cart Items <count>", yellow badge count, Clear Cart button, and close 'X' button.
/// - Free shipping progress banner ("🎉 You've unlocked FREE Shipping!", 100% progress bar).
/// - List of cart items with thumbnail, title, variant pill, quantity stepper `- 1 +`, and delete button.
/// - Summary section with Subtotal, Shipping (FREE), dashed divider, Estimated Total.
/// - Bottom action buttons: "Continue Shopping" (outlined) and "CHECKOUT ➔" (yellow filled).
/// - Trust badge: "100% Verified Secure SSL Checkout".
class CartScreen extends ConsumerStatefulWidget {
  final VoidCallback? onCheckout;
  final VoidCallback? onStartShopping;

  const CartScreen({
    super.key,
    this.onCheckout,
    this.onStartShopping,
  });

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String? _appliedCouponCode;
  double _appliedCouponDiscount = 0.0;
  bool _isCouponLoading = false;
  String? _couponError;

  void _handleApplyCoupon(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    setState(() {
      _isCouponLoading = true;
      _couponError = null;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _isCouponLoading = false;
        if (code == 'BV100' || code == 'WELCOME100') {
          _appliedCouponCode = code;
          _appliedCouponDiscount = 100.0;
          _couponError = null;
        } else if (code == 'VARDI50' || code == 'SAVE50') {
          _appliedCouponCode = code;
          _appliedCouponDiscount = 50.0;
          _couponError = null;
        } else {
          _appliedCouponCode = null;
          _appliedCouponDiscount = 0.0;
          _couponError = 'Invalid coupon code. Try "BV100" or "VARDI50"';
        }
      });
    });
  }

  void _handleRemoveCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _appliedCouponDiscount = 0.0;
      _couponError = null;
    });
  }

  void _handleProceedToCheckout(BuildContext context) {
    if (widget.onCheckout != null) {
      widget.onCheckout!();
      return;
    }

    executeWithAuthGuard(
      context,
      ref,
      action: const PendingAction(type: PendingActionType.openCart),
      onAuthenticated: () {
        try {
          context.push('/checkout');
        } catch (_) {
          Navigator.of(context).pushNamed('/checkout');
        }
      },
    );
  }

  void _handleStartShopping(BuildContext context) {
    if (widget.onStartShopping != null) {
      widget.onStartShopping!();
    } else {
      try {
        context.go('/');
      } catch (_) {
        Navigator.of(context).pushNamed('/');
      }
    }
  }

  Future<void> _handleDeleteItem(CartItemModel item) async {
    final confirmed = await QuantityStepper.showRemoveConfirmationDialog(
      context,
      itemName: item.productName,
    );

    if (confirmed == true) {
      ref.read(cartControllerProvider).removeFromCart(item.id);
    }
  }

  PriceBreakupModel _calculateEffectiveBreakup(PriceBreakupModel baseBreakup) {
    if (_appliedCouponDiscount > 0) {
      return PriceBreakupModel.calculate(
        subtotal: baseBreakup.subtotal,
        schoolBulkDiscount: baseBreakup.schoolBulkDiscount,
        couponDiscount: _appliedCouponDiscount,
      );
    }
    return baseBreakup;
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartItemsListProvider);
    final basePriceBreakup = ref.watch(cartTotalProvider);
    final effectivePriceBreakup = _calculateEffectiveBreakup(basePriceBreakup);

    final bool isEmpty = cartItems.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: AppColors.categoryPillBg,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 20.0,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: 10.0),
            Text(
              'Your Cart Items',
              style: AppTypography.heading1.copyWith(
                fontSize: 18.0,
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8.0),
            if (!isEmpty)
              Container(
                width: 24.0,
                height: 24.0,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryAmberDark,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${cartItems.length}',
                  style: const TextStyle(
                    color: AppColors.surfaceWhite,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (!isEmpty)
            TextButton.icon(
              key: const Key('cart_clear_button'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    ),
                    title: const Text('Clear Shopping Cart?'),
                    content: const Text(
                      'Are you sure you want to remove all items from your cart?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: AppColors.destructiveRed),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(cartControllerProvider).clearCart();
                }
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 16.0,
                color: AppColors.destructiveRed,
              ),
              label: Text(
                'Clear Cart',
                style: AppTypography.caption.copyWith(
                  color: AppColors.destructiveRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            key: const Key('cart_close_button'),
            icon: const Icon(Icons.close, color: AppColors.textDark),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ],
      ),
      body: isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                // Free Shipping Progress Banner
                _buildFreeShippingBanner(),

                // Cart List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      ...cartItems.map((item) => _buildCartItemCard(item)),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),

                // Bottom Summary & Action Bar
                _buildBottomSummaryAndActions(context, effectivePriceBreakup),
              ],
            ),
    );
  }

  Widget _buildFreeShippingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.borderGray, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎉 ', style: TextStyle(fontSize: 14.0)),
                  Text(
                    'You\'ve unlocked FREE Shipping!',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 13.0,
                    ),
                  ),
                ],
              ),
              Text(
                '100%',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.successGreen,
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: 1.0,
              backgroundColor: AppColors.borderGray,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
              minHeight: 6.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96.0,
              height: 96.0,
              decoration: const BoxDecoration(
                color: AppColors.categoryPillBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48.0,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Your cart is empty',
              style: AppTypography.heading1.copyWith(
                fontSize: 22.0,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Looks like you haven\'t added any books or uniforms to your cart yet.',
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            CustomButton(
              key: const Key('cart_empty_start_shopping_button'),
              text: 'Start Shopping',
              isFullWidth: false,
              onPressed: () => _handleStartShopping(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item) {
    return Container(
      key: Key('cart_item_card_${item.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray, width: 1.0),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Thumbnail Image
          ClipRRect(
            borderRadius: AppSpacing.roundedSmall,
            child: Container(
              width: 72.0,
              height: 72.0,
              color: AppColors.imagePlaceholder,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (ctx, _) => Container(
                        color: AppColors.imagePlaceholder,
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 24.0,
                          color: AppColors.disabledBg,
                        ),
                      ),
                      errorWidget: (ctx, _, __) => Container(
                        color: AppColors.imagePlaceholder,
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 24.0,
                          color: AppColors.disabledBg,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.menu_book_rounded,
                      size: 24.0,
                      color: AppColors.disabledBg,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Details & Quantity Stepper
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  item.productName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),

                // Unit Price
                Text(
                  PriceBreakupCard.formatCurrency(item.unitPrice),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Row with Quantity Stepper and Delete button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuantityStepper(
                      quantity: item.quantity,
                      maxStock: item.maxStock,
                      itemName: item.productName,
                      onQuantityChanged: (newQty) {
                        if (newQty == 0) {
                          ref.read(cartControllerProvider).removeFromCart(item.id);
                        } else {
                          ref.read(cartControllerProvider).updateQuantity(item.id, newQty);
                        }
                      },
                      onRemove: () {
                        ref.read(cartControllerProvider).removeFromCart(item.id);
                      },
                    ),
                    IconButton(
                      key: Key('cart_item_delete_${item.id}'),
                      icon: const Icon(Icons.delete_outline_rounded,
                        size: 22.0,
                        color: AppColors.textSecondary,
                      ),
                      splashRadius: 20.0,
                      onPressed: () => _handleDeleteItem(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummaryAndActions(
    BuildContext context,
    PriceBreakupModel priceBreakup,
  ) {
    final formatCur = PriceBreakupCard.formatCurrency;

    return Container(
      key: const Key('cart_sticky_bottom_bar'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          top: BorderSide(color: AppColors.borderGray, width: 1.0),
        ),
        boxShadow: AppSpacing.shadowNavBar,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtotal row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formatCur(priceBreakup.subtotal),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Shipping row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipping',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  priceBreakup.deliveryCharge == 0.0
                      ? 'FREE'
                      : formatCur(priceBreakup.deliveryCharge),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: priceBreakup.deliveryCharge == 0.0
                        ? AppColors.successGreen
                        : AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Dashed Divider
            const Divider(color: AppColors.borderGray, thickness: 1.0, height: 1.0),
            const SizedBox(height: AppSpacing.sm),

            // Estimated Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Total',
                  style: AppTypography.heading2.copyWith(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  formatCur(priceBreakup.grandTotal),
                  key: const Key('cart_bottom_bar_total'),
                  style: AppTypography.heading1.copyWith(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Action Buttons: Continue Shopping & CHECKOUT
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('cart_continue_shopping_button'),
                    onPressed: () => _handleStartShopping(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                      side: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    key: const Key('cart_proceed_to_checkout_button'),
                    onPressed: () => _handleProceedToCheckout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryAmber,
                      foregroundColor: AppColors.textDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CHECKOUT',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18.0,
                          color: AppColors.textDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Secure SSL Checkout Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 14.0,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6.0),
                Text(
                  '100% Verified Secure SSL Checkout',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
