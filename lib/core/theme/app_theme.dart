import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_typography.dart';

/// Central theme system configuration for Book Vardi.
class BookVardiTheme {
  const BookVardiTheme._();

  static ThemeData get lightTheme {
    final textTheme = AppTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundSlate,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryNavy,
        onPrimary: AppColors.surfaceWhite,
        primaryContainer: AppColors.primaryNavyHover,
        secondary: AppColors.secondaryAmber,
        onSecondary: AppColors.textDark,
        surface: AppColors.surfaceWhite,
        onSurface: AppColors.textDark,
        onSurfaceVariant: AppColors.textSecondary,
        outlineVariant: AppColors.borderGray,
        error: AppColors.destructiveRed,
        onError: AppColors.surfaceWhite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTypography.heading2.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryNavy),
        actionsIconTheme: const IconThemeData(color: AppColors.primaryNavy),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: AppColors.surfaceWhite,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size(64, 48),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedSmall,
          ),
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          backgroundColor: AppColors.surfaceWhite,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedSmall,
          ),
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMedium,
          side: BorderSide(color: AppColors.borderGray, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderGray,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyRegular.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.bodyRegular.copyWith(color: AppColors.textSecondary),
        border: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSmall,
          borderSide: BorderSide(color: AppColors.borderGray, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSmall,
          borderSide: BorderSide(color: AppColors.borderGray, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSmall,
          borderSide: BorderSide(color: AppColors.primaryNavy, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSmall,
          borderSide: BorderSide(color: AppColors.destructiveRed, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSmall,
          borderSide: BorderSide(color: AppColors.destructiveRed, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primaryNavy,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        contentTextStyle: TextStyle(color: AppColors.surfaceWhite),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedSmall,
        ),
      ),
    );
  }
}
