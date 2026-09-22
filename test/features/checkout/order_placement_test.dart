import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/cart/data/cart_repository.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/checkout/data/address_repository.dart';
import 'package:book_vardi/features/checkout/data/order_repository.dart';
import 'package:book_vardi/features/checkout/data/razorpay_service.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/checkout/domain/order_intent_model.dart';
import 'package:book_vardi/features/checkout/domain/order_model.dart';
import 'package:book_vardi/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:book_vardi/features/checkout/presentation/screens/payment_step_screen.dart';

import 'address_repository_test.dart';
import 'checkout_controller_test.dart';
import 'razorpay_service_test.dart';

/// Test double for [IOrderRepository] tracking placed orders.
class MockOrderRepository implements IOrderRepository {
  final Map<String, OrderModel> orders = {};
  int _counter = 1000;

  @override
  Future<String> createOrder({
    required String userId,
    required OrderIntentModel intent,
    required String deliveryMode,
    required String status,
    String? paymentId,
    String? razorpayOrderId,
    String? signature,
    String? paymentStatus,
  }) async {
    final orderId = '#BV-2026-${_counter++}';
    final order = OrderModel.fromIntent(
      orderId: orderId,
      userId: userId,
      intent: intent,
      deliveryMode: deliveryMode,
      orderStatus: status,
      paymentId: paymentId,
      razorpayOrderId: razorpayOrderId,
      signature: signature,
      paymentStatus: paymentStatus,
    );
    orders[orderId] = order;
    return orderId;
  }

  @override
  Future<OrderModel?> fetchOrder(String orderId) async {
    return orders[orderId];
  }

  @override
  Future<List<OrderModel>> fetchUserOrders(String userId) async {
    return orders.values.where((o) => o.userId == userId).toList();
  }

  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return Stream.value(orders.values.where((o) => o.userId == userId).toList());
  }
}

/// Test double for [ICartRepository] tracking cart clear calls.
class MockCartRepository implements ICartRepository {
  int clearCartCallCount = 0;
  String? lastClearedUserId;
  final List<CartItemModel> items = [];

  @override
  Future<void> clearCart(String userId) async {
    clearCartCallCount++;
    lastClearedUserId = userId;
    items.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Order Placement & Payment Resolution Handler (TASK-045)', () {
    late ProviderContainer container;
    late MockOrderRepository mockOrderRepo;
    late MockCartRepository mockCartRepo;
    late MockAddressRepository mockAddressRepo;
    late FakeRazorpayClient fakeRazorpayClient;
    late RazorpayService razorpayService;

    const testUserId = 'user_aditya_order_test';
    const sampleAddress = AddressModel(
      addressId: 'addr_order_1',
      fullName: 'Aditya Sharma',
      phone: '9876543210',
      addressLine1: 'Flat 402, Royal Palms',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122001',
      isDefault: true,
      addressType: 'Home',
    );

    const sampleItem = CartItemModel(
      productId: 'prod_trouser_1',
      variantId: 'v_28',
      productName: 'DPS Navy Blue Trouser',
      schoolName: 'Delhi Public School',
      variantLabel: 'Size: 28',
      unitPrice: 400.0,
      quantity: 2, // Subtotal 800 + Delivery 50 = 850
    );

    setUp(() async {
      mockOrderRepo = MockOrderRepository();
      mockCartRepo = MockCartRepository();
      mockAddressRepo = MockAddressRepository();
      await mockAddressRepo.addAddress(testUserId, sampleAddress);

      fakeRazorpayClient = FakeRazorpayClient();
      razorpayService = RazorpayService(
        client: fakeRazorpayClient,
        keyId: 'rzp_test_mock_123',
      );

      container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(mockOrderRepo),
          cartRepositoryProvider.overrideWithValue(mockCartRepo),
          addressRepositoryProvider.overrideWithValue(mockAddressRepo),
          razorpayServiceProvider.overrideWithValue(razorpayService),
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthState.authenticated(
                UserModel(
                  userId: testUserId,
                  name: 'Aditya Sharma',
                  email: 'aditya@example.com',
                  phone: '9876543210',
                ),
              ),
            );
          }),
        ],
      );
    });

    tearDown(() {
      razorpayService.dispose();
      container.dispose();
    });

    test('COD Order: direct call creates order with status CONFIRMED, clears cart, and returns order ID',
        () async {
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.initStandardCartCheckout(
        items: [sampleItem],
        userId: testUserId,
      );
      controller.selectAddress(sampleAddress);
      controller.selectPaymentMethod(PaymentMethodType.cod);

      expect(container.read(checkoutControllerProvider).paymentMethod,
          equals(PaymentMethodType.cod));

      String? callbackOrderId;
      final returnedOrderId = await controller.placeOrder(
        onSuccess: (id) => callbackOrderId = id,
      );

      // 1. Verifies order is returned and matches callback
      expect(returnedOrderId, isNotNull);
      expect(returnedOrderId, equals(callbackOrderId));
      expect(returnedOrderId, startsWith('#BV-2026-'));

      // 2. Verifies order is written to Firestore orders collection
      expect(mockOrderRepo.orders.containsKey(returnedOrderId), isTrue);
      final createdOrder = mockOrderRepo.orders[returnedOrderId]!;
      expect(createdOrder.orderStatus, equals('CONFIRMED'));
      expect(createdOrder.paymentMethod, equals('COD'));
      expect(createdOrder.paymentId, equals('COD'));
      expect(createdOrder.paymentStatus, equals('PENDING'));
      expect(createdOrder.pricing.grandTotal, equals(890.0)); // 850 + 40 COD fee

      // 3. Verifies cart is cleared for standard checkout
      expect(mockCartRepo.clearCartCallCount, equals(1));
      expect(mockCartRepo.lastClearedUserId, equals(testUserId));

      // 4. Verifies state reflects completion
      final finalState = container.read(checkoutControllerProvider);
      expect(finalState.orderId, equals(returnedOrderId));
      expect(finalState.isLoading, isFalse);
      expect(finalState.errorMessage, isNull);
    });

    test('Direct Buy-Now COD: creates order with status CONFIRMED but does NOT clear persistent cart',
        () async {
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.initBuyNowCheckout(
        item: sampleItem,
        userId: testUserId,
      );
      controller.selectAddress(sampleAddress);
      controller.selectPaymentMethod(PaymentMethodType.cod);

      final returnedOrderId = await controller.placeOrder();

      expect(returnedOrderId, isNotNull);
      expect(mockOrderRepo.orders.containsKey(returnedOrderId), isTrue);
      final createdOrder = mockOrderRepo.orders[returnedOrderId]!;
      expect(createdOrder.orderStatus, equals('CONFIRMED'));

      // Buy now bypasses cart, so clearCart must NOT be invoked
      expect(mockCartRepo.clearCartCallCount, equals(0));
    });

    test('Online Order (UPI): triggers Razorpay; on EVENT_PAYMENT_SUCCESS creates order with paymentId and CONFIRMED status',
        () async {
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.initStandardCartCheckout(
        items: [sampleItem],
        userId: testUserId,
      );
      controller.selectAddress(sampleAddress);
      controller.selectPaymentMethod(PaymentMethodType.upi);

      String? callbackOrderId;
      final placeOrderFuture = controller.placeOrder(
        onSuccess: (id) => callbackOrderId = id,
      );

      // 1. Verifies Razorpay checkout sheet is opened
      expect(fakeRazorpayClient.openCallCount, equals(1));
      final options = fakeRazorpayClient.lastOpenedOptions!;
      expect(options['amount'], equals(85000)); // ₹850 in paise
      expect(options['prefill']['contact'], equals('9876543210'));
      expect(options['prefill']['email'], equals('aditya@example.com'));

      // 2. Simulate native Razorpay success event
      fakeRazorpayClient.simulateSuccess(
        PaymentSuccessResponse(
          'pay_razorpay_mock_999',
          'order_rzp_ext_1',
          'sig_mock_signature',
          {},
        ),
      );

      final returnedOrderId = await placeOrderFuture;

      // 3. Verifies order is recorded with payment ID and status CONFIRMED
      expect(returnedOrderId, isNotNull);
      expect(returnedOrderId, equals(callbackOrderId));
      expect(mockOrderRepo.orders.containsKey(returnedOrderId), isTrue);

      final order = mockOrderRepo.orders[returnedOrderId]!;
      expect(order.orderStatus, equals('CONFIRMED'));
      expect(order.paymentStatus, equals('PAID'));
      expect(order.paymentId, equals('pay_razorpay_mock_999'));
      expect(order.razorpayOrderId, equals('order_rzp_ext_1'));
      expect(order.signature, equals('sig_mock_signature'));

      // 4. Verifies cart is cleared in Firestore
      expect(mockCartRepo.clearCartCallCount, equals(1));
    });

    test('Online Order (Card): on EVENT_PAYMENT_ERROR retains address/options and reports error for retry',
        () async {
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.initStandardCartCheckout(
        items: [sampleItem],
        userId: testUserId,
      );
      controller.selectAddress(sampleAddress);
      controller.selectPaymentMethod(PaymentMethodType.card);
      controller.selectDeliveryMode(DeliveryMode.express);

      String? reportedError;
      final placeOrderFuture = controller.placeOrder(
        onFailure: (msg) => reportedError = msg,
      );

      expect(fakeRazorpayClient.openCallCount, equals(1));

      // Simulate user cancellation
      fakeRazorpayClient.simulateFailure(
        PaymentFailureResponse(
          Razorpay.PAYMENT_CANCELLED,
          'Payment was cancelled by the customer.',
          null,
        ),
      );

      final result = await placeOrderFuture;
      expect(result, isNull);
      expect(reportedError, contains('cancelled by the customer'));

      // 1. Verifies NO order was created
      expect(mockOrderRepo.orders.isEmpty, isTrue);

      // 2. Verifies user cart was NOT cleared
      expect(mockCartRepo.clearCartCallCount, equals(0));

      // 3. CRITICAL: Verifies state preserved selected address, delivery mode, and payment method for retry
      final state = container.read(checkoutControllerProvider);
      expect(state.selectedAddress, equals(sampleAddress));
      expect(state.deliveryMode, equals(DeliveryMode.express));
      expect(state.paymentMethod, equals(PaymentMethodType.card));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('cancelled by the customer'));
    });

    testWidgets('PaymentStepScreen: payment failure displays retry dialog without losing selections',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.initStandardCartCheckout(
        items: [sampleItem],
        userId: testUserId,
      );
      controller.selectAddress(sampleAddress);
      controller.selectPaymentMethod(PaymentMethodType.card);
      controller.goToStep(CheckoutStep.payment);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PaymentStepScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger payment button
      final payButton = find.byKey(const Key('payment_primary_button'));
      expect(payButton, findsOneWidget);
      await tester.tap(payButton);
      await tester.pump();

      // Simulate failure in Razorpay
      fakeRazorpayClient.simulateFailure(
        PaymentFailureResponse(
          Razorpay.NETWORK_ERROR,
          'Network connection lost during transaction.',
          null,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifies retry dialog appears
      expect(find.byKey(const Key('payment_retry_dialog')), findsOneWidget);
      expect(find.text('Payment Unsuccessful'), findsOneWidget);
      expect(find.text('Network connection lost during transaction.'), findsOneWidget);

      // 2. Change method dismisses dialog and retains address
      final changeMethodBtn = find.byKey(const Key('retry_dialog_change_method_button'));
      expect(changeMethodBtn, findsOneWidget);
      await tester.tap(changeMethodBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payment_retry_dialog')), findsNothing);
      expect(find.text('Aditya Sharma • +91 9876543210'), findsOneWidget);
      expect(container.read(checkoutControllerProvider).selectedAddress, equals(sampleAddress));
    });
  });
}
