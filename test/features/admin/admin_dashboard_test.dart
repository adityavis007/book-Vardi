import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:book_vardi/features/admin/data/admin_repository.dart';
import 'package:book_vardi/features/admin/presentation/controllers/admin_controller.dart';
import 'package:book_vardi/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/features/orders/domain/tracking_step_model.dart';

class MockAdminRepository implements IAdminRepository {
  AdminDashboardStats stats;
  List<ProductModel> lowStockProducts;
  List<ProductModel> allProducts;
  List<OrderModel> orders;

  MockAdminRepository({
    this.stats = const AdminDashboardStats(
      totalGmv: 42500.0,
      totalOrdersCount: 28,
      unfulfilledOrdersCount: 7,
      totalProductsCount: 14,
      lowStockProductsCount: 2,
    ),
    this.lowStockProducts = const [],
    this.allProducts = const [],
    this.orders = const [],
  });

  @override
  Stream<AdminDashboardStats> watchDashboardStats() => Stream.value(stats);

  @override
  Stream<List<ProductModel>> watchLowStockProducts({int threshold = 5}) =>
      Stream.value(lowStockProducts);

  @override
  Stream<List<ProductModel>> watchAllProducts({String? searchQuery}) =>
      Stream.value(allProducts);

  @override
  Stream<List<OrderModel>> watchAllOrders({OrderStatus? statusFilter}) =>
      Stream.value(orders);

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? carrierName,
    String? trackingNumber,
  }) async {}

  @override
  Future<String> saveProduct(ProductModel product) async => 'prod_123';

  @override
  Future<void> deleteProduct(String productId) async {}
}

void main() {
  const sampleLowStockProducts = [
    ProductModel(
      productId: 'prod_low_1',
      name: 'Boys Summer Uniform Navy',
      description: 'Standard cotton blend uniform',
      categoryId: 'uniforms',
      schoolName: 'St. Xavier School',
      basePrice: 450.0,
      totalStock: 3,
      inStock: true,
      variants: [
        VariantModel(variantId: 'v1', label: 'Size 28', sku: 'UNIF-28', price: 450.0, stock: 3),
      ],
    ),
    ProductModel(
      productId: 'prod_low_2',
      name: 'Oxford Oxford Dictionary',
      description: 'Hardcover edition',
      categoryId: 'books',
      schoolName: 'DPS Mathura',
      basePrice: 320.0,
      totalStock: 1,
      inStock: true,
      variants: [],
    ),
  ];

  group('TASK-059: Admin Dashboard Screen Tests', () {
    testWidgets('renders KPI metrics cards correctly', (tester) async {
      final mockRepo = MockAdminRepository(lowStockProducts: sampleLowStockProducts);

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/admin',
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => const Scaffold(body: Text('Catalog Studio Screen')),
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (context, state) => const Scaffold(body: Text('Fulfillment Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Operations Portal'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);

      // Verify KPI Metrics
      expect(find.text('₹42500'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify Critical Inventory Alerts
      expect(find.text('Critical Inventory Alerts'), findsOneWidget);
      expect(find.text('Boys Summer Uniform Navy'), findsOneWidget);
      expect(find.text('Oxford Oxford Dictionary'), findsOneWidget);
      expect(find.text('3 left'), findsOneWidget);
      expect(find.text('1 left'), findsOneWidget);
    });

    testWidgets('navigates to Catalog Studio when Studio quick card is tapped', (tester) async {
      final mockRepo = MockAdminRepository();

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/admin',
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => const Scaffold(body: Text('Catalog Studio Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final studioCard = find.text('Catalog Studio');
      expect(studioCard, findsOneWidget);

      await tester.tap(studioCard);
      await tester.pumpAndSettle();

      expect(find.text('Catalog Studio Screen'), findsOneWidget);
    });

    testWidgets('navigates to Fulfillment Screen when quick card is tapped', (tester) async {
      final mockRepo = MockAdminRepository();

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/admin',
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (context, state) => const Scaffold(body: Text('Fulfillment Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fulfillmentCard = find.text('Order Fulfillment');
      expect(fulfillmentCard, findsOneWidget);

      await tester.tap(fulfillmentCard);
      await tester.pumpAndSettle();

      expect(find.text('Fulfillment Screen'), findsOneWidget);
    });
  });
}
