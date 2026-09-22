import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/theme/app_theme.dart';
import 'package:book_vardi/core/constants/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookVardiTheme Configuration Tests', () {
    test('themeData is created with useMaterial3 and correct primary colors', () {
      final theme = BookVardiTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, equals(AppColors.backgroundSlate));
      expect(theme.colorScheme.primary, equals(AppColors.primaryNavy));
      expect(theme.colorScheme.secondary, equals(AppColors.secondaryAmber));
      expect(theme.colorScheme.surface, equals(AppColors.surfaceWhite));
      expect(theme.colorScheme.outlineVariant, equals(AppColors.borderGray));
    });

    testWidgets('MaterialApp with BookVardiTheme renders scaffold background as #F8FAFC',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BookVardiTheme.lightTheme,
          home: const Scaffold(
            body: Center(child: Text('Book Vardi Theme Test')),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final context = tester.element(find.text('Book Vardi Theme Test'));
      final theme = Theme.of(context);

      expect(scaffold.backgroundColor ?? theme.scaffoldBackgroundColor,
          equals(const Color(0xFFF8FAFC)));
    });

    testWidgets('ElevatedButton inherits primaryNavy styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BookVardiTheme.lightTheme,
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Button'),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final context = tester.element(find.text('Button'));
      final theme = Theme.of(context);

      final style = button.style ?? theme.elevatedButtonTheme.style;
      final backgroundColor = style?.backgroundColor?.resolve({});
      expect(backgroundColor, equals(AppColors.primaryNavy));
    });
  });
}
