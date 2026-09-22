import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/auth/presentation/widgets/auth_modal_sheet.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/orders/data/order_repository.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/features/orders/domain/tracking_step_model.dart';
import 'package:book_vardi/features/orders/presentation/screens/order_history_screen.dart';

class _DummyAuthRepo implements IAuthRepository {
  @override
  Stream<UserModel?> watchAuthState() => const Stream.empty();
  @override
  Future<UserModel?> getCurrentUser() async => null;
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) =>
      throw UnimplementedError();
  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<UserModel> updateProfile(UserModel user) async => user;
}

class FakeAuthController extends AuthController {
  FakeAuthController(AuthState initialState) : super(authRepository: _DummyAuthRepo()) {
    state = initialState;
  }
}

class MockOrdersRepoForHistory implements IOrdersRepository {
  final List<OrderModel> orders;
  final bool shouldThrow;

  MockOrdersRepoForHistory({
    this.orders = const [],
    this.shouldThrow = false,
  });

  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    if (shouldThrow) return Stream.error(Exception('Network error loading orders'));
    return Stream.value(orders);
  }

  @override
  Stream<OrderModel?> watchOrderById(String orderId) {
    if (shouldThrow) return Stream.error(Exception('Order tracking error'));
    try {
      final order = orders.firstWhere((o) => o.orderId == orderId);
      return Stream.value(order);
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Future<OrderModel?> fetchOrderById(String orderId) async {
    try {
      return orders.firstWhere((o) => o.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancelOrder(String orderId, String reason) async {}
}

void main() {
  final testUser = UserModel(
    userId: 'user_123',
    name: 'Aditya Sharma',
    email: 'aditya@example.com',
    phone: '9876543210',
    role: UserRole.customer,
  );

  final sampleOrder = OrderModel(
    orderId: '#BV-2026-9812',
    userId: 'user_123',
    items: [
      CartItemModel(
        productId: 'prod_uniform_1',
        productName: 'Boys Summer Uniform Set',
        unitPrice: 399.0,
        quantity: 2,
        variantLabel: 'Size 28',
      ),
    ],
    shippingAddress: AddressModel(
      addressId: 'addr_1',
      fullName: 'Aditya Sharma',
      phone: '9876543210',
      addressLine1: 'Flat 402, Lotus Apartments',
      city: 'Lucknow',
      state: 'Uttar Pradesh',
      pincode: '226028',
    ),
    pricing: const PriceBreakupModel(
      subtotal: 798.0,
      deliveryCharge: 0.0,
      grandTotal: 798.0,
    ),
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

  Widget createWidgetUnderTest({
    required AuthState authState,
    IOrdersRepository? repo,
  }) {
    final effectiveRepo = repo ?? MockOrdersRepoForHistory();
    final router = GoRouter(
      initialLocation: '/orders',
      routes: [
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrderHistoryScreen(),
        ),
        GoRoute(
          path: '/order/:id',
          builder: (context, state) => Scaffold(
            body: Text('Tracking Screen for ${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Catalog Home Mock')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => FakeAuthController(authState)),
        ordersRepositoryProvider.overrideWithValue(effectiveRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('OrderHistoryScreen Widget Tests', () {
    testWidgets('guest user sees guest guard prompt and login button', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: const AuthState.unauthenticated(isGuest: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Log in to view your orders'), findsOneWidget);
      expect(find.byKey(const Key('guest_orders_login_btn')), findsOneWidget);
      expect(find.text('Login or Create Account'), findsOneWidget);
    });

    testWidgets('tapping guest login button opens AuthModalBottomSheet', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: const AuthState.unauthenticated(isGuest: true),
        ),
      );
      await tester.pumpAndSettle();

      final loginBtn = find.byKey(const Key('guest_orders_login_btn'));
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AuthModalBottomSheet), findsOneWidget);
    });

    testWidgets('authenticated user with no orders sees empty state with explore CTA', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: AuthState.authenticated(testUser),
          repo: MockOrdersRepoForHistory(orders: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No orders placed yet'), findsOneWidget);
      expect(find.byKey(const Key('explore_catalog_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('explore_catalog_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Catalog Home Mock'), findsOneWidget);
    });

    testWidgets('authenticated user with orders sees order card and navigates to tracking', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: AuthState.authenticated(testUser),
          repo: MockOrdersRepoForHistory(orders: [sampleOrder]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#BV-2026-9812'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
      expect(find.text('₹798'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);

      // Tap Track Order
      final trackBtn = find.byKey(const Key('track_btn_#BV-2026-9812'));
      expect(trackBtn, findsOneWidget);

      await tester.tap(trackBtn);
      await tester.pumpAndSettle();

      expect(find.text('Tracking Screen for #BV-2026-9812'), findsOneWidget);
    });

    testWidgets('shows error view and retry when orders stream errors', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: AuthState.authenticated(testUser),
          repo: MockOrdersRepoForHistory(shouldThrow: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load orders'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
