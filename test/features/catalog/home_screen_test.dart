import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/catalog/data/catalog_repository.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/school_model.dart';
import 'package:book_vardi/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:book_vardi/features/catalog/presentation/screens/home_screen.dart';
import 'package:book_vardi/features/catalog/presentation/widgets/category_item.dart';
import 'package:book_vardi/features/catalog/presentation/widgets/product_card.dart';

class MockCatalogRepoForHomeScreen implements ICatalogRepository {
  final List<CategoryModel> categories = [
    const CategoryModel(
      categoryId: 'cat_uniforms',
      name: 'Uniforms',
      iconUrl: '',
      displayOrder: 1,
    ),
    const CategoryModel(
      categoryId: 'cat_books',
      name: 'Textbooks',
      iconUrl: '',
      displayOrder: 2,
    ),
    const CategoryModel(
      categoryId: 'cat_stationery',
      name: 'Stationery',
      iconUrl: '',
      displayOrder: 3,
    ),
  ];

  final List<SchoolModel> schools = [
    const SchoolModel(
      schoolId: 'sch_dps',
      name: 'Delhi Public School',
      city: 'Delhi',
      logoUrl: 'https://example.com/dps.png',
    ),
    const SchoolModel(
      schoolId: 'sch_xavier',
      name: "St. Xavier's High School",
      city: 'Mumbai',
      logoUrl: 'https://example.com/xavier.png',
    ),
  ];

  final List<ProductModel> products = [
    const ProductModel(
      productId: 'prod_1',
      name: 'DPS Boys White Shirt',
      description: 'Cotton uniform shirt',
      categoryId: 'cat_uniforms',
      schoolName: 'Delhi Public School',
      targetGrade: 'Class 6',
      basePrice: 650.0,
      discountPrice: 550.0,
      inStock: true,
      isFeatured: true,
    ),
    const ProductModel(
      productId: 'prod_2',
      name: 'NCERT Class 6 Math Textbook',
      description: 'Mathematics textbook',
      categoryId: 'cat_books',
      schoolName: 'Delhi Public School',
      targetGrade: 'Class 6',
      basePrice: 280.0,
      inStock: true,
      isFeatured: true,
    ),
    const ProductModel(
      productId: 'bundle_1',
      name: 'Class 6 Complete Book Set',
      description: 'Full textbook kit',
      categoryId: 'cat_books',
      schoolName: 'Delhi Public School',
      targetGrade: 'Class 6',
      basePrice: 1999.0,
      discountPrice: 1699.0,
      inStock: true,
      isFeatured: true,
    ),
  ];

  @override
  Future<List<CategoryModel>> fetchCategories() async => categories;

  @override
  Stream<List<CategoryModel>> watchCategories() => Stream.value(categories);

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
  }) async {
    return products.where((p) {
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (school != null && p.schoolName != school) return false;
      if (grade != null && p.targetGrade != grade) return false;
      return true;
    }).toList();
  }

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
  }) =>
      Stream.value(products);

  @override
  Future<ProductModel?> fetchProductById(String id) async {
    return products.firstWhere((p) => p.productId == id);
  }

  @override
  Stream<ProductModel?> watchProductById(String id) =>
      Stream.value(products.firstWhere((p) => p.productId == id));

  @override
  Future<List<SchoolModel>> fetchSchools() async => schools;

  @override
  Stream<List<SchoolModel>> watchSchools() => Stream.value(schools);
}

void main() {
  late MockCatalogRepoForHomeScreen mockRepo;

  setUp(() {
    mockRepo = MockCatalogRepoForHomeScreen();
  });

  Widget createHomeScreenApp({
    VoidCallback? onSearchTap,
    VoidCallback? onViewAllCategories,
    ValueChanged<ProductModel>? onProductTap,
    ProviderContainer? container,
  }) {
    final scopeOverrides = [
      catalogRepositoryProvider.overrideWithValue(mockRepo),
    ];

    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: HomeScreen(
            onSearchTap: onSearchTap,
            onViewAllCategories: onViewAllCategories,
            onProductTap: onProductTap,
            autoScrollBanners: false,
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: scopeOverrides,
      child: MaterialApp(
        home: HomeScreen(
          onSearchTap: onSearchTap,
          onViewAllCategories: onViewAllCategories,
          onProductTap: onProductTap,
          autoScrollBanners: false,
        ),
      ),
    );
  }

  group('HomeScreen Core Layout & Elements Tests', () {
    testWidgets('renders all core dashboard sections starting with promo banners', (tester) async {
      await tester.pumpWidget(createHomeScreenApp());
      await tester.pumpAndSettle();

      // 1. 16:9 Promo Banner Carousel with Headline
      expect(find.text('Back to School Mega Sale'), findsOneWidget);
      expect(find.text('LIMITED TIME'), findsOneWidget);

      // 2. Category Quick Rail & View All CTA
      expect(find.text('Shop by Category'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.byType(CategoryQuickRail), findsOneWidget);

      // 3. "Filter By School" Section
      expect(find.text('Find Your School Kit'), findsOneWidget);
      expect(find.text('Select School'), findsOneWidget);

      // 4. "Recommended Bundles" Section
      expect(find.text('Recommended Bundles'), findsOneWidget);

      // 5. "Popular Items" Section
      expect(find.text('Popular Items'), findsOneWidget);
      expect(find.byType(ProductCard), findsWidgets);
    });

    testWidgets('View All categories button invokes onViewAllCategories',
        (tester) async {
      bool viewAllTapped = false;
      await tester.pumpWidget(
        createHomeScreenApp(
          onViewAllCategories: () => viewAllTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View All'));
      await tester.pump();

      expect(viewAllTapped, isTrue);
    });

    testWidgets('swiping promo banner updates pagination dot index',
        (tester) async {
      await tester.pumpWidget(createHomeScreenApp());
      await tester.pumpAndSettle();

      // Initial active banner
      expect(find.text('Back to School Mega Sale'), findsOneWidget);

      // Swipe left to next banner
      await tester.drag(
        find.byType(PageView),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // Second banner should now be visible
      expect(find.text('New Session Books 2026-27'), findsOneWidget);
    });
  });

  group('HomeScreen Viewport Resiliency (360px to 428px) & Overflow Tests', () {
    final viewports = [
      const Size(360, 640), // Compact mobile (e.g. Galaxy A10)
      const Size(375, 667), // iPhone SE / standard small
      const Size(390, 844), // iPhone 13/14
      const Size(412, 915), // Pixel 7
      const Size(428, 926), // iPhone 14 Pro Max
    ];

    for (final size in viewports) {
      testWidgets('renders cleanly with 0 overflow on ${size.width}x${size.height} viewport',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createHomeScreenApp());
        await tester.pumpAndSettle();

        // Check essential elements are present and layed out without overflow exceptions
        expect(find.text('Shop by Category'), findsOneWidget);
        expect(find.text('Find Your School Kit'), findsOneWidget);
        expect(find.text('Popular Items'), findsOneWidget);

        // Scroll down to test full length rendering
        await tester.drag(find.byKey(const Key('home_scroll_view')), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('HomeScreen Interactions & Pull-to-Refresh Tests', () {
    testWidgets('pull to refresh triggers without errors', (tester) async {
      await tester.pumpWidget(createHomeScreenApp());
      await tester.pumpAndSettle();

      // Pull down to trigger RefreshIndicator
      await tester.drag(find.byKey(const Key('home_scroll_view')), const Offset(0, 300));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting a school updates catalogFilterProvider and shows Clear button',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.pumpWidget(createHomeScreenApp(container: container));
      await tester.pumpAndSettle();

      // Scroll down to school filter section
      await tester.drag(find.byKey(const Key('home_scroll_view')), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Open School dropdown
      await tester.tap(find.byKey(const Key('school_dropdown')), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Choose "Delhi Public School"
      await tester.tap(find.text('Delhi Public School').last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(container.read(catalogFilterProvider).schoolName, 'Delhi Public School');
      expect(find.text('Clear'), findsOneWidget);

      // Tap Clear resets filter
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(container.read(catalogFilterProvider).schoolName, isNull);
      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('tapping a product card invokes onProductTap callback',
        (tester) async {
      ProductModel? tappedProduct;
      await tester.pumpWidget(
        createHomeScreenApp(
          onProductTap: (prod) => tappedProduct = prod,
        ),
      );
      await tester.pumpAndSettle();

      // Drag down to Popular Items section
      await tester.drag(find.byKey(const Key('home_scroll_view')), const Offset(0, -900));
      await tester.pumpAndSettle();

      // Tap the first product card
      await tester.tap(find.text('DPS Boys White Shirt'));
      await tester.pumpAndSettle();

      expect(tappedProduct, isNotNull);
      expect(tappedProduct!.productId, 'prod_1');
    });
  });
}
