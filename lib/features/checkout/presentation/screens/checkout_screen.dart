import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/stationery_background.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../cart/domain/cart_item_model.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../domain/address_model.dart';
import '../controllers/checkout_controller.dart';
import 'add_address_screen.dart';
import 'address_step_screen.dart';

/// Professional, full-featured Book Vardi Checkout Screen matching the
/// official web platform design and school stationery theme.
///
/// Supports responsive 2-column layout (Desktop/Tablet >= 900px) and
/// single-column layout with sticky bottom CTA (Mobile < 900px).
class CheckoutScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final void Function(String orderId)? onOrderPlaced;

  const CheckoutScreen({super.key, this.onBack, this.onOrderPlaced});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isCouponExpanded = false;
  String _selectedUpiApp = 'Google Pay';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCheckoutIfNeeded();
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _initializeCheckoutIfNeeded() {
    final checkoutState = ref.read(checkoutControllerProvider);
    if (checkoutState.items.isEmpty) {
      final cartItems = ref.read(cartItemsListProvider);
      if (cartItems.isNotEmpty) {
        ref
            .read(checkoutControllerProvider.notifier)
            .initStandardCartCheckout();
      }
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/cart');
    }
  }

  void _openAddAddressModal([AddressModel? existingAddress]) {
    final authState = ref.read(authControllerProvider);
    final userId = authState.user?.userId;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddAddressScreen(
          userId: userId,
          initialAddress: existingAddress,
          onAddressAdded: (newAddress) {
            ref
                .read(checkoutControllerProvider.notifier)
                .selectAddress(newAddress);
          },
        ),
      ),
    );
  }

  void _showAddressSelectionModal(List<AddressModel> addresses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: AppSpacing.sheetRadius),
      builder: (ctx) {
        final currentSelected = ref
            .watch(checkoutControllerProvider)
            .selectedAddress;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Delivery Address',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      final isSelected =
                          currentSelected?.addressId == addr.addressId;
                      return InkWell(
                        onTap: () {
                          ref
                              .read(checkoutControllerProvider.notifier)
                              .selectAddress(addr);
                          Navigator.pop(ctx);
                        },
                        borderRadius: AppSpacing.roundedMedium,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.categoryPillBg
                                : AppColors.surfaceWhite,
                            borderRadius: AppSpacing.roundedMedium,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryNavy
                                  : AppColors.borderGray,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected
                                    ? AppColors.primaryNavy
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.imagePlaceholder,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            addr.addressType.toUpperCase(),
                                            style: AppTypography.caption
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          addr.fullName,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${addr.addressLine1}, ${addr.city} - ${addr.pincode}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Phone: ${addr.phone}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openAddAddressModal();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('+ Add New Address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNavy,
                      side: const BorderSide(color: AppColors.primaryNavy),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyCoupon(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coupon code.'),
          backgroundColor: AppColors.destructiveRed,
        ),
      );
      return;
    }

    double discount = 0.0;
    final checkoutState = ref.read(checkoutControllerProvider);
    final subtotal = checkoutState.basePricing.subtotal;

    if (cleanCode == 'SCHOOL10') {
      discount = (subtotal * 0.10).clamp(10.0, 500.0);
    } else if (cleanCode == 'WELCOME100') {
      discount = subtotal >= 300 ? 100.0 : (subtotal * 0.10);
    } else if (cleanCode == 'VARDI50') {
      discount = 50.0;
    } else if (cleanCode == 'FREESHIP') {
      discount = 49.0;
    } else if (cleanCode == 'PEN5') {
      discount = (subtotal * 0.05).clamp(5.0, 100.0);
    } else {
      discount = (subtotal * 0.10).clamp(10.0, 200.0);
    }

    ref
        .read(checkoutControllerProvider.notifier)
        .applyCoupon(cleanCode, discount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coupon "$cleanCode" applied! You saved ₹${discount.toInt()}',
        ),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeCoupon() {
    ref.read(checkoutControllerProvider.notifier).applyCoupon('', 0.0);
    _couponController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coupon removed.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    final checkoutState = ref.read(checkoutControllerProvider);
    final controller = ref.read(checkoutControllerProvider.notifier);

    if (checkoutState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your order is empty. Please add items to checkout.'),
          backgroundColor: AppColors.destructiveRed,
        ),
      );
      return;
    }

    if (checkoutState.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a delivery address to continue.'),
          backgroundColor: AppColors.primaryNavy,
        ),
      );
      _openAddAddressModal();
      return;
    }

    await controller.placeOrder(
      onSuccess: (orderId) {
        if (!mounted) return;
        if (widget.onOrderPlaced != null) {
          widget.onOrderPlaced!(orderId);
        } else {
          context.go('/order-confirmation/$orderId');
        }
      },
      onFailure: (errorMessage) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.destructiveRed,
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutControllerProvider);
    final savedAddressesAsync = ref.watch(savedAddressesStreamProvider);

    // Auto-select first address if none selected and addresses loaded
    savedAddressesAsync.whenData((addresses) {
      if (checkoutState.selectedAddress == null && addresses.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              ref.read(checkoutControllerProvider).selectedAddress == null) {
            final defaultAddr = addresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => addresses.first,
            );
            ref
                .read(checkoutControllerProvider.notifier)
                .selectAddress(defaultAddr);
          }
        });
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopLayout = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Announcement Strip
            _buildAnnouncementBar(),

            // 2. Navigation & Breadcrumb Header
            _buildHeader(context),

            // 3. Main Content Area (Responsive)
            Expanded(
              child: StationeryBackground(
                child: checkoutState.items.isEmpty
                    ? _buildEmptyState(context)
                    : isDesktopLayout
                    ? _buildDesktopLayout(checkoutState, savedAddressesAsync)
                    : _buildMobileLayout(checkoutState, savedAddressesAsync),
              ),
            ),

            // 4. Sticky Bottom CTA (Mobile only)
            if (!isDesktopLayout && checkoutState.items.isNotEmpty)
              _buildMobileStickyBottomBar(checkoutState),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP ANNOUNCEMENT BAR (Dark Pine Green)
  // ==========================================
  Widget _buildAnnouncementBar() {
    return Container(
      width: double.infinity,
      color: AppColors.announcementDarkBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnnouncementPill(
              badge: 'DISCOUNT',
              badgeColor: AppColors.secondaryAmber,
              textColor: AppColors.textDark,
              message: '10% OFF First Order | Code: SCHOOL10',
              onTap: () {
                _couponController.text = 'SCHOOL10';
                _applyCoupon('SCHOOL10');
              },
            ),
            const SizedBox(width: 24),
            _buildAnnouncementPill(
              badge: 'TRUST',
              badgeColor: const Color(0xFF10B981),
              textColor: Colors.white,
              message: '7-Day Easy Returns on Uniforms & Books',
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementPill({
    required String badge,
    required Color badgeColor,
    required Color textColor,
    required String message,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_outward_rounded,
            size: 12,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER & BREADCRUMBS
  // ==========================================
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.8),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primaryNavy,
            ),
            tooltip: 'Back',
            onPressed: _handleBack,
          ),
          const SizedBox(width: 4),
          // Breadcrumbs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Secure Checkout',
                      style: AppTypography.caption.copyWith(
                        fontSize: 14,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // SSL Encrypted Trust Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.mintPillBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 13,
                  color: AppColors.mintPillText,
                ),
                const SizedBox(width: 5),
                Text(
                  '256-Bit SSL',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mintPillText,
                    fontWeight: FontWeight.bold,
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

  // ==========================================
  // EMPTY CHECKOUT STATE
  // ==========================================
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_shopping_cart_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your checkout session is empty',
              style: AppTypography.heading2.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add uniforms, textbooks, or stationery from the catalog to place an order.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => context.go('/cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedMedium,
                ),
              ),
              child: const Text('Return to Cart'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DESKTOP LAYOUT (2 Columns >= 900px)
  // ==========================================
  Widget _buildDesktopLayout(
    CheckoutState checkoutState,
    AsyncValue<List<AddressModel>> savedAddressesAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Steps 1, 2, 3 (Flex: 6.5)
              Expanded(
                flex: 65,
                child: Column(
                  children: [
                    _buildStep1AddressCard(checkoutState, savedAddressesAsync),
                    const SizedBox(height: 20),
                    _buildStep2DeliverySpeedCard(checkoutState),
                    const SizedBox(height: 20),
                    _buildStep3PaymentMethodCard(checkoutState),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right Column: Order Summary (Flex: 35)
              Expanded(flex: 35, child: _buildOrderSummaryCard(checkoutState)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MOBILE LAYOUT (Single Column < 900px)
  // ==========================================
  Widget _buildMobileLayout(
    CheckoutState checkoutState,
    AsyncValue<List<AddressModel>> savedAddressesAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          _buildStep1AddressCard(checkoutState, savedAddressesAsync),
          const SizedBox(height: 16),
          _buildStep2DeliverySpeedCard(checkoutState),
          const SizedBox(height: 16),
          _buildStep3PaymentMethodCard(checkoutState),
          const SizedBox(height: 16),
          _buildOrderSummaryCard(checkoutState),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 1: DELIVERY ADDRESS CARD
  // ==========================================
  Widget _buildStep1AddressCard(
    CheckoutState checkoutState,
    AsyncValue<List<AddressModel>> savedAddressesAsync,
  ) {
    final selectedAddress = checkoutState.selectedAddress;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedLarge,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepNumberBadge(1),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Where should we deliver your stationery parcel?',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // + Add New Button
              OutlinedButton.icon(
                key: const Key('checkout_add_address_button'),
                onPressed: () => _openAddAddressModal(),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Add New'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.borderGray),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Address Card or Empty Box
          if (selectedAddress != null) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppSpacing.roundedMedium,
                border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tag: HOME / WORK / CAMPUS
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selectedAddress.addressType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // Edit Address Icon
                          IconButton(
                            key: const Key('checkout_edit_address_icon'),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            tooltip: 'Edit Address',
                            onPressed: () =>
                                _openAddAddressModal(selectedAddress),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                          const SizedBox(width: 8),
                          // Selected Checkmark Pill
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryNavy,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    selectedAddress.fullName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedAddress.addressLine1}${selectedAddress.city.isNotEmpty ? ', ${selectedAddress.city}' : ''}${selectedAddress.pincode.isNotEmpty ? ' - ${selectedAddress.pincode}' : ''}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${selectedAddress.phone}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Switch Address option if multiple saved addresses exist
            savedAddressesAsync.maybeWhen(
              data: (addresses) {
                if (addresses.length > 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _showAddressSelectionModal(addresses),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: Text(
                          'Change Address (${addresses.length} saved)',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryNavy,
                          textStyle: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ] else ...[
            // Empty Address Placeholder
            InkWell(
              onTap: () => _openAddAddressModal(),
              borderRadius: AppSpacing.roundedMedium,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.imagePlaceholder,
                  borderRadius: AppSpacing.roundedMedium,
                  border: Border.all(
                    color: AppColors.borderGray,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.add_location_alt_outlined,
                      size: 32,
                      color: AppColors.primaryNavy,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Delivery Address Selected',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap here or click "+ Add New" to add your school or home address',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: DELIVERY SPEED & CARRIER
  // ==========================================
  Widget _buildStep2DeliverySpeedCard(CheckoutState checkoutState) {
    final isStandard = checkoutState.deliveryMode == DeliveryMode.standard;
    final isExpress = checkoutState.deliveryMode == DeliveryMode.express;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedLarge,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepNumberBadge(2),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Speed & Carrier',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select your preferred transit speed for school / college dispatch',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Two Delivery Speed Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 550;
              final standardCard = _buildDeliverySpeedTile(
                key: const Key('checkout_delivery_mode_standard'),
                isSelected: isStandard,
                icon: Icons.local_shipping_outlined,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: AppColors.primaryNavy,
                title: 'Standard Delivery',
                subtitle: '3 - 5 Business Days via BlueDart / Delhivery',
                highlightText: '✓ Eligible for Free Delivery',
                highlightColor: AppColors.successGreen,
                badgeText: 'FREE',
                badgeBg: const Color(0xFFDCFCE7),
                badgeTextColor: const Color(0xFF166534),
                onTap: () {
                  ref
                      .read(checkoutControllerProvider.notifier)
                      .selectDeliveryMode(DeliveryMode.standard);
                },
              );

              final expressCard = _buildDeliverySpeedTile(
                key: const Key('checkout_delivery_mode_express'),
                isSelected: isExpress,
                icon: Icons.bolt_rounded,
                iconBg: const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFD97706),
                title: 'Campus Express',
                subtitle: '1 - 2 Days Priority Air Dispatch',
                highlightText: '⚡ Guaranteed Pre-Exam Fast Delivery',
                highlightColor: const Color(0xFFD97706),
                badgeText: '+₹49',
                badgeBg: const Color(0xFFF1F5F9),
                badgeTextColor: AppColors.textDark,
                onTap: () {
                  ref
                      .read(checkoutControllerProvider.notifier)
                      .selectDeliveryMode(DeliveryMode.express);
                },
              );

              if (isNarrow) {
                return Column(
                  children: [
                    standardCard,
                    const SizedBox(height: 12),
                    expressCard,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: standardCard),
                  const SizedBox(width: 16),
                  Expanded(child: expressCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySpeedTile({
    required Key key,
    required bool isSelected,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String highlightText,
    required Color highlightColor,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: AppSpacing.roundedMedium,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : AppColors.surfaceWhite,
          borderRadius: AppSpacing.roundedMedium,
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderGray,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
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
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              highlightText,
              style: TextStyle(
                color: highlightColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 3: PAYMENT METHOD
  // ==========================================
  Widget _buildStep3PaymentMethodCard(CheckoutState checkoutState) {
    final isUpi = checkoutState.paymentMethod == PaymentMethodType.upi;
    final isCod = checkoutState.paymentMethod == PaymentMethodType.cod;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedLarge,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepNumberBadge(3),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose your trusted payment provider (Zero surcharge)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Two Primary Payment Selectors (UPI vs COD)
          Row(
            children: [
              Expanded(
                child: _buildPaymentMethodTile(
                  key: const Key('checkout_payment_upi'),
                  isSelected: isUpi,
                  icon: Icons.phone_android_rounded,
                  label: 'UPI / Online Pay',
                  onTap: () {
                    ref
                        .read(checkoutControllerProvider.notifier)
                        .selectPaymentMethod(PaymentMethodType.upi);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPaymentMethodTile(
                  key: const Key('checkout_payment_cod'),
                  isSelected: isCod,
                  icon: Icons.payments_outlined,
                  label: 'Cash on Delivery',
                  onTap: () {
                    ref
                        .read(checkoutControllerProvider.notifier)
                        .selectPaymentMethod(PaymentMethodType.cod);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sub-panel when UPI is selected
          if (isUpi) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: AppSpacing.roundedMedium,
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Popular Instant UPI Apps & Razorpay Gateway',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Zero Surcharge',
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // UPI App Pills
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _buildUpiPill('Google Pay'),
                      _buildUpiPill('PhonePe'),
                      _buildUpiPill('Paytm'),
                      _buildUpiPill('Other UPI ID'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Device launch prompt
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_android_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tapping Place Order will launch $_selectedUpiApp directly on your device.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Sub-panel when COD is selected
          if (isCod) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: AppSpacing.roundedMedium,
                border: Border.all(color: const Color(0xFFFEF08A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pay in cash when your parcel is delivered. A ₹40 courier handling fee applies to Cash on Delivery orders.',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required Key key,
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: AppSpacing.roundedMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : AppColors.surfaceWhite,
          borderRadius: AppSpacing.roundedMedium,
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderGray,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primaryNavy
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppColors.textDark
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiPill(String appName) {
    final isSelected = _selectedUpiApp == appName;
    return InkWell(
      onTap: () {
        setState(() => _selectedUpiApp = appName);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderGray,
          ),
        ),
        child: Text(
          appName,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // RIGHT COLUMN / ORDER SUMMARY CARD
  // ==========================================
  Widget _buildOrderSummaryCard(CheckoutState checkoutState) {
    final items = checkoutState.items;
    final pricing = checkoutState.pricing;
    final basePricing = checkoutState.basePricing;
    final isCouponApplied = basePricing.couponDiscount > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedLarge,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order Summary',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length} ${items.length == 1 ? 'Item' : 'Items'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items Preview List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  children: [
                    // Item Thumbnail
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.imagePlaceholder,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          item.imageUrl != null &&
                              item.imageUrl!.startsWith('http')
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.school_outlined,
                                size: 24,
                                color: AppColors.primaryNavy,
                              ),
                            )
                          : const Icon(
                              Icons.menu_book_outlined,
                              size: 24,
                              color: AppColors.primaryNavy,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Item Name & Quantity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: ${item.quantity} × ₹${item.unitPrice.toInt()}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Item Total
                    Text(
                      '₹${item.totalPrice.toInt()}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Coupon Code Section
          Container(
            decoration: BoxDecoration(
              color: isCouponApplied
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCouponApplied
                    ? const Color(0xFFA7F3D0)
                    : AppColors.borderGray,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                if (!isCouponApplied) ...[
                  InkWell(
                    onTap: () {
                      setState(() => _isCouponExpanded = !_isCouponExpanded);
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          size: 16,
                          color: AppColors.textDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Have a Coupon Code?',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          _isCouponExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  if (_isCouponExpanded) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('checkout_coupon_input'),
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'e.g. SCHOOL10',
                              hintStyle: const TextStyle(fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceWhite,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppColors.borderGray,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          key: const Key('checkout_apply_coupon_button'),
                          onPressed: () => _applyCoupon(_couponController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'APPLY',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.successGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coupon Applied (-₹${basePricing.couponDiscount.toInt()})',
                          style: const TextStyle(
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        color: AppColors.destructiveRed,
                        onPressed: _removeCoupon,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Price Breakdown Lines
          _buildSummaryRow(
            label: 'Cart Subtotal',
            value: '₹${basePricing.subtotal.toInt()}',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            label: 'Delivery Speed',
            value: checkoutState.effectiveDeliveryCharge == 0
                ? 'FREE'
                : '+₹${checkoutState.effectiveDeliveryCharge.toInt()}',
            isSuccess: checkoutState.effectiveDeliveryCharge == 0,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            label: 'GST / Campus Tax',
            value: 'Included',
            isSuccess: true,
          ),
          if (basePricing.couponDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              label: 'Coupon Discount',
              value: '-₹${basePricing.couponDiscount.toInt()}',
              isSuccess: true,
            ),
          ],
          if (checkoutState.codHandlingFee > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              label: 'COD Courier Handling Fee',
              value: '+₹${checkoutState.codHandlingFee.toInt()}',
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.borderGray, height: 1),
          ),

          // Total Payable
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Total Payable',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${pricing.grandTotal.toInt()}',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // PLACE ORDER CTA (Secondary Amber Yellow)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              key: const Key('checkout_place_order_button'),
              onPressed: checkoutState.isLoading ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryAmber,
                foregroundColor: AppColors.textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: checkoutState.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.textDark,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'PLACE ORDER • ₹${pricing.grandTotal.toInt()}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Trust Badges Footer
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildTrustBadge(
                icon: Icons.verified_user_outlined,
                label: '100% Genuine Stationery',
              ),
              _buildTrustBadge(
                icon: Icons.security_rounded,
                label: 'Safe Campus Delivery',
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
    bool isSuccess = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            color: isSuccess ? AppColors.successGreen : AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadge({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MOBILE STICKY BOTTOM BAR (< 900px)
  // ==========================================
  Widget _buildMobileStickyBottomBar(CheckoutState checkoutState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Payable',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                '₹${checkoutState.pricing.grandTotal.toInt()}',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('checkout_sticky_place_order_button'),
                onPressed: checkoutState.isLoading ? null : _handlePlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryAmber,
                  foregroundColor: AppColors.textDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: checkoutState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textDark,
                        ),
                      )
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_rounded, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'PLACE ORDER',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP NUMBER BADGE HELPER
  // ==========================================
  Widget _buildStepNumberBadge(int number) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
