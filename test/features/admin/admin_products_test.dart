import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:book_vardi/features/admin/data/admin_repository.dart';
import 'package:book_vardi/features/admin/presentation/controllers/admin_controller.dart';
import 'package:book_vardi/features/admin/presentation/screens/admin_product_form.dart';
import 'package:book_vardi/features/admin/presentation/screens/admin_products_screen.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/features/orders/domain/tracking_step_model.dart';

class MockProductsAdminRepository implements IAdminRepository {
  List<ProductModel> products;
  ProductModel? lastSavedProduct;
  bool saveCalled = false;

  MockProductsAdminRepository({required this.products});

  @override
  Stream<AdminDashboardStats> watchDashboardStats() => const Stream.empty();

  @override
  Stream<List<ProductModel>> watchLowStockProducts({int threshold = 5}) => const Stream.empty();

  @override
  Stream<List<ProductModel>> watchAllProducts({String? searchQuery}) {
    if (searchQuery == null || searchQuery.isEmpty) {
      return Stream.value(products);
    }
    final q = searchQuery.toLowerCase();
    final filtered = products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.schoolName != null && p.schoolName!.toLowerCase().contains(q)))
        .toList();
    return Stream.value(filtered);
  }

  @override
  Stream<List<OrderModel>> watchAllOrders({OrderStatus? statusFilter}) => const Stream.empty();

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? carrierName,
    String? trackingNumber,
  }) async {}

  @override
  Future<String> saveProduct(ProductModel product) async {
    saveCalled = true;
    lastSavedProduct = product;
    return 'generated_id';
  }

  @override
  Future<void> deleteProduct(String productId) async {
    products.removeWhere((p) => p.productId == productId);
  }
}

void main() {
  const sampleProducts = [
    ProductModel(
      productId: 'prod_1',
      name: 'Class 4 Math Magic Textbook',
      description: 'NCERT standard textbook',
      categoryId: 'books',
      schoolName: 'All Schools',
      targetGrade: 'Class 4',
      basePrice: 160.0,
      totalStock: 50,
      inStock: true,
      variants: [],
    ),
    ProductModel(
      productId: 'prod_2',
      name: 'Girls Pleated Skirt Grey',
      description: 'Durable school uniform skirt',
      categoryId: 'uniforms',
      schoolName: 'Delhi Public School',
      targetGrade: 'Class 6',
      basePrice: 520.0,
      totalStock: 12,
      inStock: true,
      variants: [
        VariantModel(variantId: 'v1', label: 'Size 30', sku: 'SKIRT-30', price: 520.0, stock: 8),
        VariantModel(variantId: 'v2', label: 'Size 32', sku: 'SKIRT-32', price: 540.0, stock: 4),
      ],
    ),
  ];

  group('TASK-060: Product Catalog Studio Tests', () {
    testWidgets('AdminProductsScreen renders product cards and filters by search', (tester) async {
      final mockRepo = MockProductsAdminRepository(products: List.of(sampleProducts));

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/admin/products',
        routes: [
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => const AdminProductsScreen(),
          ),
          GoRoute(
            path: '/admin/products/new',
            builder: (context, state) => const Scaffold(body: Text('New Product Screen')),
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

      // Verify product items exist
      expect(find.text('Catalog Studio'), findsOneWidget);
      expect(find.text('Class 4 Math Magic Textbook'), findsOneWidget);
      expect(find.text('Girls Pleated Skirt Grey'), findsOneWidget);

      // Tap Floating Action Button to create new product
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('New Product Screen'), findsOneWidget);
    });

    testWidgets('AdminProductFormScreen dynamic variant matrix adds and removes rows', (tester) async {
      final mockRepo = MockProductsAdminRepository(products: []);

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AdminProductFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Form header
      expect(find.text('Add New Product'), findsOneWidget);

      // Verify Variant Builder section
      expect(find.text('Variant Matrix Builder'), findsOneWidget);

      // Initially 1 default variant row exists
      expect(find.text('Size / Option'), findsOneWidget);
      expect(find.text('SKU'), findsOneWidget);
      expect(find.text('Stock'), findsOneWidget);

      // Tap "Add Variant" button
      final addVariantBtn = find.text('Add Variant');
      expect(addVariantBtn, findsOneWidget);
      await tester.ensureVisible(addVariantBtn);
      await tester.pumpAndSettle();
      await tester.tap(addVariantBtn);
      await tester.pumpAndSettle();

      // Now 2 variant rows exist
      expect(find.text('Size / Option'), findsNWidgets(2));

      // Remove second variant row
      final deleteBtns = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteBtns, findsNWidgets(2));
      await tester.ensureVisible(deleteBtns.last);
      await tester.pumpAndSettle();
      await tester.tap(deleteBtns.last);
      await tester.pumpAndSettle();

      // Back to 1 variant row
      expect(find.text('Size / Option'), findsOneWidget);
    });
  });
}
