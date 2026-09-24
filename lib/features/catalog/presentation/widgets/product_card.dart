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
          onTap: () => onTap?.call(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1:1.14 Product Image Section with Top Badges
              AspectRatio(
                aspectRatio: 1.14,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Product Image & Neutral Placeholder
                    Container(
                      color: const Color(0xFFF8FAFC),
                      child: _buildProductImage(),
                    ),

                    // Burgundy / Amber Discount Tag (Top Left)
                    if (product.hasDiscount)
                      Positioned(
                        top: 6.0,
                        left: 6.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9F1239),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '${product.discountPercentage}% OFF',
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
                      child: _buildWishlistButton(context, ref),
                    ),
                  ],
                ),
              ),

              // Product Info & Action Section (Compact Spacing Matching Wishlist)
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title (Bold, 1 line clamp)
                    Text(
                      product.name,
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

                    // School / Grade Subtitle
                    Text(
                      product.schoolName != null &&
                              product.schoolName!.trim().isNotEmpty
                          ? product.schoolName!.trim()
                          : (product.targetGrade != null &&
                                  product.targetGrade!.trim().isNotEmpty
                              ? _formatGrade(product.targetGrade!.trim())
                              : 'All Schools'),
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
                    if (product.schoolName != null &&
                        product.schoolName!.trim().isNotEmpty &&
                        product.targetGrade != null &&
                        product.targetGrade!.trim().isNotEmpty) ...[
                      const SizedBox(height: 1.0),
                      Text(
                        _formatGrade(product.targetGrade!.trim()),
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 9.5,
                          color: Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4.0),

                    // Price Row
                    _buildPriceRow(),
                    const SizedBox(height: 3.0),

                    // Rating + Stock Status Row
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 5-Star Rating
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
                          const SizedBox(width: 8.0),

                          // Stock Status
                          Text(
                            product.inStock
                                ? 'In Stock'
                                : 'Out of stock',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w600,
                              color: product.inStock
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6.0),

                    // CTA Button (H: 30px, Rounded: 15px)
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
      child: InkWell(
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
          child: Center(
            child: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border_rounded,
              size: 15.0,
              color: isWishlisted
                  ? AppColors.destructiveRed
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Bold Effective Price
          Text(
            _formatPrice(product.effectivePrice),
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),

          // MRP Strikethrough if discounted
          if (product.hasDiscount) ...[
            const SizedBox(width: 4.0),
            Text(
              _formatPrice(product.basePrice),
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEF4444),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context, WidgetRef ref) {
    final bool canAddToCart = product.inStock;

    return SizedBox(
      height: 30.0,
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
          backgroundColor: canAddToCart
              ? const Color(0xFFFDE047).withValues(alpha: 0.25)
              : const Color(0xFFF1F5F9),
          side: BorderSide(
            color: canAddToCart
                ? const Color(0xFFEAB308)
                : const Color(0xFFCBD5E1),
            width: 0.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (canAddToCart) ...[
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 13.0,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 4.0),
              ],
              Text(
                canAddToCart ? 'ADD TO CART +' : 'OUT OF STOCK',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: canAddToCart
                      ? AppColors.primaryNavy
                      : AppColors.disabledText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
