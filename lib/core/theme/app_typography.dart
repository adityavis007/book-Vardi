import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Typography definitions based on the 1.25 Major Third scale using Plus Jakarta Sans.
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Plus Jakarta Sans';

  static bool get _isTestEnv {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  /// Base text style utilizing GoogleFonts.plusJakartaSans
  static TextStyle _baseStyle({
    required double fontSize,
    required FontWeight fontWeight,
    double height = 1.3,
    Color color = AppColors.textDark,
    double? letterSpacing,
  }) {
    if (_isTestEnv) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
        letterSpacing: letterSpacing,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Display Large: 32px / 700 ── Home Hero Banner Headings
  static TextStyle get displayLarge => _baseStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  /// Heading 1: 24px / 700 ── Screen Titles (PDP Title, Cart Header)
  static TextStyle get heading1 => _baseStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  /// Heading 2: 18px / 600 ── Section Titles ("Featured Categories", "Bundles")
  static TextStyle get heading2 => _baseStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  /// Body Regular: 14px / 400 ── Descriptions, Input Fields, Specifications
  static TextStyle get bodyRegular => _baseStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  /// Body Medium: 14px / 500 ── Buttons, Table Headers, Filter Labels
  static TextStyle get bodyMedium => _baseStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  /// Caption: 12px / 500 ── Badges, Variant Labels, Delivery Estimates
  static TextStyle get caption => _baseStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppColors.textSecondary,
      );

  /// Micro: 10px / 400 ── Footnotes, SKU Numbers, Timestamps
  static TextStyle get micro => _baseStyle(
        fontSize: 10.0,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AppColors.textSecondary,
      );

  /// Flutter ThemeData TextTheme assembly
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        headlineLarge: heading1,
        headlineMedium: heading2,
        titleMedium: bodyMedium,
        bodyLarge: bodyMedium,
        bodyMedium: bodyRegular,
        bodySmall: caption,
        labelSmall: micro,
      );
}
