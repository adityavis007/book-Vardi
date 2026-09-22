import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:book_vardi/features/catalog/data/catalog_repository.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/school_model.dart';
import 'package:book_vardi/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:book_vardi/features/catalog/presentation/screens/categories_screen.dart';

class MockCatalogRepoForCategories implements ICatalogRepository {
  final List<CategoryModel> categories;
  final bool shouldThrow;

  MockCatalogRepoForCategories({
    this.categories = const [
      CategoryModel(categoryId: 'books', name: 'Books', iconUrl: '', displayOrder: 1),
      CategoryModel(categoryId: 'uniforms', name: 'Uniforms', iconUrl: '', displayOrder: 2),
      CategoryModel(categoryId: 'stationery', name: 'Stationery', iconUrl: '', displayOrder: 3),
      CategoryModel(categoryId: 'shoes', name: 'Shoes', iconUrl: '', displayOrder: 4),
      CategoryModel(categoryId: 'bags', name: 'Bags', iconUrl: '', displayOrder: 5),
    ],
    this.shouldThrow = false,
  });

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    if (shouldThrow) throw Exception('Network error');
    return categories;
  }

  @override
  Stream<List<CategoryModel>> watchCategories() {
    if (shouldThrow) return Stream.error(Exception('Network error'));
    return Stream.value(categories);
  }

  @override
  Future<List<SchoolModel>> fetchSchools() async => [];
  @override
  Stream<List<SchoolModel>> watchSchools() => Stream.value([]);
  @override
  Future<List<ProductModel>> fetchProducts({
    String? categoryId,
    String? school,
    String? schoolId,
    String? grade,
    String? searchQuery,
    SortOption? sort,
    bool? featuredOnly,
    int? limit,
  }) async => [];
  @override
  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    String? school,
    String? schoolId,
    String? grade,
    String? searchQuery,
    SortOption? sort,
    bool? featuredOnly,
    int? limit,
  }) => Stream.value([]);
  @override
  Future<ProductModel?> fetchProductById(String id) async => null;
  @override
  Stream<ProductModel?> watchProductById(String id) => Stream.value(null);
}

void main() {
  Widget createWidgetUnderTest({
    ICatalogRepository? repo,
    ProviderContainer? container,
  }) {
    final effectiveRepo = repo ?? MockCatalogRepoForCategories();
    final router = GoRouter(
      initialLocation: '/category',
      routes: [
        GoRoute(
          path: '/category',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const Scaffold(body: Text('Search Screen Mock')),
        ),
      ],
    );

    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    return ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(effectiveRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('CategoriesScreen Widget Tests', () {
    testWidgets('renders app bar and all 5 seeded categories in grid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Uniforms'), findsOneWidget);
      expect(find.text('Stationery'), findsOneWidget);
      expect(find.text('Shoes'), findsOneWidget);
      expect(find.text('Bags'), findsOneWidget);
    });

    testWidgets('tapping a category card updates catalogFilterProvider and navigates', (tester) async {
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(MockCatalogRepoForCategories()),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(container: container));
      await tester.pumpAndSettle();

      // Tap on Uniforms
      final uniformsCard = find.byKey(const Key('category_card_uniforms'));
      expect(uniformsCard, findsOneWidget);

      await tester.tap(uniformsCard);
      await tester.pumpAndSettle();

      // Verify the filter provider has categoryId set to 'uniforms'
      expect(container.read(catalogFilterProvider).categoryId, equals('uniforms'));
      // Verify navigated to search screen
      expect(find.text('Search Screen Mock'), findsOneWidget);
    });

    testWidgets('displays error and retry when repository fails', (tester) async {
      final failingRepo = MockCatalogRepoForCategories(shouldThrow: true);
      await tester.pumpWidget(createWidgetUnderTest(repo: failingRepo));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load categories'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
