import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/constants/app_colors.dart';
import 'package:book_vardi/core/constants/app_spacing.dart';

void main() {
  group('Design Tokens - AppColors Specification Tests', () {
    test('brand colors match exact hex values', () {
      expect(AppColors.primaryNavy, equals(const Color(0xFF142921)));
      expect(AppColors.primaryNavyHover, equals(const Color(0xFF1D3B30)));
      expect(AppColors.secondaryAmber, equals(const Color(0xFFFBBF24)));
    });

    test('surface and background colors match exact hex values', () {
      expect(AppColors.backgroundSlate, equals(const Color(0xFFF8FAFC)));
      expect(AppColors.surfaceWhite, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.borderGray, equals(const Color(0xFFE2E8F0)));
      expect(AppColors.imagePlaceholder, equals(const Color(0xFFF1F5F9)));
      expect(AppColors.categoryPillBg, equals(const Color(0xFFF0FDF4)));
      expect(AppColors.categoryPillBorder, equals(const Color(0xFFDCFCE7)));
    });

    test('text colors match exact hex values', () {
      expect(AppColors.textDark, equals(const Color(0xFF0F172A)));
      expect(AppColors.textSecondary, equals(const Color(0xFF64748B)));
      expect(AppColors.textMuted, equals(const Color(0xFF94A3B8)));
    });

    test('semantic status colors match exact hex values', () {
      expect(AppColors.successGreen, equals(const Color(0xFF10B981)));
      expect(AppColors.destructiveRed, equals(const Color(0xFFEF4444)));
      expect(AppColors.disabledBg, equals(const Color(0xFFCBD5E1)));
    });
  });

  group('Design Tokens - AppSpacing Specification Tests', () {
    test('4px base grid units adhere to scale', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.xxl, 32.0);
      expect(AppSpacing.xxxl, 48.0);
    });

    test('corner radii match design specifications', () {
      expect(AppSpacing.radiusMicro, 4.0);
      expect(AppSpacing.radiusSmall, 8.0);
      expect(AppSpacing.radiusMedium, 12.0);
      expect(AppSpacing.radiusLarge, 20.0);
      expect(AppSpacing.radiusFull, 9999.0);
    });

    test('sheetRadius applies only to top corners', () {
      expect(AppSpacing.sheetRadius.topLeft, const Radius.circular(20.0));
      expect(AppSpacing.sheetRadius.topRight, const Radius.circular(20.0));
      expect(AppSpacing.sheetRadius.bottomLeft, Radius.zero);
      expect(AppSpacing.sheetRadius.bottomRight, Radius.zero);
    });
  });
}
