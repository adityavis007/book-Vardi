import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/theme/app_typography.dart';
import 'package:book_vardi/core/constants/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTypography Scale & Token Tests', () {
    test('displayLarge conforms to 32px / 700', () {
      final style = AppTypography.displayLarge;
      expect(style.fontSize, 32.0);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.color, AppColors.textDark);
    });

    test('heading1 conforms to 24px / 700', () {
      final style = AppTypography.heading1;
      expect(style.fontSize, 24.0);
      expect(style.fontWeight, FontWeight.w700);
    });

    test('heading2 conforms to 18px / 600', () {
      final style = AppTypography.heading2;
      expect(style.fontSize, 18.0);
      expect(style.fontWeight, FontWeight.w600);
    });

    test('bodyRegular conforms to 14px / 400', () {
      final style = AppTypography.bodyRegular;
      expect(style.fontSize, 14.0);
      expect(style.fontWeight, FontWeight.w400);
    });

    test('bodyMedium conforms to 14px / 500', () {
      final style = AppTypography.bodyMedium;
      expect(style.fontSize, 14.0);
      expect(style.fontWeight, FontWeight.w500);
    });

    test('caption conforms to 12px / 500 with textSecondary color', () {
      final style = AppTypography.caption;
      expect(style.fontSize, 12.0);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, AppColors.textSecondary);
    });

    test('micro conforms to 10px / 400 with textSecondary color', () {
      final style = AppTypography.micro;
      expect(style.fontSize, 10.0);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, AppColors.textSecondary);
    });

    test('textTheme contains properly mapped styles', () {
      final textTheme = AppTypography.textTheme;
      expect(textTheme.displayLarge?.fontSize, 32.0);
      expect(textTheme.headlineLarge?.fontSize, 24.0);
      expect(textTheme.headlineMedium?.fontSize, 18.0);
      expect(textTheme.bodyMedium?.fontSize, 14.0);
      expect(textTheme.bodySmall?.fontSize, 12.0);
      expect(textTheme.labelSmall?.fontSize, 10.0);
    });
  });
}
