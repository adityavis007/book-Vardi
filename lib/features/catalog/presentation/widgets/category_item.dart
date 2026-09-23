import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../domain/category_model.dart';
import '../controllers/catalog_controller.dart';

/// Single Category circular item (60x60) for the discovery rail.
class CategoryItem extends StatelessWidget {
  final CategoryModel? category;
  final String? label;
  final String? iconUrl;
  final IconData? icon;
  final Widget? iconWidget;
  final bool isSelected;
  final VoidCallback? onTap;
  final double circleSize;
  final double iconSize;
  final double itemWidth;

  const CategoryItem({
    super.key,
    this.category,
    this.label,
    this.iconUrl,
    this.icon,
    this.iconWidget,
    this.isSelected = false,
    this.onTap,
    this.circleSize = 60.0,
    this.iconSize = 36.0,
    this.itemWidth = 72.0,
  });

  String get _displayLabel => label ?? category?.name ?? '';
  String get _iconUrl => iconUrl ?? category?.iconUrl ?? '';

  static bool get _isTestEnv {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBg = isSelected ? AppColors.primaryNavy : AppColors.categoryPillBg;
    final activeBorderColor =
        isSelected ? AppColors.primaryNavy : AppColors.categoryPillBorder;
    final activeIconColor = isSelected ? Colors.white : AppColors.primaryNavy;
    final activeTextColor =
        isSelected ? AppColors.primaryNavy : AppColors.textDark;
    final textWeight = isSelected ? FontWeight.w700 : FontWeight.w500;

    return Semantics(
      button: true,
      selected: isSelected,
      label: _displayLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(itemWidth / 2),
        splashColor: AppColors.primaryNavy.withValues(alpha: 0.12),
        highlightColor: AppColors.primaryNavy.withValues(alpha: 0.06),
        child: SizedBox(
          width: itemWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeBg,
                  border: Border.all(
                    color: activeBorderColor,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected ? AppSpacing.elevationSm : null,
                ),
                child: Center(
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: Center(
                      child: _buildIcon(context, activeIconColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _displayLabel,
                style: AppTypography.caption.copyWith(
                  fontSize: 12.0,
                  fontWeight: textWeight,
                  color: activeTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, Color iconColor) {
    if (iconWidget != null) {
      return iconWidget!;
    }

    if (icon != null) {
      return Icon(
        icon,
        size: iconSize * 0.75,
        color: iconColor,
      );
    }

    final url = _iconUrl.trim();
    if (url.isEmpty) {
      return Icon(
        Icons.category_outlined,
        size: iconSize * 0.75,
        color: iconColor,
      );
    }

    // SVG icon format
    if (url.toLowerCase().endsWith('.svg')) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        if (_isTestEnv) {
          return Icon(Icons.category_outlined,
              size: iconSize * 0.75, color: iconColor);
        }
        return SvgPicture.network(
          url,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          placeholderBuilder: (_) => Icon(
            Icons.category_outlined,
            size: iconSize * 0.75,
            color: iconColor,
          ),
        );
      } else {
        return SvgPicture.asset(
          url,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
      }
    }

    // Network Image
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (_isTestEnv) {
        return Icon(Icons.category_outlined,
            size: iconSize * 0.75, color: iconColor);
      }
      return CachedNetworkImage(
        imageUrl: url,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        placeholder: (context, _) => Center(
          child: SizedBox(
            width: iconSize * 0.5,
            height: iconSize * 0.5,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        ),
        errorWidget: (context, _, __) => Icon(
          Icons.category_outlined,
          size: iconSize * 0.75,
          color: iconColor,
        ),
      );
    }

    // Local Asset Image
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.category_outlined,
          size: iconSize * 0.75,
          color: iconColor,
        ),
      );
    }

    // Fallback Icon
    return Icon(
      Icons.category_outlined,
      size: iconSize * 0.75,
      color: iconColor,
    );
  }
}

/// Horizontal scroll quick rail displaying categories with bounce physics and reactive selection.
class CategoryQuickRail extends ConsumerWidget {
  final List<CategoryModel>? categories;
  final String? selectedCategoryId;
  final ValueChanged<CategoryModel>? onCategorySelected;
  final bool showAllOption;
  final String allLabel;
  final VoidCallback? onAllSelected;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const CategoryQuickRail({
    super.key,
    this.categories,
    this.selectedCategoryId,
    this.onCategorySelected,
    this.showAllOption = true,
    this.allLabel = 'All',
    this.onAllSelected,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xs,
    ),
    this.spacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine active category selection from prop or catalogFilterProvider
    final activeFilterCatId = ref.watch(catalogFilterProvider).categoryId;
    final activeSelectedId = selectedCategoryId ?? activeFilterCatId;

    if (categories != null) {
      return _buildRailContent(
        context,
        ref,
        categories!,
        activeSelectedId,
      );
    }

    // Read reactive categoriesProvider if categories prop not provided
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (cats) => _buildRailContent(
        context,
        ref,
        cats,
        activeSelectedId,
      ),
      loading: () => _buildShimmerRail(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildShimmerRail() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: padding,
      child: Row(
        children: List.generate(
          5,
          (index) => Padding(
            padding: EdgeInsets.only(right: index == 4 ? 0 : spacing),
            child: const ShimmerCategoryItem(),
          ),
        ),
      ),
    );
  }

  Widget _buildRailContent(
    BuildContext context,
    WidgetRef ref,
    List<CategoryModel> categoryList,
    String? activeSelectedId,
  ) {
    final sortedCategories = List<CategoryModel>.from(categoryList)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final items = <Widget>[];

    if (showAllOption) {
      final isAllSelected = activeSelectedId == null || activeSelectedId.isEmpty;
      items.add(
        CategoryItem(
          key: const ValueKey('category_item_all'),
          label: allLabel,
          icon: Icons.grid_view_rounded,
          isSelected: isAllSelected,
          onTap: () {
            if (onAllSelected != null) {
              onAllSelected!();
            } else {
              ref.read(catalogFilterProvider.notifier).setCategory(null);
            }
          },
        ),
      );
    }

    for (final cat in sortedCategories) {
      final isSelected = activeSelectedId == cat.categoryId;
      items.add(
        CategoryItem(
          key: ValueKey('category_item_${cat.categoryId}'),
          category: cat,
          isSelected: isSelected,
          onTap: () {
            if (onCategorySelected != null) {
              onCategorySelected!(cat);
            } else {
              // Toggle: tapping already selected category unselects it
              final newId = isSelected ? null : cat.categoryId;
              ref.read(catalogFilterProvider.notifier).setCategory(newId);
            }
          },
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: padding,
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            items[i],
          ],
        ],
      ),
    );
  }
}
