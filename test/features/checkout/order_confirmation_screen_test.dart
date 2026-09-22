import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';
import 'package:book_vardi/features/checkout/data/order_repository.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/checkout/domain/order_intent_model.dart';
import 'package:book_vardi/features/checkout/domain/order_model.dart';
import 'package:book_vardi/features/checkout/presentation/screens/order_confirmation_screen.dart';

import 'order_placement_test.dart';

void main() {
  group('OrderConfirmationScreen Widget Tests (TASK-046)', () {
    late MockOrderRepository mockOrderRepo;

    const sampleAddress = AddressModel(
      addressId: 'addr_order_conf_1',
      fullName: 'Aditya Sharma',
      phone: '9876543210',
      addressLine1: 'Flat 402, Royal Palms, DLF Phase 5',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122001',
      isDefault: true,
      addressType: 'Home',
    );

    const sampleItem1 = CartItemModel(
      productId: 'prod_trouser_1',
      variantId: 'v_28',
      productName: 'DPS Navy Blue Trouser',
      schoolName: 'Delhi Public School',
      variantLabel: 'Size: 28',
      unitPrice: 400.0,
      quantity: 2, // 800.0
    );

    const sampleItem2 = CartItemModel(
      productId: 'prod_tie_1',
      variantId: 'v_free',
      productName: 'DPS School Crest Tie',
      schoolName: 'Delhi Public School',
      variantLabel: 'Standard',
      unitPrice: 150.0,
      quantity: 1, // 150.0
    );

    final sampleOrder = OrderModel.fromIntent(
      orderId: '#BV-2026-9812',
      userId: 'user_test_123',
      intent: OrderIntentModel.create(
        items: [sampleItem1, sampleItem2],
        shippingAddress: sampleAddress,
        pricing: const PriceBreakupModel(
          subtotal: 950.0,
          deliveryCharge: 50.0,
          grandTotal: 1000.0,
        ),
        paymentMethod: 'UPI',
      ),
      deliveryMode: 'standard',
      orderStatus: 'CONFIRMED',
      paymentId: 'pay_rzp_mock_12345',
      paymentStatus: 'PAID',
      createdAt: DateTime(2026, 9, 20, 10, 30),
      estimatedDeliveryDate: DateTime(2026, 9, 24),
    );

    final sampleCodOrder = OrderModel.fromIntent(
      orderId: '#BV-2026-4321',
      userId: 'user_test_123',
      intent: OrderIntentModel.create(
        items: [sampleItem1],
        shippingAddress: sampleAddress,
        pricing: const PriceBreakupModel(
          subtotal: 800.0,
          deliveryCharge: 50.0,
          grandTotal: 890.0,
        ),
        paymentMethod: 'COD',
      ),
      deliveryMode: 'standard',
      orderStatus: 'CONFIRMED',
      paymentId: 'COD',
      paymentStatus: 'PENDING',
      createdAt: DateTime(2026, 9, 20, 11, 0),
      estimatedDeliveryDate: DateTime(2026, 9, 24),
    );

    setUp(() {
      mockOrderRepo = MockOrderRepository();
      mockOrderRepo.orders[sampleOrder.orderId] = sampleOrder;
      mockOrderRepo.orders[sampleCodOrder.orderId] = sampleCodOrder;
    });

    Widget createTestWidget({
      required String orderId,
      OrderModel? order,
      VoidCallback? onTrackOrder,
      VoidCallback? onContinueShopping,
    }) {
      return ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        ],
        child: MaterialApp(
          home: OrderConfirmationScreen(
            orderId: orderId,
            order: order,
            onTrackOrder: onTrackOrder,
            onContinueShopping: onContinueShopping,
          ),
        ),
      );
    }

    testWidgets('renders animated checkmark and Order Placed Successfully header',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        orderId: sampleOrder.orderId,
        order: sampleOrder,
      ));

      // Trigger animation forward and settle
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('order_confirmation_success_title')),
          findsOneWidget);
      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(
        find.textContaining('Thank you for shopping with Book Vardi'),
        findsOneWidget,
      );
    });

    testWidgets('displays business Order ID, estimated delivery, and status pill',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        orderId: sampleOrder.orderId,
        order: sampleOrder,
      ));
      await tester.pumpAndSettle();

      // Order ID
      expect(find.byKey(const Key('order_confirmation_id_text')), findsOneWidget);
      expect(find.text('#BV-2026-9812'), findsOneWidget);

      // Estimated Delivery Date
      expect(
        find.byKey(const Key('order_confirmation_estimated_delivery')),
        findsOneWidget,
      );
      expect(find.text('Thu, 24 Sep 2026'), findsOneWidget);

      // Status badge
      expect(find.text('CONFIRMED'), findsOneWidget);
    });

    testWidgets('renders summary of ordered items with quantities and prices',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        orderId: sampleOrder.orderId,
        order: sampleOrder,
      ));
      await tester.pumpAndSettle();

      // Items header with total units (2 trousers + 1 tie = 3 items)
      expect(find.byKey(const Key('order_confirmation_items_summary')),
          findsOneWidget);
      expect(find.text('Items Ordered (3)'), findsOneWidget);

      // Item 1
      expect(find.text('DPS Navy Blue Trouser'), findsOneWidget);
      expect(
        find.text('Delhi Public School • Size: 28 • Qty: 2'),
        findsOneWidget,
      );
      expect(find.text('₹800'), findsOneWidget);

      // Item 2
      expect(find.text('DPS School Crest Tie'), findsOneWidget);
      expect(
        find.text('Delhi Public School • Standard • Qty: 1'),
        findsOneWidget,
      );
      expect(find.text('₹150'), findsOneWidget);
    });

    testWidgets('renders delivery address snapshot accurately',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        orderId: sampleOrder.orderId,
        order: sampleOrder,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Delivery Address'), findsOneWidget);
      expect(find.text('Aditya Sharma • +91 9876543210'), findsOneWidget);
      expect(find.byKey(const Key('order_confirmation_shipping_address')),
          findsOneWidget);
      expect(find.textContaining('DLF Phase 5'), findsOneWidget);
    });

    testWidgets('renders financial summary and payment status (Online vs COD)',
        (tester) async {
      // 1. Online Paid Order
      await tester.pumpWidget(createTestWidget(
        orderId: sampleOrder.orderId,
        order: sampleOrder,
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Paid via Online'),
        100,
      );

      expect(find.text('Paid via Online'), findsOneWidget);
      expect(find.byKey(const Key('order_confirmation_price_summary')),
          findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);

      // 2. Cash on Delivery Order
      await tester.pumpWidget(createTestWidget(
        orderId: sampleCodOrder.orderId,
        order: sampleCodOrder,
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Cash on Delivery'),
        100,
      );

      expect(find.text('Cash on Delivery'), findsOneWidget);
      expect(find.text('COD Handling Fee'), findsOneWidget);
      expect(find.text('+₹40'), findsOneWidget);
      expect(find.text('₹890'), findsOneWidget);
    });

    testWidgets('action buttons trigger Track Order and Continue Shopping callbacks',
        (tester) async {
      var trackPressed = false;
      var continuePressed = false;
      await tester.pumpWidget(createTestWidget(
        orderId: sampleOrder.orderId,
        order: sampleOrder,
        onTrackOrder: () => trackPressed = true,
        onContinueShopping: () => continuePressed = true,
      ));
      await tester.pumpAndSettle();

      // Track Order Button
      final trackBtn = find.byKey(const Key('order_confirmation_track_button'));
      expect(trackBtn, findsOneWidget);
      await tester.tap(trackBtn);
      await tester.pumpAndSettle();
      expect(trackPressed, isTrue);

      // Continue Shopping Button
      final continueBtn =
          find.byKey(const Key('order_confirmation_continue_shopping_button'));
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(continuePressed, isTrue);
    });

    testWidgets('disables back navigation into checkout stack via PopScope',
        (tester) async {
      var backIntercepted = false;

      await tester.pumpWidget(createTestWidget(
        orderId: sampleOrder.orderId,
        order: sampleOrder,
        onContinueShopping: () => backIntercepted = true,
      ));
      await tester.pumpAndSettle();

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScopeWidget = tester.widget(popScopeFinder) as PopScope;
      expect(popScopeWidget.canPop, isFalse);

      // Simulate back navigation pop invocation
      popScopeWidget.onPopInvokedWithResult?.call(false, null);
      await tester.pumpAndSettle();

      expect(backIntercepted, isTrue);
    });

    testWidgets('zero layout overflow across compact mobile viewport (360x640)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        orderId: sampleOrder.orderId,
        order: sampleOrder,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('order_confirmation_success_title')),
          findsOneWidget);
      expect(find.byKey(const Key('order_confirmation_track_button')),
          findsOneWidget);
    });

    testWidgets('loads order from orderByIdProvider when order is null',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        orderId: sampleOrder.orderId,
        order: null, // Test repository fetching fallback
      ));
      await tester.pumpAndSettle();

      expect(find.text('#BV-2026-9812'), findsOneWidget);
      expect(find.text('Items Ordered (3)'), findsOneWidget);
    });
  });
}
