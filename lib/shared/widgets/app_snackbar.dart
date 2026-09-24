import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

/// Reusable modern floating snackbar/toast matching Book Vardi website UI aesthetics.
class AppSnackBar {
  const AppSnackBar._();

  static void showCartSnackBar(
    BuildContext context, {
    required String productTitle,
    String message = 'Added to cart successfully',
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Color(0xFF334155), width: 0.8),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: AppColors.secondaryAmber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.secondaryAmber,
                size: 16.0,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            GestureDetector(
              key: const Key('snackbar_view_cart_btn'),
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                try {
                  context.push('/cart');
                } catch (_) {
                  Navigator.of(context).pushNamed('/cart');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryAmber,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VIEW CART',
                      style: TextStyle(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.0,
                      ),
                    ),
                    SizedBox(width: 3.0),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primaryNavy,
                      size: 12.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showWishlistSnackBar(
    BuildContext context, {
    required String productTitle,
    required bool isAdded,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Color(0xFF334155), width: 0.8),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: isAdded
                    ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                    : const Color(0xFF94A3B8).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                isAdded ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isAdded ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                size: 16.0,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isAdded ? 'Added to wishlist' : 'Removed from wishlist',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isAdded) ...[
              const SizedBox(width: 8.0),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  try {
                    context.push('/wishlist');
                  } catch (_) {
                    Navigator.of(context).pushNamed('/wishlist');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'WISHLIST',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.0,
                        ),
                      ),
                      SizedBox(width: 3.0),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 12.0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
