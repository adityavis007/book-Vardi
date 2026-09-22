import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/orders/data/order_repository.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/features/orders/domain/tracking_step_model.dart';
import 'package:book_vardi/features/orders/presentation/screens/order_tracking_screen.dart';

class MockOrdersRepoForTracking implements IOrdersRepository {
  final OrderModel? order;
  final bool shouldThrow;
  String? cancelledOrderId;
  String? cancelReason;

  MockOrdersRepoForTracking({
    this.order,
    this.shouldThrow = false,
  });

  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) => Stream.value([]);

  @override
  Stream<OrderModel?> watchOrderById(String orderId) {
    if (shouldThrow) return Stream.error(Exception('Failed to track order'));
    return Stream.value(order);
  }

  @override
  Future<OrderModel?> fetchOrderById(String orderId) async {
    if (shouldThrow) throw Exception('Failed to fetch order');
    return order;
  }

  @override
  Future<void> cancelOrder(String orderId, String reason) async {
    cancelledOrderId = orderId;
    cancelReason = reason;
  }
}

void main() {
  final sampleAddress = AddressModel(
    addressId: 'addr_1',
    fullName: 'Aditya Sharma',
    phone: '9876543210',
    addressLine1: 'Flat 402, Lotus Apartments',
    city: 'Lucknow',
    state: 'Uttar Pradesh',
    pincode: '226028',
  );

  final samplePricing = const PriceBreakupModel(
    subtotal: 798.0,
    deliveryCharge: 0.0,
    grandTotal: 798.0,
  );

  final sampleItems = [
    CartItemModel(
      productId: 'prod_uniform_1',
      productName: 'Boys Summer Uniform Set',
      unitPrice: 399.0,
      quantity: 2,
      variantLabel: 'Size 28',
    ),
  ];

  final shippedOrder = OrderModel(
    orderId: 'BV-2026-9812',
    userId: 'user_123',
    items: sampleItems,
    shippingAddress: sampleAddress,
    pricing: samplePricing,
    deliveryMode: 'standard',
    paymentMethod: 'COD',
    paymentStatus: 'PENDING',
    orderStatus: OrderStatus.shipped,
    createdAt: DateTime(2026, 9, 19, 10, 0),
    estimatedDeliveryDate: DateTime(2026, 9, 23, 18, 0),
    trackingMetadata: const TrackingMetadata(
      carrierName: 'BlueDart Express',
      trackingNumber: 'BD-991288',
    ),
  );

  final confirmedOrder = OrderModel(
    orderId: 'BV-2026-1111',
    userId: 'user_123',
    items: sampleItems,
    shippingAddress: sampleAddress,
    pricing: samplePricing,
    deliveryMode: 'standard',
    paymentMethod: 'COD',
    paymentStatus: 'PENDING',
    orderStatus: OrderStatus.confirmed,
    createdAt: DateTime(2026, 9, 19, 10, 0),
    estimatedDeliveryDate: DateTime(2026, 9, 23, 18, 0),
    trackingMetadata: const TrackingMetadata(),
  );

  Widget createWidgetUnderTest({
    required String orderId,
    required IOrdersRepository repo,
  }) {
    final router = GoRouter(
      initialLocation: '/order/$orderId',
      routes: [
        GoRoute(
          path: '/order/:id',
          builder: (context, state) => OrderTrackingScreen(
            orderId: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('OrderTrackingScreen Widget Tests', () {
    testWidgets('renders order header, milestone journey, and courier details for SHIPPED order',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockOrdersRepoForTracking(order: shippedOrder);

      await tester.pumpWidget(
        createWidgetUnderTest(orderId: 'BV-2026-9812', repo: repo),
      );
      await tester.pumpAndSettle();

      // Header card
      expect(find.text('Track Order'), findsOneWidget);
      expect(find.text('BV-2026-9812'), findsOneWidget);
      expect(find.text('Shipped'), findsNWidgets(2)); // Status pill + timeline step

      // Milestone timeline
      expect(find.text('Fulfillment Journey'), findsOneWidget);
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Packed & Ready'), findsOneWidget);
      expect(find.text('Handed over to BlueDart Express'), findsOneWidget);
      expect(find.text('Out for Delivery'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);

      // Courier partner card
      expect(find.text('Courier & Dispatch Details'), findsOneWidget);
      expect(find.text('Carrier: BlueDart Express'), findsOneWidget);
      expect(find.text('AWB Number: BD-991288'), findsOneWidget);

      // Delivery Address
      expect(find.text('Delivery Address'), findsOneWidget);
      expect(find.text('Aditya Sharma'), findsOneWidget);
      expect(find.textContaining('Lucknow, Uttar Pradesh - 226028'), findsOneWidget);

      // Ordered Items
      expect(find.text('Ordered Items (2)'), findsOneWidget);
      expect(find.text('Boys Summer Uniform Set'), findsOneWidget);
      expect(find.text('Size/Variant: Size 28'), findsOneWidget);

      // Payment Summary
      expect(find.text('Payment Summary'), findsOneWidget);
      expect(find.text('Grand Total (COD)'), findsOneWidget);
      expect(find.text('₹798'), findsWidgets);

      // Shipped order cannot be cancelled directly in app
      expect(find.byKey(const Key('cancel_order_btn')), findsNothing);
    });

    testWidgets('confirmed order shows cancel order button and triggers confirmation dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockOrdersRepoForTracking(order: confirmedOrder);

      await tester.pumpWidget(
        createWidgetUnderTest(orderId: 'BV-2026-1111', repo: repo),
      );
      await tester.pumpAndSettle();

      // Cancel button exists for confirmed orders
      final cancelBtn = find.byKey(const Key('cancel_order_btn'));
      expect(cancelBtn, findsOneWidget);

      // Tap Cancel Order
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog pops up
      expect(find.text('Are you sure you want to cancel order BV-2026-1111?'), findsOneWidget);
      expect(find.text('Keep Order'), findsOneWidget);

      // Confirm cancellation
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Cancel Order');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(repo.cancelledOrderId, equals('BV-2026-1111'));
    });

    testWidgets('shows not found view when order does not exist', (tester) async {
      final repo = MockOrdersRepoForTracking(order: null);

      await tester.pumpWidget(
        createWidgetUnderTest(orderId: 'NON_EXISTENT', repo: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order Not Found'), findsOneWidget);
      expect(find.text('Back to Orders'), findsOneWidget);
    });
  });
}
