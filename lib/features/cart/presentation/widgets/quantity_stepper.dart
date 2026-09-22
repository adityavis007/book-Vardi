import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Atomic quantity stepper widget styled as a 32px capsule pill.
/// Layout: `[-] quantity [+]`
///
/// Features:
/// - Fixed 32px height capsule pill layout conforming to Book Vardi Design System.
/// - Decrementing from 1 triggers a confirmation dialog ("Remove item from cart?").
/// - Increment disabled when `quantity >= maxStock` or `quantity >= skuLimit`.
/// - Haptic feedback on tap interactions.
/// - Built-in loading state with mini spinner for async cart mutations.
class QuantityStepper extends StatelessWidget {
  /// Current quantity value (must be >= 1).
  final int quantity;

  /// Maximum available stock for this variant or product.
  final int maxStock;

  /// Maximum allowed units per SKU constraint (default 5).
  final int skuLimit;

  /// Callback when quantity changes. When removed, emits 0.
  final ValueChanged<int>? onQuantityChanged;

  /// Optional dedicated callback when user confirms removal from dialog.
  final VoidCallback? onRemove;

  /// Optional item title for display in the remove confirmation dialog.
  final String? itemName;

  /// Whether the stepper is in a loading/mutating state.
  final bool isLoading;

  /// Whether the stepper is enabled for user interaction.
  final bool enabled;

  /// Capsule height (defaults to 32px per design specification).
  final double height;

  /// Whether to render a trash/delete icon when quantity is 1.
  final bool showDeleteIconAtOne;

  const QuantityStepper({
    super.key,
    required this.quantity,
    this.maxStock = 99,
    this.skuLimit = 5,
    this.onQuantityChanged,
    this.onRemove,
    this.itemName,
    this.isLoading = false,
    this.enabled = true,
    this.height = 32.0,
    this.showDeleteIconAtOne = true,
  });

  /// The effective maximum allowed quantity considering stock and SKU limit.
  int get effectiveMax {
    final int resolvedStock = maxStock > 0 ? maxStock : 99;
    return resolvedStock < skuLimit ? resolvedStock : skuLimit;
  }

  /// Whether increment action is currently allowed.
  bool get canIncrement => enabled && !isLoading && quantity < effectiveMax;

  /// Whether decrement action is currently allowed.
  bool get canDecrement => enabled && !isLoading;

  /// Displays the confirmation dialog when attempting to decrement from 1.
  static Future<bool?> showRemoveConfirmationDialog(
    BuildContext context, {
    String? itemName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          title: Text(
            'Remove item from cart?',
            style: AppTypography.heading2.copyWith(
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            itemName != null && itemName.trim().isNotEmpty
                ? 'Are you sure you want to remove "$itemName" from your cart?'
                : 'Are you sure you want to remove this item from your cart?',
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              key: const Key('quantity_stepper_dialog_cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              key: const Key('quantity_stepper_dialog_confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Remove',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.destructiveRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleDecrement(BuildContext context) {
    if (!canDecrement) return;

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    if (quantity <= 1) {
      showRemoveConfirmationDialog(
        context,
        itemName: itemName,
      ).then((confirmed) {
        if (confirmed == true) {
          onRemove?.call();
          onQuantityChanged?.call(0);
        }
      });
    } else {
      onQuantityChanged?.call(quantity - 1);
    }
  }

  void _handleIncrement() {
    if (!canIncrement) return;

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    onQuantityChanged?.call(quantity + 1);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAtOne = quantity <= 1;
    final bool isDeleteState = isAtOne && showDeleteIconAtOne;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedFull,
        border: Border.all(
          color: enabled ? AppColors.borderGray : AppColors.disabledBg,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Decrement / Delete Button
          GestureDetector(
            key: const Key('quantity_stepper_decrement'),
            behavior: HitTestBehavior.opaque,
            onTap: canDecrement ? () => _handleDecrement(context) : null,
            child: SizedBox(
              width: height,
              height: height,
              child: Center(
                child: Icon(
                  isDeleteState
                      ? Icons.delete_outline_rounded
                      : Icons.remove_rounded,
                  size: isDeleteState ? 16.0 : 18.0,
                  color: !canDecrement
                      ? AppColors.disabledText
                      : (isDeleteState
                          ? AppColors.destructiveRed
                          : AppColors.primaryNavy),
                ),
              ),
            ),
          ),

          // Quantity Text or Loading Indicator
          Container(
            constraints: BoxConstraints(minWidth: height * 0.85),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 14.0,
                    height: 14.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                    ),
                  )
                : Text(
                    '$quantity',
                    key: const Key('quantity_stepper_value'),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.textDark : AppColors.disabledText,
                    ),
                  ),
          ),

          // Increment Button
          GestureDetector(
            key: const Key('quantity_stepper_increment'),
            behavior: HitTestBehavior.opaque,
            onTap: canIncrement ? _handleIncrement : null,
            child: SizedBox(
              width: height,
              height: height,
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 18.0,
                  color: canIncrement
                      ? AppColors.primaryNavy
                      : AppColors.disabledText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
