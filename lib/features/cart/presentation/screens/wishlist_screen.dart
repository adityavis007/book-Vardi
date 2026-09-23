import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/stationery_background.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_modal_sheet.dart';
import '../../domain/wishlist_item_model.dart';
import '../controllers/wishlist_controller.dart';
import '../widgets/price_breakup_card.dart';

/// Screen displaying the user's saved wishlist items in a responsive grid.
///
/// Features:
/// - Guest Guard Intercept: Navigating as a guest automatically triggers [AuthModalBottomSheet].
/// - Real-time synchronized grid view of wishlisted items.
/// - Quick "MOVE TO CART" CTA button with stock validation and immediate transfer.
/// - Remove from wishlist heart action button.
/// - Empty state with "Explore Products" navigation.
class WishlistScreen extends ConsumerStatefulWidget {
  /// Optional callback invoked when a guest is intercepted (for testing or overrides).
  final VoidCallback? onGuestIntercept;

  /// Optional explore products callback.
  final VoidCallback? onExplore;

  const WishlistScreen({
    super.key,
    this.onGuestIntercept,
    this.onExplore,
  });

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGuestIntercept();
    });
  }

  void _checkGuestIntercept() {
    final authState = ref.read(authControllerProvider);
    final bool isGuest = authState.isGuest || authState.user == null;

    if (isGuest) {
      if (widget.onGuestIntercept != null) {
        widget.onGuestIntercept!();
      } else {
        AuthModalBottomSheet.show(context);
      }
    }
  }

  void _handleTriggerAuth() {
    if (widget.onGuestIntercept != null) {
      widget.onGuestIntercept!();
    } else {
      AuthModalBottomSheet.show(context);
    }
  }

  Future<void> _handleMoveToCart(WishlistItemModel item) async {
    if (!item.inStock) return;

    await ref.read(wishlistControllerProvider).moveToCart(item);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.productName}" moved to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.textDark,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppColors.secondaryAmber,
          onPressed: () {
            try {
              context.push('/cart');
            } catch (_) {
              Navigator.of(context).pushNamed('/cart');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final bool isGuest = authState.isGuest || authState.user == null;
    final wishlistItems = ref.watch(wishlistItemsListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        title: Text(
          isGuest || wishlistItems.isEmpty
              ? 'My Wishlist'
              : 'My Wishlist (${wishlistItems.length})',
          style: AppTypography.heading1.copyWith(
            fontSize: 20.0,
            color: AppColors.primaryNavy,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryNavy),
      ),
      body: StationeryBackground(
        child: isGuest
            ? _buildGuestState(context)
            : (wishlistItems.isEmpty
                ? _buildEmptyState(context)
                : _buildWishlistGrid(context, wishlistItems)),
      ),
    );
  }

  /// Guest intercept placeholder shown if auth sheet is dismissed
  Widget _buildGuestState(BuildContext context) {
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
                Icons.favorite_outline_rounded,
                size: 48.0,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Sign In to View Wishlist',
              style: AppTypography.heading1.copyWith(
                fontSize: 22.0,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please sign in to save your favorite school textbooks and uniforms across devices.',
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            CustomButton(
              key: const Key('wishlist_guest_signin_button'),
              text: 'Sign In to Continue',
              isFullWidth: false,
              onPressed: _handleTriggerAuth,
            ),
          ],
        ),
      ),
    );
  }

  /// Empty Wishlist state
  Widget _buildEmptyState(BuildContext context) {
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
                Icons.favorite_border_rounded,
                size: 48.0,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Your Wishlist is Empty',
              style: AppTypography.heading1.copyWith(
                fontSize: 22.0,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Explore our collection and add items you want to save for later.',
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            CustomButton(
              key: const Key('wishlist_empty_explore_button'),
              text: 'Explore Products',
              isFullWidth: false,
              onPressed: () {
                if (widget.onExplore != null) {
                  widget.onExplore!();
                } else {
                  try {
                    context.go('/');
                  } catch (_) {
                    Navigator.of(context).pushNamed('/');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Populated 2-column grid of wishlisted items
  Widget _buildWishlistGrid(
    BuildContext context,
    List<WishlistItemModel> items,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.48,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildWishlistCard(context, item);
      },
    );
  }

  Widget _buildWishlistCard(BuildContext context, WishlistItemModel item) {
    return Container(
      key: Key('wishlist_card_${item.productId}'),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray, width: 1.0),
        boxShadow: AppSpacing.elevationSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Badges
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background & Thumbnail
                item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (ctx, _) => Container(
                          color: AppColors.imagePlaceholder,
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 32.0,
                            color: AppColors.disabledBg,
                          ),
                        ),
                        errorWidget: (ctx, _, __) => Container(
                          color: AppColors.imagePlaceholder,
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 32.0,
                            color: AppColors.disabledBg,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.imagePlaceholder,
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 32.0,
                          color: AppColors.disabledBg,
                        ),
                      ),

                // Discount Pill Tag (Top Left)
                if (item.hasDiscount)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs + 2,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAmber,
                        borderRadius: AppSpacing.roundedMicro,
                      ),
                      child: Text(
                        '${item.discountPercent}% OFF',
                        style: AppTypography.micro.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Remove from Wishlist Heart Button (Top Right)
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('wishlist_remove_${item.productId}'),
                      borderRadius: BorderRadius.circular(20.0),
                      onTap: () {
                        ref
                            .read(wishlistControllerProvider)
                            .removeFromWishlist(item.productId);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: AppSpacing.elevationSm,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 18.0,
                          color: AppColors.destructiveRed,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // School Name
                      if (item.schoolName != null &&
                          item.schoolName!.trim().isNotEmpty) ...[
                        Text(
                          item.schoolName!.trim(),
                          style: AppTypography.micro.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.0),
                      ],

                      // Product Title
                      Text(
                        item.productName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Price Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            PriceBreakupCard.formatCurrency(item.price),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (item.hasDiscount && item.mrp != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              PriceBreakupCard.formatCurrency(item.mrp!),
                              style: AppTypography.micro.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2.0),

                      // Stock status
                      Text(
                        item.inStock ? 'In Stock' : 'Out of Stock',
                        style: AppTypography.micro.copyWith(
                          color: item.inStock
                              ? AppColors.successGreen
                              : AppColors.destructiveRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Move to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 36.0,
                    child: OutlinedButton.icon(
                      key: Key('wishlist_move_to_cart_${item.productId}'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: item.inStock
                              ? AppColors.primaryNavy
                              : AppColors.disabledBg,
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMicro + 2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        backgroundColor: AppColors.surfaceWhite,
                        foregroundColor: item.inStock
                            ? AppColors.primaryNavy
                            : AppColors.disabledText,
                      ),
                      onPressed: item.inStock ? () => _handleMoveToCart(item) : null,
                      icon: Icon(
                        Icons.shopping_bag_outlined,
                        size: 15.0,
                        color: item.inStock
                            ? AppColors.primaryNavy
                            : AppColors.disabledText,
                      ),
                      label: Text(
                        'MOVE TO CART',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: item.inStock
                              ? AppColors.primaryNavy
                              : AppColors.disabledText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
