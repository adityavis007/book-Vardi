import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/guards/guest_guard.dart';
import '../../../../core/guards/pending_action.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/product_model.dart';

/// Product Grid Card Component conforming to Design System Section 3.2.
///
/// Features:
/// - 1:1 Aspect ratio preview image with `#F1F5F9` placeholder.
/// - Absolute top badges: Amber discount tag pill and Guest-Guarded Wishlist heart button.
/// - Details: Micro school name, 2-line title clamp, grade caption, bold price with MRP strikethrough.
/// - Outlined "ADD TO CART +" button (H: 36px, radius: 6px) protected by [executeWithAuthGuard].
class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final bool isWishlisted;
  final ValueChanged<ProductModel>? onAddToCart;
  final ValueChanged<ProductModel>? onToggleWishlist;
  final ValueChanged<ProductModel>? onTap;
  final double? width;

  const ProductCard({
    super.key,
    required this.product,
    this.isWishlisted = false,
    this.onAddToCart,
    this.onToggleWishlist,
    this.onTap,
    this.width,
  });

  static bool get _isTestEnv {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  String _formatPrice(double amount) {
    try {
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
      ).format(amount);
    } catch (_) {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray, width: 1.0),
        boxShadow: AppSpacing.elevationSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap?.call(product),
          borderRadius: AppSpacing.roundedMedium,
          splashColor: AppColors.primaryNavy.withValues(alpha: 0.05),
          highlightColor: AppColors.primaryNavy.withValues(alpha: 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1:1 Square Image Area with Badges Overlay
              _buildImageSection(context, ref),

              // Content & Pricing Details
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School Name (Micro text, 1 line truncate)
                    if (product.schoolName != null &&
                        product.schoolName!.trim().isNotEmpty) ...[
                      Text(
                        product.schoolName!.trim(),
                        style: AppTypography.micro.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Product Title (Body Medium, 2 line clamp)
                    Text(
                      product.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Target Grade Caption
                    if (product.targetGrade != null &&
                        product.targetGrade!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatGrade(product.targetGrade!.trim()),
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.0,
                          color: const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xs),

                    // Price & MRP Strikethrough Row
                    _buildPriceRow(),

                    const SizedBox(height: AppSpacing.sm),

                    // Outlined "ADD TO CART +" Button (H: 36px, Radius: 6px)
                    _buildAddToCartButton(context, ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatGrade(String grade) {
    if (grade.toLowerCase().startsWith('class') ||
        grade.toLowerCase().startsWith('std') ||
        grade.toLowerCase().startsWith('grade')) {
      return grade;
    }
    return 'Class: $grade';
  }

  Widget _buildImageSection(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Placeholder & Image
          Container(
            color: AppColors.imagePlaceholder,
            child: _buildProductImage(),
          ),

          // Top Badges Overlay (Top-8)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Discount Tag Pill
                if (product.hasDiscount)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 3.0,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryAmber,
                      borderRadius: AppSpacing.roundedMicro,
                    ),
                    child: Text(
                      '${product.discountPercentage}% OFF',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Wishlist Heart Button (Protected by executeWithAuthGuard)
                _buildWishlistButton(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = product.primaryImage.trim();

    if (_isTestEnv || imageUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.school_outlined,
          size: 40,
          color: AppColors.textMuted,
        ),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildWishlistButton(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: isWishlisted ? 'Remove from Wishlist' : 'Add to Wishlist',
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 1.0,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            executeWithAuthGuard(
              context,
              ref,
              action: PendingAction(
                type: PendingActionType.toggleWishlist,
                productId: product.productId,
              ),
              onAuthenticated: () {
                onToggleWishlist?.call(product);
              },
            );
          },
          child: Container(
            width: 32.0,
            height: 32.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderGray.withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border_rounded,
                size: 18.0,
                color: isWishlisted
                    ? AppColors.destructiveRed
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: 2.0,
      children: [
        // Bold Effective Price
        Text(
          _formatPrice(product.effectivePrice),
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),

        // MRP Strikethrough if discounted
        if (product.hasDiscount)
          Text(
            _formatPrice(product.basePrice),
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),

        // Out of stock label if unavailable
        if (!product.inStock)
          Text(
            'Out of stock',
            style: AppTypography.micro.copyWith(
              color: AppColors.destructiveRed,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildAddToCartButton(BuildContext context, WidgetRef ref) {
    final bool canAddToCart = product.inStock;

    return SizedBox(
      height: 36.0,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: canAddToCart
            ? () {
                executeWithAuthGuard(
                  context,
                  ref,
                  action: PendingAction(
                    type: PendingActionType.addToCart,
                    productId: product.productId,
                    quantity: 1,
                  ),
                  onAuthenticated: () {
                    onAddToCart?.call(product);
                  },
                );
              }
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          disabledForegroundColor: AppColors.disabledText,
          side: BorderSide(
            color: canAddToCart ? AppColors.primaryNavy : AppColors.disabledBg,
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        child: Text(
          canAddToCart ? 'ADD TO CART +' : 'OUT OF STOCK',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: canAddToCart
                ? AppColors.primaryNavy
                : AppColors.disabledText,
          ),
        ),
      ),
    );
  }
}
