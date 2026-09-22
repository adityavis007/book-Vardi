import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/network/fcm_service.dart';
import 'package:book_vardi/core/router/app_router.dart';
import 'package:book_vardi/core/theme/app_theme.dart';
import 'package:book_vardi/features/admin/data/admin_repository.dart';
import 'package:book_vardi/features/admin/presentation/controllers/admin_controller.dart';
import 'package:book_vardi/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:book_vardi/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:book_vardi/features/admin/presentation/widgets/admin_invoice_dialog.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/cart/data/cart_repository.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';
import 'package:book_vardi/features/cart/presentation/screens/cart_screen.dart';
import 'package:book_vardi/features/catalog/data/catalog_repository.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/school_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';
import 'package:book_vardi/features/catalog/presentation/screens/categories_screen.dart';
import 'package:book_vardi/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:book_vardi/features/checkout/data/address_repository.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/orders/data/order_repository.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/features/orders/domain/tracking_step_model.dart';
import 'package:book_vardi/features/orders/presentation/screens/order_tracking_screen.dart';

// Test doubles
class E2EAuthRepo implements IAuthRepository {
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
  }) async {
    codeSent('e2e_vid_123', 112233);
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    return const UserModel(
      userId: 'user_e2e_customer',
      name: 'Aditya Customer',
      email: 'aditya@bookvardi.com',
      phone: '9876543210',
      role: UserRole.customer,
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel> updateProfile(UserModel user) async => user;
}

class E2EAuthController extends AuthController {
  E2EAuthController(AuthState initial) : super(authRepository: E2EAuthRepo()) {
    state = initial;
  }
  void setAuthenticatedCustomer() {
    state = const AuthState.authenticated(
      UserModel(
        userId: 'user_e2e_customer',
        name: 'Aditya Customer',
        email: 'aditya@bookvardi.com',
        phone: '9876543210',
        role: UserRole.customer,
      ),
    );
  }
  void setAuthenticatedAdmin() {
    state = const AuthState.authenticated(
      UserModel(
        userId: 'user_e2e_admin',
        name: 'Admin Boss',
        email: 'admin@bookvardi.com',
        phone: '9998887776',
        role: UserRole.admin,
      ),
    );
  }
}

class E2ECatalogRepo implements ICatalogRepository {
  static const sampleProduct = ProductModel(
    productId: 'uniform_set_boys_01',
    name: 'Boys Summer Uniform Set',
    description: 'Navy blue shorts and white half sleeve shirt with school crest.',
    basePrice: 399.0,
    discountPrice: 399.0,
    categoryId: 'uniforms',
    schoolId: 'cms_lucknow',
    schoolName: 'City Montessori School',
    targetGrade: 'Class 4',
    rating: 4.8,
    reviewCount: 42,
    images: ['https://images.unsplash.com/photo-1577896851231-70ef18881754?w=600'],
    variants: [
      VariantModel(variantId: 'v_28', sku: 'SKU-28', label: 'Size 28', price: 399.0, stock: 15),
      VariantModel(variantId: 'v_30', sku: 'SKU-30', label: 'Size 30', price: 420.0, stock: 20),
    ],
  );

  @override
  Future<List<CategoryModel>> fetchCategories() async => CategoriesScreen.defaultCategories;
  @override
  Stream<List<CategoryModel>> watchCategories() => Stream.value(CategoriesScreen.defaultCategories);
  @override
  Future<List<SchoolModel>> fetchSchools() async => [];
  @override
  Stream<List<SchoolModel>> watchSchools() => Stream.value([]);
  @override
  Future<List<ProductModel>> fetchProducts({String? categoryId, String? school, String? schoolId, String? grade, String? searchQuery, SortOption? sort, bool? featuredOnly, int? limit}) async => [sampleProduct];
  @override
  Stream<List<ProductModel>> watchProducts({String? categoryId, String? school, String? schoolId, String? grade, String? searchQuery, SortOption? sort, bool? featuredOnly, int? limit}) => Stream.value([sampleProduct]);
  @override
  Future<ProductModel?> fetchProductById(String id) async => sampleProduct;
  @override
  Stream<ProductModel?> watchProductById(String id) => Stream.value(sampleProduct);
}

class E2ECartRepo implements ICartRepository {
  final Map<String, CartItemModel> _items = {};
  final _controller = StreamController<List<CartItemModel>>.broadcast();

  E2ECartRepo() {
    _emit();
  }

  void _emit() {
    _controller.add(_items.values.toList());
  }

  @override
  Future<List<CartItemModel>> fetchCart(String userId) async => _items.values.toList();
  @override
  Future<void> addToCart(String userId, CartItemModel item) async {
    _items[item.id] = item;
    _emit();
  }
  @override
  Future<void> clearCart(String userId) async {
    _items.clear();
    _emit();
  }
  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    _items.remove(cartItemId);
    _emit();
  }
  @override
  Future<void> updateQuantity(String userId, String cartItemId, int quantity) async {
    if (_items.containsKey(cartItemId)) {
      _items[cartItemId] = _items[cartItemId]!.copyWith(quantity: quantity);
      _emit();
    }
  }
  @override
  Stream<List<CartItemModel>> watchCart(String userId) {
    return Stream<List<CartItemModel>>.multi((controller) {
      controller.add(_items.values.toList());
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }
}

class E2EAddressRepo implements IAddressRepository {
  static const testAddress = AddressModel(
    addressId: 'addr_e2e_1',
    fullName: 'Aditya Sharma',
    phone: '9876543210',
    pincode: '226028',
    addressLine1: 'Flat 402, Pine Enclave',
    addressLine2: 'Faizabad Road',
    city: 'Lucknow',
    state: 'Uttar Pradesh',
    addressType: 'Home',
    isDefault: true,
  );

  @override
  Future<String> addAddress(String userId, AddressModel address) async => address.addressId;
  @override
  Future<AddressModel?> fetchDefaultAddress(String userId) async => testAddress;
  @override
  Future<void> updateAddress(String userId, AddressModel address) async {}
  @override
  Future<void> deleteAddress(String userId, String addressId) async {}
  @override
  Future<List<AddressModel>> fetchAddresses(String userId) async => [testAddress];
  Future<void> saveAddress(String userId, AddressModel address) async {}
  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {}
  @override
  Stream<List<AddressModel>> watchAddresses(String userId) => Stream.value([testAddress]);
}

class E2EOrdersRepo implements IOrdersRepository {
  OrderModel? currentOrder;
  final _controller = StreamController<List<OrderModel>>.broadcast();

  void emit(OrderModel order) {
    currentOrder = order;
    _controller.add([order]);
  }

  @override
  Future<void> cancelOrder(String orderId, String reason) async {}
  @override
  Future<OrderModel?> fetchOrderById(String orderId) async => currentOrder;
  @override
  Stream<OrderModel?> watchOrderById(String orderId) {
    return Stream<OrderModel?>.multi((controller) {
      if (currentOrder != null) {
        controller.add(currentOrder);
      }
      final sub = _controller.stream.listen(
        (list) {
          final found = list.firstWhere((o) => o.orderId == orderId, orElse: () => currentOrder!);
          controller.add(found);
        },
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }
  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return Stream<List<OrderModel>>.multi((controller) {
      if (currentOrder != null) {
        controller.add([currentOrder!]);
      }
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }
}

class E2EAdminRepo implements IAdminRepository {
  final E2EOrdersRepo ordersRepo;
  E2EAdminRepo(this.ordersRepo);

  @override
  Stream<AdminDashboardStats> watchDashboardStats() => Stream.value(
    const AdminDashboardStats(
      totalGmv: 420.0,
      totalOrdersCount: 1,
      unfulfilledOrdersCount: 1,
      totalProductsCount: 1,
      lowStockProductsCount: 0,
    ),
  );

  @override
  Stream<List<ProductModel>> watchLowStockProducts({int threshold = 5}) => Stream.value([]);

  @override
  Stream<List<ProductModel>> watchAllProducts({String? searchQuery}) => Stream.value([E2ECatalogRepo.sampleProduct]);

  @override
  Stream<List<OrderModel>> watchAllOrders({OrderStatus? statusFilter}) {
    final list = ordersRepo.currentOrder != null ? [ordersRepo.currentOrder!] : <OrderModel>[];
    return Stream.value(list);
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? carrierName,
    String? trackingNumber,
  }) async {
    if (ordersRepo.currentOrder != null) {
      final updated = ordersRepo.currentOrder!.copyWith(
        orderStatus: newStatus,
        trackingMetadata: TrackingMetadata(
          carrierName: carrierName,
          trackingNumber: trackingNumber,
        ),
      );
      ordersRepo.emit(updated);
    }
  }

  @override
  Future<String> saveProduct(ProductModel product) async => product.productId;

  @override
  Future<void> deleteProduct(String productId) async {}
}

class E2EFcmService implements IFcmService {
  @override
  Future<NotificationSettings?> requestPermissions() async => null;
  @override
  Future<String?> getDeviceToken() async => 'e2e_dummy_token';
  @override
  Future<void> removeDeviceToken(String userId) async {}
  @override
  void setupMessageHandlers({void Function(String orderId)? onNavigateToOrder, void Function(String title, String body, String? orderId)? onForegroundMessage}) {}
  @override
  Future<void> syncDeviceToken(String userId) async {}
  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-067: End-to-End User Journey Regression Suite', () {
    late E2EAuthController authController;
    late E2ECatalogRepo catalogRepo;
    late E2ECartRepo cartRepo;
    late E2EAddressRepo addressRepo;
    late E2EOrdersRepo ordersRepo;
    late E2EAdminRepo adminRepo;
    late E2EFcmService fcmService;

    setUp(() {
      authController = E2EAuthController(const AuthState.unauthenticated(isGuest: true));
      catalogRepo = E2ECatalogRepo();
      cartRepo = E2ECartRepo();
      addressRepo = E2EAddressRepo();
      ordersRepo = E2EOrdersRepo();
      adminRepo = E2EAdminRepo(ordersRepo);
      fcmService = E2EFcmService();
    });

    Widget createTestApp(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: BookVardiTheme.lightTheme,
          routerConfig: container.read(routerProvider),
        ),
      );
    }

    testWidgets('Complete Journey: Guest browse -> Category -> PDP -> Cart -> Tracking -> Admin fulfillment & GST invoice', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(E2EAuthRepo()),
          authControllerProvider.overrideWith((ref) => authController),
          catalogRepositoryProvider.overrideWithValue(catalogRepo),
          cartRepositoryProvider.overrideWithValue(cartRepo),
          addressRepositoryProvider.overrideWithValue(addressRepo),
          ordersRepositoryProvider.overrideWithValue(ordersRepo),
          adminRepositoryProvider.overrideWithValue(adminRepo),
          fcmServiceProvider.overrideWithValue(fcmService),
        ],
      );

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // STEP 1: Guest Browse on HomeScreen inside AppScaffoldShell
      expect(find.byTooltip('Search catalog'), findsOneWidget);
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);

      // STEP 2: Navigate to Categories Tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoriesScreen), findsOneWidget);
      expect(find.text('Uniforms'), findsOneWidget);

      // STEP 3: Navigate directly to Product Detail Page (PDP)
      container.read(routerProvider).go('/product/uniform_set_boys_01');
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Boys Summer Uniform Set'), findsWidgets);
      expect(find.text('Size 28'), findsOneWidget);
      expect(find.text('Size 30'), findsOneWidget);

      // Tap Size 30 variant
      await tester.tap(find.text('Size 30'));
      await tester.pumpAndSettle();

      // STEP 4: Authenticate Customer & Add item to Cart
      authController.setAuthenticatedCustomer();
      await tester.pumpAndSettle();

      await cartRepo.addToCart(
        'user_e2e_customer',
        const CartItemModel(
          productId: 'uniform_set_boys_01',
          variantId: 'v_30',
          productName: 'Boys Summer Uniform Set',
          schoolName: 'City Montessori School',
          variantLabel: 'Size 30',
          imageUrl: 'https://images.unsplash.com/photo-1577896851231-70ef18881754?w=600',
          unitPrice: 420.0,
          quantity: 1,
          maxStock: 20,
        ),
      );
      await tester.pumpAndSettle();

      // STEP 5: Switch to Cart Tab
      container.read(routerProvider).go('/cart');
      await tester.pumpAndSettle();
      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.text('Boys Summer Uniform Set'), findsWidgets);
      expect(find.text('PROCEED TO CHECKOUT'), findsWidgets);

      // STEP 6: Place Order & Emit into Orders Stream
      final placedOrder = OrderModel(
        orderId: 'BV-2026-9901',
        userId: 'user_e2e_customer',
        items: const [
          CartItemModel(
            productId: 'uniform_set_boys_01',
            variantId: 'v_30',
            productName: 'Boys Summer Uniform Set',
            variantLabel: 'Size 30',
            quantity: 1,
            unitPrice: 420.0,
          ),
        ],
        shippingAddress: E2EAddressRepo.testAddress,
        pricing: const PriceBreakupModel(
          subtotal: 420.0,
          deliveryCharge: 0.0,
          grandTotal: 420.0,
        ),
        deliveryMode: 'standard',
        paymentMethod: 'COD',
        paymentStatus: 'PAID',
        orderStatus: OrderStatus.pending,
        createdAt: DateTime.now(),
        estimatedDeliveryDate: DateTime.now().add(const Duration(days: 3)),
      );
      ordersRepo.emit(placedOrder);

      // STEP 7: Order Tracking Screen Validation
      container.read(routerProvider).go('/order/BV-2026-9901');
      await tester.pumpAndSettle();
      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      expect(find.text('Order Confirmed'), findsOneWidget);

      // STEP 8: Admin Operations Portal Fulfillment & Status Progression
      authController.setAuthenticatedAdmin();
      await tester.pump();
      await tester.pumpAndSettle();

      container.read(routerProvider).go('/admin');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.byType(AdminDashboardScreen), findsOneWidget);

      // Open Admin Orders Screen
      container.read(routerProvider).go('/admin/orders');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.byType(AdminOrdersScreen), findsOneWidget);

      // Advance status from PENDING to SHIPPED with BlueDart Carrier details
      final shippedOrder = placedOrder.copyWith(
        orderStatus: OrderStatus.shipped,
        trackingMetadata: const TrackingMetadata(
          carrierName: 'BlueDart Express',
          trackingNumber: 'BLUEDART-AWB-987654',
        ),
      );
      ordersRepo.emit(shippedOrder);
      container.invalidate(adminOrdersProvider);
      await tester.pumpAndSettle();

      // Verify Admin Invoice Dialog opens cleanly with GST Tax Details
      await tester.tap(find.byKey(const Key('admin_invoice_button_BV-2026-9901')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminInvoiceDialog), findsOneWidget);
      expect(find.textContaining('TAX INVOICE'), findsOneWidget);
      expect(find.textContaining('GSTIN'), findsOneWidget);
      expect(find.text('Aditya Sharma'), findsOneWidget);
    });
  });
}
