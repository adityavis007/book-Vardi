import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/product_model.dart';
import '../../domain/variant_model.dart';

/// Variant Selector Matrix for Uniforms, Shoes, and Textbooks conforming to PRD Section 4.2.
/// Supports Size pills with Size Chart modal, Class/Grade chips, live stock indicators, and haptic feedback.
class VariantSelector extends StatelessWidget {
  final ProductModel product;
  final VariantModel? selectedVariant;
  final ValueChanged<VariantModel> onVariantSelected;
  final VoidCallback? onSizeChartTap;

  const VariantSelector({
    super.key,
    required this.product,
    required this.selectedVariant,
    required this.onVariantSelected,
    this.onSizeChartTap,
  });

  bool get _isBookOrGrade {
    final cat = product.categoryId.toLowerCase();
    final name = product.name.toLowerCase();
    final isBookCategory = cat.contains('book') ||
        cat.contains('textbook') ||
        name.contains('textbook') ||
        name.contains('book');
    final hasClassVariants = product.variants.any(
      (v) =>
          v.label.toLowerCase().contains('class') ||
          v.label.toLowerCase().contains('grade') ||
          v.label.toLowerCase().contains('std'),
    );
    return isBookCategory || hasClassVariants;
  }

  bool get _isUniformOrShoe {
    if (_isBookOrGrade) return false;
    final cat = product.categoryId.toLowerCase();
    final name = product.name.toLowerCase();
    final isApparel = cat.contains('uniform') ||
        cat.contains('shoe') ||
        cat.contains('footwear') ||
        cat.contains('apparel') ||
        cat.contains('clothing') ||
        name.contains('uniform') ||
        name.contains('shoe') ||
        name.contains('shirt') ||
        name.contains('trouser') ||
        name.contains('skirt') ||
        name.contains('blazer');
    final hasNumericSizes = product.variants.any(
      (v) =>
          RegExp(r'^\d+$').hasMatch(v.label.trim()) ||
          v.label.toLowerCase().contains('uk') ||
          v.label.toLowerCase().contains('size') ||
          v.label.toLowerCase() == 'xs' ||
          v.label.toLowerCase() == 's' ||
          v.label.toLowerCase() == 'm' ||
          v.label.toLowerCase() == 'l' ||
          v.label.toLowerCase() == 'xl',
    );
    return isApparel || hasNumericSizes;
  }

  String get _sectionTitle {
    if (_isBookOrGrade) return 'Select Class';
    if (_isUniformOrShoe) return 'Select Size';
    return 'Select Option';
  }

  void _openSizeChart(BuildContext context) {
    if (onSizeChartTap != null) {
      onSizeChartTap!();
      return;
    }
    showSizeChartModal(context, isFootwear: product.categoryId.toLowerCase().contains('shoe'));
  }

  @override
  Widget build(BuildContext context) {
    if (product.variants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Title on Left, Size Chart Link on Right (for Uniforms/Shoes)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _sectionTitle,
              style: AppTypography.heading2.copyWith(
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            if (_isUniformOrShoe)
              InkWell(
                key: const Key('size_chart_button'),
                borderRadius: AppSpacing.roundedSmall,
                onTap: () => _openSizeChart(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Size Chart',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2.0),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 14.0,
                        color: AppColors.primaryNavy,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Variant Pills Wrap Matrix
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: product.variants.map((variant) {
            final isSelected = selectedVariant?.variantId == variant.variantId;
            final inStock = variant.inStock;

            return _VariantPill(
              variant: variant,
              isSelected: isSelected,
              inStock: inStock,
              onTap: () {
                if (!inStock) {
                  // Prevent selecting out-of-stock items as per TASK-029 done criteria
                  return;
                }
                HapticFeedback.lightImpact();
                onVariantSelected(variant);
              },
            );
          }).toList(),
        ),

        // Active SKU & Stock Feedback Row
        if (selectedVariant != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildVariantDetailsRow(selectedVariant!),
        ],
      ],
    );
  }

  Widget _buildVariantDetailsRow(VariantModel variant) {
    final hasSku = variant.sku.isNotEmpty;
    final isLowStock = variant.inStock && variant.stock <= 5;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: 4.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasSku)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2.0,
            ),
            decoration: const BoxDecoration(
              color: AppColors.backgroundSlate,
              borderRadius: AppSpacing.roundedSmall,
            ),
            child: Text(
              'SKU: ${variant.sku}',
              style: AppTypography.micro.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (isLowStock)
          Text(
            'Only ${variant.stock} left in stock!',
            style: AppTypography.caption.copyWith(
              color: AppColors.secondaryAmber,
              fontWeight: FontWeight.w700,
            ),
          )
        else if (variant.inStock)
          Text(
            'In Stock (${variant.stock} units)',
            style: AppTypography.caption.copyWith(
              color: AppColors.successGreen,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Text(
            'Out of Stock',
            style: AppTypography.caption.copyWith(
              color: AppColors.destructiveRed,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// Atomic pill widget for individual variant selection.
class _VariantPill extends StatelessWidget {
  final VariantModel variant;
  final bool isSelected;
  final bool inStock;
  final VoidCallback onTap;

  const _VariantPill({
    required this.variant,
    required this.isSelected,
    required this.inStock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Border border;
    TextStyle textStyle;

    if (!inStock) {
      backgroundColor = AppColors.backgroundSlate.withValues(alpha: 0.6);
      border = Border.all(
        color: AppColors.borderGray.withValues(alpha: 0.6),
        width: 1.0,
      );
      textStyle = AppTypography.bodyMedium.copyWith(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        decoration: TextDecoration.lineThrough,
        decorationColor: AppColors.textMuted,
      );
    } else if (isSelected) {
      backgroundColor = AppColors.categoryPillBg;
      border = Border.all(
        color: AppColors.primaryNavy,
        width: 2.0,
      );
      textStyle = AppTypography.bodyMedium.copyWith(
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryNavy,
      );
    } else {
      backgroundColor = AppColors.surfaceWhite;
      border = Border.all(
        color: AppColors.borderGray,
        width: 1.0,
      );
      textStyle = AppTypography.bodyMedium.copyWith(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );
    }

    return InkWell(
      key: Key('variant_pill_${variant.variantId}'),
      onTap: inStock ? onTap : null,
      borderRadius: AppSpacing.roundedSmall,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 48.0, minHeight: 40.0),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppSpacing.roundedSmall,
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              variant.label,
              style: textStyle,
            ),
            if (!inStock) ...[
              const SizedBox(width: 4.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 1.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.destructiveRed.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Text(
                  'Out',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.destructiveRed,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
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

/// Displays standard Size Chart modal bottom sheet conforming to School Uniform standards.
void showSizeChartModal(BuildContext context, {bool isFootwear = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SizeChartModal(isFootwear: isFootwear),
  );
}

/// Size Chart Modal bottom sheet content.
class SizeChartModal extends StatelessWidget {
  final bool isFootwear;

  const SizeChartModal({
    super.key,
    this.isFootwear = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('size_chart_modal'),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLarge),
          topRight: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal drag handle
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: const BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: AppSpacing.roundedFull,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Modal Header with Title and Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFootwear
                      ? 'Footwear Size Guide'
                      : 'Uniform Sizing Chart',
                  style: AppTypography.heading2.copyWith(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  key: const Key('size_chart_close_button'),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            Text(
              isFootwear
                  ? 'Standard Indian & UK shoe size conversion.'
                  : 'All measurements are in inches. Standard school fit.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Sizing Table
            isFootwear ? _buildFootwearTable() : _buildUniformTable(),

            const SizedBox(height: AppSpacing.lg),

            // Tip Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.secondaryAmber.withValues(alpha: 0.12),
                borderRadius: AppSpacing.roundedSmall,
                border: Border.all(
                  color: AppColors.secondaryAmber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18.0,
                    color: AppColors.secondaryAmber,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Tip: For growing students, selecting one size larger is recommended.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniformTable() {
    const headers = ['Size', 'Chest', 'Waist', 'Length', 'Age Guide'];
    const rows = [
      ['26', '26"', '22"', '18"', '4-5 yrs'],
      ['28', '28"', '24"', '20"', '6-7 yrs'],
      ['30', '30"', '26"', '22"', '8-9 yrs'],
      ['32', '32"', '28"', '24"', '10-11 yrs'],
      ['34', '34"', '30"', '26"', '12-13 yrs'],
      ['36', '36"', '32"', '28"', '14+ yrs'],
    ];

    return _buildTableWidget(headers, rows);
  }

  Widget _buildFootwearTable() {
    const headers = ['Size (IN)', 'UK Size', 'Foot (cm)', 'Age Guide'];
    const rows = [
      ['9C', '9 Kid', '16.5 cm', '4-5 yrs'],
      ['11C', '11 Kid', '18.0 cm', '6-7 yrs'],
      ['13C', '13 Kid', '19.5 cm', '8-9 yrs'],
      ['2', 'UK 2', '21.0 cm', '10-11 yrs'],
      ['4', 'UK 4', '22.5 cm', '12-13 yrs'],
      ['6', 'UK 6', '24.5 cm', '14+ yrs'],
    ];

    return _buildTableWidget(headers, rows);
  }

  Widget _buildTableWidget(List<String> headers, List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.roundedSmall,
        border: Border.all(color: AppColors.borderGray),
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.roundedSmall,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header Row
            TableRow(
              decoration: const BoxDecoration(
                color: AppColors.backgroundSlate,
              ),
              children: headers
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 10.0,
                      ),
                      child: Text(
                        h,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
            ),

            // Data Rows
            ...rows.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              final isEven = idx % 2 == 0;

              return TableRow(
                decoration: BoxDecoration(
                  color: isEven
                      ? AppColors.surfaceWhite
                      : AppColors.backgroundSlate.withValues(alpha: 0.3),
                ),
                children: row
                    .map(
                      (cell) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          cell,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
