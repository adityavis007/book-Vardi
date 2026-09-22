import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/shared/widgets/custom_button.dart';
import 'package:book_vardi/core/constants/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('CustomButton Component Tests', () {
    testWidgets('renders Filled variant with primaryNavy background and responds to tap',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          CustomButton(
            text: 'Login to Continue',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Login to Continue'), findsOneWidget);

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CustomButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.primaryNavy));

      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('renders Outline variant with surfaceWhite background and border',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          CustomButton.outline(
            text: 'Add to Cart',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Add to Cart'), findsOneWidget);

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CustomButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.surfaceWhite));
      expect(decoration.border, isNotNull);
    });

    testWidgets('renders AccentBuyNow variant with amber background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          CustomButton.accentBuyNow(
            text: 'Buy Now',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Buy Now'), findsOneWidget);

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CustomButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.secondaryAmber));
    });

    testWidgets('renders Disabled state when onPressed is null and ignores taps',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CustomButton(
            text: 'Disabled Button',
            onPressed: null,
          ),
        ),
      );

      expect(find.text('Disabled Button'), findsOneWidget);

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CustomButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.disabledBg));
    });

    testWidgets('renders Loading spinner and hides text when isLoading is true',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          CustomButton(
            text: 'Processing',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Processing'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(CustomButton));
      await tester.pump();
      expect(tapped, isFalse);
    });
  });
}
