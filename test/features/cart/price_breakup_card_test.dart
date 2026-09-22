import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';
import 'package:book_vardi/features/cart/presentation/widgets/price_breakup_card.dart';
import 'package:book_vardi/core/constants/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }

  group('PriceBreakupCard Component Tests', () {
    testWidgets('renders all core rows and formats currency with free shipping',
        (WidgetTester tester) async {
      const priceBreakup = PriceBreakupModel(
        subtotal: 1250.0,
        schoolBulkDiscount: 0.0,
        couponDiscount: 0.0,
        deliveryCharge: 0.0,
        grandTotal: 1250.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const PriceBreakupCard(priceBreakup: priceBreakup),
        ),
      );

      expect(find.byKey(const Key('price_breakup_card')), findsOneWidget);
      expect(find.text('Price Details'), findsOneWidget);
      expect(find.text('Items Total'), findsOneWidget);

      // Verify Subtotal formatted
      expect(find.byKey(const Key('price_breakup_subtotal_value')), findsOneWidget);
      expect(find.text('₹1,250'), findsNWidgets(2)); // Subtotal & Total Payable

      // Free shipping tag present
      expect(find.byKey(const Key('price_breakup_free_shipping_tag')), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);

      // Total Payable in 18px Bold
      final grandTotalText = tester.widget<Text>(
        find.byKey(const Key('price_breakup_grand_total_value')),
      );
      expect(grandTotalText.style?.fontSize, equals(18.0));
      expect(grandTotalText.style?.fontWeight, equals(FontWeight.w700));

      // Savings banner for free shipping
      expect(find.byKey(const Key('price_breakup_savings_banner')), findsOneWidget);
      expect(find.text('You will save ₹50 on this order'), findsOneWidget);
    });

    testWidgets('renders school bulk discount and coupon discount lines with green text',
        (WidgetTester tester) async {
      const priceBreakup = PriceBreakupModel(
        subtotal: 2000.0,
        schoolBulkDiscount: 200.0,
        couponDiscount: 100.0,
        deliveryCharge: 0.0,
        grandTotal: 1700.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const PriceBreakupCard(
            priceBreakup: priceBreakup,
            appliedCouponCode: 'BOOK100',
          ),
        ),
      );

      // Bulk discount
      expect(find.text('School Bulk Discount'), findsOneWidget);
      expect(find.byKey(const Key('price_breakup_bulk_discount_value')), findsOneWidget);
      final bulkText = tester.widget<Text>(
        find.byKey(const Key('price_breakup_bulk_discount_value')),
      );
      expect(bulkText.style?.color, equals(AppColors.successGreen));

      // Coupon discount
      expect(find.text('Coupon Discount (BOOK100)'), findsOneWidget);
      expect(find.byKey(const Key('price_breakup_coupon_discount_value')), findsOneWidget);
      final couponText = tester.widget<Text>(
        find.byKey(const Key('price_breakup_coupon_discount_value')),
      );
      expect(couponText.style?.color, equals(AppColors.successGreen));

      // Total Payable = ₹1,700
      expect(find.text('₹1,700'), findsOneWidget);

      // Total savings: 200 (bulk) + 100 (coupon) + 50 (free delivery) = 350
      expect(find.text('You will save ₹350 on this order'), findsOneWidget);
    });

    testWidgets('renders paid shipping and free delivery threshold incentive pill',
        (WidgetTester tester) async {
      const priceBreakup = PriceBreakupModel(
        subtotal: 600.0,
        schoolBulkDiscount: 0.0,
        couponDiscount: 0.0,
        deliveryCharge: 50.0,
        grandTotal: 650.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const PriceBreakupCard(priceBreakup: priceBreakup),
        ),
      );

      // Shipping shows ₹50
      expect(find.byKey(const Key('price_breakup_shipping_value')), findsOneWidget);
      expect(find.text('₹50'), findsOneWidget);

      // Free shipping incentive: 999 - 600 = 399
      expect(find.text('Add ₹399 more for FREE Delivery'), findsOneWidget);

      // Total Payable = ₹650
      expect(find.text('₹650'), findsOneWidget);
    });

    testWidgets('allows entering coupon code and clicking APPLY',
        (WidgetTester tester) async {
      String submittedCoupon = '';

      const priceBreakup = PriceBreakupModel(
        subtotal: 800.0,
        deliveryCharge: 50.0,
        grandTotal: 850.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          PriceBreakupCard(
            priceBreakup: priceBreakup,
            onApplyCoupon: (code) => submittedCoupon = code,
          ),
        ),
      );

      // Enter code
      await tester.enterText(
        find.byKey(const Key('price_breakup_coupon_input')),
        'DISCOUNT50',
      );
      await tester.pump();

      // Tap APPLY
      await tester.tap(find.byKey(const Key('price_breakup_apply_coupon')));
      await tester.pumpAndSettle();

      expect(submittedCoupon, equals('DISCOUNT50'));
    });

    testWidgets('submits coupon code on keyboard submit action',
        (WidgetTester tester) async {
      String submittedCoupon = '';

      const priceBreakup = PriceBreakupModel(
        subtotal: 800.0,
        deliveryCharge: 50.0,
        grandTotal: 850.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          PriceBreakupCard(
            priceBreakup: priceBreakup,
            onApplyCoupon: (code) => submittedCoupon = code,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('price_breakup_coupon_input')),
        'SAVE10',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submittedCoupon, equals('SAVE10'));
    });

    testWidgets('displays loading indicator in apply button when isCouponLoading is true',
        (WidgetTester tester) async {
      const priceBreakup = PriceBreakupModel(
        subtotal: 800.0,
        deliveryCharge: 50.0,
        grandTotal: 850.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const PriceBreakupCard(
            priceBreakup: priceBreakup,
            isCouponLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('APPLY'), findsNothing);
    });

    testWidgets('displays coupon error message when provided',
        (WidgetTester tester) async {
      const priceBreakup = PriceBreakupModel(
        subtotal: 800.0,
        deliveryCharge: 50.0,
        grandTotal: 850.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const PriceBreakupCard(
            priceBreakup: priceBreakup,
            couponErrorMessage: 'Coupon code is invalid or expired',
          ),
        ),
      );

      expect(find.byKey(const Key('price_breakup_coupon_error')), findsOneWidget);
      expect(find.text('Coupon code is invalid or expired'), findsOneWidget);
    });

    testWidgets('displays applied coupon banner and triggers onRemoveCoupon on REMOVE tap',
        (WidgetTester tester) async {
      bool removed = false;

      const priceBreakup = PriceBreakupModel(
        subtotal: 1000.0,
        couponDiscount: 50.0,
        deliveryCharge: 0.0,
        grandTotal: 950.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          PriceBreakupCard(
            priceBreakup: priceBreakup,
            appliedCouponCode: 'WELCOME2026',
            onRemoveCoupon: () => removed = true,
          ),
        ),
      );

      expect(find.text('WELCOME2026'), findsOneWidget);
      expect(find.text('Coupon applied successfully'), findsOneWidget);
      expect(find.byKey(const Key('price_breakup_remove_coupon')), findsOneWidget);

      await tester.tap(find.byKey(const Key('price_breakup_remove_coupon')));
      await tester.pumpAndSettle();

      expect(removed, isTrue);
    });

    testWidgets('hides coupon section when showCouponSection is false',
        (WidgetTester tester) async {
      const priceBreakup = PriceBreakupModel(
        subtotal: 1000.0,
        deliveryCharge: 0.0,
        grandTotal: 1000.0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const PriceBreakupCard(
            priceBreakup: priceBreakup,
            showCouponSection: false,
          ),
        ),
      );

      expect(find.byKey(const Key('price_breakup_coupon_input')), findsNothing);
      expect(find.byKey(const Key('price_breakup_apply_coupon')), findsNothing);
    });
  });
}
