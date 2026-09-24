import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/checkout/data/address_repository.dart';
import 'package:book_vardi/features/checkout/data/order_repository.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:book_vardi/features/checkout/presentation/screens/checkout_screen.dart';

import 'address_repository_test.dart';
import 'checkout_controller_test.dart';
import 'order_placement_test.dart';

void main() {
  group('CheckoutScreen Widget Tests (Web Ref & Responsive)', () {
    late MockAddressRepository mockAddressRepo;
    late MockOrderRepository mockOrderRepo;
    const testUserId = 'user_rahul_checkout_test';

    const sampleAddress = AddressModel(
      addressId: 'addr_rahul_1',
      fullName: 'Rahul',
      phone: '9213213212',
      addressLine1: 'abc',
      city: 'lucknow',
      state: 'Uttar Pradesh',
      pincode: '110001',
      isDefault: true,
      addressType: 'Home',
    );

    const sampleItem = CartItemModel(
      productId: 'prod_shirt_1',
      variantId: 'v_cloth',
      productName: 'ghe shirt cloth',
      schoolName: 'City Montessori School',
      variantLabel: 'Standard Cloth',
      unitPrice: 100.0,
      quantity: 1, // Subtotal 100
    );

    setUp(() async {
      mockAddressRepo = MockAddressRepository();
      mockOrderRepo = MockOrderRepository();
      await mockAddressRepo.addAddress(testUserId, sampleAddress);
    });

    tearDown(() {
      mockAddressRepo.dispose();
    });

    Widget createTestWidget({
      VoidCallback? onBack,
      void Function(String orderId)? onOrderPlaced,
      DeliveryMode initialDeliveryMode = DeliveryMode.standard,
      PaymentMethodType initialPaymentMethod = PaymentMethodType.upi,
      AddressModel? initialAddress = sampleAddress,
      List<CartItemModel> items = const [sampleItem],
      Size viewportSize = const Size(1200, 900),
    }) {
      return ProviderScope(
        overrides: [
          addressRepositoryProvider.overrideWithValue(mockAddressRepo),
          orderRepositoryProvider.overrideWithValue(mockOrderRepo),
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthState.authenticated(
                UserModel(
                  userId: testUserId,
                  name: 'Rahul',
                  email: 'rahul@example.com',
                  phone: '9213213212',
                ),
              ),
            );
          }),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: viewportSize),
            child: Consumer(
              builder: (context, ref, _) {
                final controller = ref.read(checkoutControllerProvider.notifier);
                final state = ref.read(checkoutControllerProvider);

                if (state.items.isEmpty && items.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.initStandardCartCheckout(
                      items: items,
                      userId: testUserId,
                    );
                    if (initialAddress != null) {
                      controller.selectAddress(initialAddress);
                    }
                    controller.selectDeliveryMode(initialDeliveryMode);
                    controller.selectPaymentMethod(initialPaymentMethod);
                  });
                }

                return CheckoutScreen(
                  onBack: onBack,
                  onOrderPlaced: onOrderPlaced,
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('renders top announcement bar with SCHOOL10 and trust badge',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('DISCOUNT'), findsOneWidget);
      expect(find.text('10% OFF First Order | Code: SCHOOL10'), findsOneWidget);
      expect(find.text('TRUST'), findsOneWidget);
      expect(find.text('7-Day Easy Returns on Uniforms & Books'), findsOneWidget);
    });

    testWidgets('renders breadcrumbs and 256-Bit SSL trust badge in header',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Secure Checkout'), findsOneWidget);
      expect(find.text('256-Bit SSL'), findsOneWidget);
    });

    testWidgets('renders Step 1 (Delivery Address) with address details and Add New button',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Delivery Address'), findsOneWidget);
      expect(find.text('Where should we deliver your stationery parcel?'), findsOneWidget);
      expect(find.byKey(const Key('checkout_add_address_button')), findsOneWidget);

      // Address content matches website screenshot
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('Rahul'), findsOneWidget);
      expect(find.text('abc, lucknow - 110001'), findsOneWidget);
      expect(find.text('Phone: 9213213212'), findsOneWidget);
      expect(find.byKey(const Key('checkout_edit_address_icon')), findsOneWidget);
    });

    testWidgets('renders Step 2 (Delivery Speed & Carrier) and toggles modes',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Delivery Speed & Carrier'), findsOneWidget);
      expect(find.text('Standard Delivery'), findsOneWidget);
      expect(find.text('3 - 5 Business Days via BlueDart / Delhivery'), findsOneWidget);
      expect(find.text('✓ Eligible for Free Delivery'), findsOneWidget);
      expect(find.text('FREE'), findsWidgets);

      expect(find.text('Campus Express'), findsOneWidget);
      expect(find.text('1 - 2 Days Priority Air Dispatch'), findsOneWidget);
      expect(find.text('⚡ Guaranteed Pre-Exam Fast Delivery'), findsOneWidget);
      expect(find.text('+₹49'), findsOneWidget);

      // Tap Campus Express
      await tester.tap(find.byKey(const Key('checkout_delivery_mode_express')));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(CheckoutScreen));
      final container = ProviderScope.containerOf(element);
      expect(
        container.read(checkoutControllerProvider).deliveryMode,
        equals(DeliveryMode.express),
      );
    });

    testWidgets('renders Step 3 (Payment Method) with UPI apps and Zero Surcharge badge',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('UPI / Online Pay'), findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);

      // UPI apps
      expect(find.text('Popular Instant UPI Apps & Razorpay Gateway'), findsOneWidget);
      expect(find.text('Zero Surcharge'), findsOneWidget);
      expect(find.text('Google Pay'), findsOneWidget);
      expect(find.text('PhonePe'), findsOneWidget);
      expect(find.text('Paytm'), findsOneWidget);
      expect(find.text('Other UPI ID'), findsOneWidget);
    });

    testWidgets('switching to COD shows COD fee note and recalculates total',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap COD option
      await tester.tap(find.byKey(const Key('checkout_payment_cod')));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(CheckoutScreen));
      final container = ProviderScope.containerOf(element);
      expect(
        container.read(checkoutControllerProvider).paymentMethod,
        equals(PaymentMethodType.cod),
      );

      // COD Handling Fee row rendered in summary
      expect(find.text('COD Courier Handling Fee'), findsOneWidget);
      expect(find.text('+₹40'), findsOneWidget);
    });

    testWidgets('renders Order Summary card with items, subtotal, and trust badges',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('1 Item'), findsOneWidget);
      expect(find.text('ghe shirt cloth'), findsOneWidget);
      expect(find.text('Qty: 1 × ₹100'), findsOneWidget);
      expect(find.text('Cart Subtotal'), findsOneWidget);
      expect(find.text('Total Payable'), findsOneWidget);
      expect(find.text('100% Genuine Stationery'), findsOneWidget);
      expect(find.text('Safe Campus Delivery'), findsOneWidget);
    });

    testWidgets('applying coupon SCHOOL10 updates discount and shows applied banner',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand coupon accordion
      await tester.tap(find.text('Have a Coupon Code?'));
      await tester.pumpAndSettle();

      // Enter coupon SCHOOL10
      final inputFinder = find.byKey(const Key('checkout_coupon_input'));
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'SCHOOL10');
      await tester.pumpAndSettle();

      // Tap apply button
      await tester.tap(find.byKey(const Key('checkout_apply_coupon_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Coupon Applied'), findsOneWidget);
      expect(find.text('Coupon Discount'), findsOneWidget);
    });

    testWidgets('tapping PLACE ORDER with COD invokes onOrderPlaced callback',
        (tester) async {
      String? placedOrderId;

      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget(
        initialPaymentMethod: PaymentMethodType.cod,
        onOrderPlaced: (orderId) {
          placedOrderId = orderId;
        },
      ));
      await tester.pumpAndSettle();

      final placeOrderButton = find.byKey(const Key('checkout_place_order_button'));
      expect(placeOrderButton, findsOneWidget);

      await tester.tap(placeOrderButton);
      await tester.pumpAndSettle();

      expect(placedOrderId, isNotNull);
      expect(placedOrderId, startsWith('#BV-2026-'));
    });

    testWidgets('zero layout overflow on compact mobile viewport (360x640)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.pumpWidget(createTestWidget(
        viewportSize: const Size(360, 640),
      ));
      await tester.pumpAndSettle();

      // Sticky bottom bar should be present on mobile
      expect(find.byKey(const Key('checkout_sticky_place_order_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
