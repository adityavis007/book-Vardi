import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Base shimmer container providing the 1200ms pulse animation with #E2E8F0 to #F1F5F9 gradient.
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Duration period;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: period,
      child: child,
    );
  }
}

/// Generic rectangular or rounded placeholder box.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppSpacing.roundedSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Preset for a list tile placeholder (thumbnail + 2 title lines).
class ShimmerTile extends StatelessWidget {
  final double thumbnailSize;

  const ShimmerTile({
    super.key,
    this.thumbnailSize = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShimmerBox(
            width: thumbnailSize,
            height: thumbnailSize,
            borderRadius: AppSpacing.roundedSmall,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShimmerBox(
                  width: double.infinity,
                  height: 14.0,
                  borderRadius: AppSpacing.roundedMicro,
                ),
                const SizedBox(height: AppSpacing.sm),
                ShimmerBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 12.0,
                  borderRadius: AppSpacing.roundedMicro,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Preset for the 1:1 image product grid card placeholder.
class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppSpacing.roundedMedium,
          border: Border.all(color: AppColors.borderGray, width: 1),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1:1 image placeholder
            AspectRatio(
              aspectRatio: 1.0,
              child: ShimmerBox(
                borderRadius: AppSpacing.roundedSmall,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            // School name metadata
            ShimmerBox(
              width: 80,
              height: 10,
              borderRadius: AppSpacing.roundedMicro,
            ),
            SizedBox(height: AppSpacing.xs),
            // Product title
            ShimmerBox(
              width: double.infinity,
              height: 14,
              borderRadius: AppSpacing.roundedMicro,
            ),
            SizedBox(height: AppSpacing.sm),
            // Price tag
            ShimmerBox(
              width: 60,
              height: 16,
              borderRadius: AppSpacing.roundedMicro,
            ),
            SizedBox(height: AppSpacing.sm),
            // Outlined Add to Cart button skeleton
            ShimmerBox(
              width: double.infinity,
              height: 36,
              borderRadius: AppSpacing.roundedSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Preset for 16:9 Hero Promotional Carousel Banner.
class ShimmerBanner extends StatelessWidget {
  final double aspectRatio;

  const ShimmerBanner({
    super.key,
    this.aspectRatio = 16 / 9,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: const ShimmerBox(
          width: double.infinity,
          borderRadius: AppSpacing.roundedMedium,
        ),
      ),
    );
  }
}

/// Preset for 60x60 circular Category Quick Rail items.
class ShimmerCategoryItem extends StatelessWidget {
  const ShimmerCategoryItem({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerBox(
            width: 60,
            height: 60,
            borderRadius: AppSpacing.roundedFull,
          ),
          SizedBox(height: AppSpacing.xs),
          ShimmerBox(
            width: 48,
            height: 10,
            borderRadius: AppSpacing.roundedMicro,
          ),
        ],
      ),
    );
  }
}
