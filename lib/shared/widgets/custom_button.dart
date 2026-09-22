import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Button visual variants specified in Book Vardi Design System.
enum CustomButtonVariant {
  filled,
  outline,
  accentBuyNow,
}

/// Primary button component supporting Filled, Outline, Accent "Buy Now",
/// Loading states, tactile scale(0.98) feedback, and Haptic feedback.
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CustomButtonVariant.filled,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.icon,
  });

  const CustomButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.icon,
  }) : variant = CustomButtonVariant.outline;

  const CustomButton.accentBuyNow({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.icon,
  }) : variant = CustomButtonVariant.accentBuyNow;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    Color backgroundColor;
    Color textColor;
    Border? border;

    if (isDisabled) {
      backgroundColor = AppColors.disabledBg;
      textColor = AppColors.disabledText;
      border = null;
    } else {
      switch (widget.variant) {
        case CustomButtonVariant.filled:
          backgroundColor = AppColors.primaryNavy;
          textColor = AppColors.surfaceWhite;
          border = null;
          break;
        case CustomButtonVariant.outline:
          backgroundColor = AppColors.surfaceWhite;
          textColor = AppColors.primaryNavy;
          border = Border.all(color: AppColors.primaryNavy, width: 1.5);
          break;
        case CustomButtonVariant.accentBuyNow:
          backgroundColor = AppColors.secondaryAmber;
          textColor = AppColors.textDark;
          border = null;
          break;
      }
    }

    final TextStyle textStyle = AppTypography.bodyMedium.copyWith(
      color: textColor,
      fontWeight: widget.variant == CustomButtonVariant.accentBuyNow
          ? FontWeight.w700
          : FontWeight.w600,
    );

    final Color spinnerColor = widget.variant == CustomButtonVariant.outline
        ? AppColors.primaryNavy
        : (widget.variant == CustomButtonVariant.accentBuyNow
            ? AppColors.textDark
            : AppColors.surfaceWhite);

    final Widget content = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  widget.text,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final Widget buttonBox = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.height,
      width: widget.isFullWidth ? double.infinity : null,
      constraints:
          widget.isFullWidth ? null : const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedSmall,
        border: border,
      ),
      alignment: Alignment.center,
      child: content,
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: isDisabled ? null : _handleTapDown,
        onTapUp: isDisabled ? null : _handleTapUp,
        onTapCancel: isDisabled ? null : _handleTapCancel,
        onTap: isDisabled ? null : _handleTap,
        behavior: HitTestBehavior.opaque,
        child: buttonBox,
      ),
    );
  }
}
