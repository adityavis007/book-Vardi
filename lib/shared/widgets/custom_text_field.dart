import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Form text field component conforming to Book Vardi design specifications:
/// 48px height, 8px radius, password eye-toggle, and WCAG AA compliant styling.
class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? prefixText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool isPassword;
  final bool autofocus;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.prefixText,
    this.controller,
    this.initialValue,
    this.isPassword = false,
    this.autofocus = false,
    this.maxLength,
    this.inputFormatters,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          enabled: widget.enabled,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: AppTypography.bodyRegular.copyWith(
            color: widget.enabled ? AppColors.textDark : AppColors.disabledText,
          ),
          decoration: InputDecoration(
            counterText: '',
            prefixText: widget.prefixText,
            prefixStyle: AppTypography.bodyRegular.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
            hintText: widget.hintText,
            helperText: widget.helperText,
            hintStyle: AppTypography.bodyRegular.copyWith(
              color: AppColors.textMuted,
            ),
            helperStyle: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            errorStyle: AppTypography.caption.copyWith(
              color: AppColors.destructiveRed,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon,
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surfaceWhite
                : AppColors.imagePlaceholder,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            isDense: true,
            border: const OutlineInputBorder(
              borderRadius: AppSpacing.roundedSmall,
              borderSide: BorderSide(color: AppColors.borderGray, width: 1.0),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppSpacing.roundedSmall,
              borderSide: BorderSide(color: AppColors.borderGray, width: 1.0),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppSpacing.roundedSmall,
              borderSide: BorderSide(color: AppColors.primaryNavy, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppSpacing.roundedSmall,
              borderSide: BorderSide(color: AppColors.destructiveRed, width: 1.0),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppSpacing.roundedSmall,
              borderSide: BorderSide(color: AppColors.destructiveRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
