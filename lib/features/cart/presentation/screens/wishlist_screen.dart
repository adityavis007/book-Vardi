import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_snackbar.dart';
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
    AppSnackBar.showCartSnackBar(
      context,
      productTitle: item.productName,
      message: 'Moved to cart successfully',
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
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              key: const Key('wishlist_back_button'),
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
            Flexible(
              child: Text(
                'My Wishlist',
                style: AppTypography.heading1.copyWith(
                  fontSize: 17.0,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6.0),
            if (!isGuest && wishlistItems.isNotEmpty)
              Container(
                width: 22.0,
                height: 22.0,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryAmberDark,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${wishlistItems.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth >= 600;
        final crossAxisCount = isTablet ? (screenWidth >= 900 ? 4 : 3) : 2;
        final childAspectRatio = isTablet ? 0.68 : 0.59;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 12.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildWishlistCard(context, item);
          },
        );
      },
    );
  }

  Widget _buildWishlistCard(BuildContext context, WishlistItemModel item) {
    return Container(
      key: Key('wishlist_card_${item.productId}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            try {
              context.push('/product/${item.productId}');
            } catch (_) {
              Navigator.of(context).pushNamed('/product/${item.productId}');
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1:1.15 Product Image Section with Top Badges
              AspectRatio(
                aspectRatio: 1.14,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Product Image & Neutral Placeholder
                    Container(
                      color: const Color(0xFFF8FAFC),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (ctx, _) => const Center(
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 28.0,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              errorWidget: (ctx, _, __) => const Center(
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 28.0,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.menu_book_rounded,
                                size: 28.0,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                    ),

                    // Website Style Raspberry / Burgundy Discount Tag (Top Left)
                    if (item.hasDiscount)
                      Positioned(
                        top: 6.0,
                        left: 6.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9F1239), // Raspberry/Burgundy 17% OFF tag
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '${item.discountPercent}% OFF',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                    // Circular White Heart Button (Top Right)
                    Positioned(
                      top: 6.0,
                      right: 6.0,
                      child: InkWell(
                        key: Key('wishlist_remove_${item.productId}'),
                        onTap: () {
                          ref
                              .read(wishlistControllerProvider)
                              .removeFromWishlist(item.productId);
                        },
                        borderRadius: BorderRadius.circular(14.0),
                        child: Container(
                          width: 28.0,
                          height: 28.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.95),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4.0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 15.0,
                              color: Color(0xFFEF4444), // Active Wishlist Red
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info & Action Section (Compact Spacing Matching Web)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Title (Bold, 1 line clamp)
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),

                          // School / Product Subtitle
                          Text(
                            item.schoolName != null &&
                                    item.schoolName!.trim().isNotEmpty
                                ? item.schoolName!.trim()
                                : 'Premium quality school uniform & educational product.',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),

                          // Price Row (Full Width)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                PriceBreakupCard.formatCurrency(item.price),
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (item.hasDiscount && item.mrp != null) ...[
                                const SizedBox(width: 4.0),
                                Text(
                                  PriceBreakupCard.formatCurrency(item.mrp!),
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.lineThrough,
                                    color: Color(0xFFEF4444), // Red MRP strikethrough as on web
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3.0),

                          // Rating + Stock Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 5-Star Rating (4.0 as on website)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...List.generate(5, (starIdx) {
                                    final bool isFilled = starIdx < 4;
                                    return Icon(
                                      isFilled
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 10.5,
                                      color: isFilled
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFFCBD5E1),
                                    );
                                  }),
                                  const SizedBox(width: 2.0),
                                  const Text(
                                    '4.0',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),

                              // Stock Status
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    item.inStock ? 'In Stock' : 'Out of Stock',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w600,
                                      color: item.inStock
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Amber CTA Button Matching Web "Move to Cart"
                      SizedBox(
                        width: double.infinity,
                        height: 30.0,
                        child: ElevatedButton(
                          key: Key('wishlist_move_to_cart_${item.productId}'),
                          onPressed: item.inStock ? () => _handleMoveToCart(item) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: item.inStock
                                ? const Color(0xFFFDE047) // Soft Vibrant Amber #FDE047
                                : const Color(0xFFE2E8F0),
                            foregroundColor: const Color(0xFF0F172A),
                            disabledBackgroundColor: const Color(0xFFE2E8F0),
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              side: BorderSide(
                                color: item.inStock
                                    ? const Color(0xFFEAB308)
                                    : const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 13.0,
                                  color: item.inStock
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  'MOVE TO CART',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: item.inStock
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF94A3B8),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
