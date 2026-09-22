import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/catalog/data/catalog_repository.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/school_model.dart';
import 'package:book_vardi/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:book_vardi/features/catalog/presentation/screens/search_screen.dart';
import 'package:book_vardi/features/catalog/presentation/widgets/filter_modal.dart';
import 'package:book_vardi/features/catalog/presentation/widgets/product_card.dart';

class MockCatalogRepoForSearch implements ICatalogRepository {
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
      rating: 4.5,
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
      rating: 4.8,
    ),
    const ProductModel(
      productId: 'prod_3',
      name: 'St. Xavier Navy Blazer',
      description: 'Formal blazer for winter',
      categoryId: 'cat_uniforms',
      schoolName: "St. Xavier's High School",
      targetGrade: 'Class 8',
      basePrice: 1500.0,
      discountPrice: 1200.0,
      inStock: false,
      isFeatured: false,
      rating: 4.2,
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
    final list = products.where((p) {
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (school != null && p.schoolName != school) return false;
      if (grade != null && p.targetGrade != grade) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final nameMatches = p.name.toLowerCase().contains(q);
        final descMatches = p.description.toLowerCase().contains(q);
        final schoolMatches =
            p.schoolName?.toLowerCase().contains(q) ?? false;
        if (!nameMatches && !descMatches && !schoolMatches) return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case SortOption.priceLowToHigh:
        list.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case SortOption.priceHighToLow:
        list.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case SortOption.ratingHighToLow:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        break;
    }

    return list;
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCatalogRepoForSearch mockRepo;

  setUp(() {
    mockRepo = MockCatalogRepoForSearch();
  });

  Widget buildTestApp({
    CatalogFilterState? initialState,
    ValueChanged<String>? onProductTap,
    VoidCallback? onBackTap,
    Duration debounceDuration = Duration.zero,
  }) {
    return ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(mockRepo),
        if (initialState != null)
          catalogFilterProvider.overrideWith((ref) {
            final notifier = CatalogFilterNotifier();
            notifier.applyState(initialState);
            return notifier;
          }),
      ],
      child: MaterialApp(
        home: SearchScreen(
          onProductTap: onProductTap,
          onBackTap: onBackTap,
          debounceDuration: debounceDuration,
        ),
      ),
    );
  }

  group('SearchScreen Core Layout & Elements Tests', () {
    testWidgets('renders search text field, back button, and filter action',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('search_back_button')), findsOneWidget);
      expect(find.byKey(const Key('search_text_field')), findsOneWidget);
      expect(find.byKey(const Key('search_filter_modal_btn')), findsOneWidget);
      expect(find.byKey(const Key('quick_sort_button')), findsOneWidget);
      expect(find.text('Search Screen'), findsOneWidget);
    });

    testWidgets('displays products in responsive 2-column grid',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(ProductCard), findsWidgets);
      expect(find.text('DPS Boys White Shirt'), findsOneWidget);
      expect(find.text('NCERT Class 6 Math Textbook'), findsOneWidget);
      expect(find.text('3 products found'), findsOneWidget);
    });

    testWidgets('tapping back button triggers onBackTap callback',
        (tester) async {
      var backTapped = false;
      await tester.pumpWidget(buildTestApp(
        onBackTap: () => backTapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('search_back_button')));
      await tester.pumpAndSettle();

      expect(backTapped, isTrue);
    });
  });

  group('Search Input & Debounced Query Filtering', () {
    testWidgets('entering query updates filtered list and displays clear button',
        (tester) async {
      await tester.pumpWidget(buildTestApp(debounceDuration: Duration.zero));
      await tester.pumpAndSettle();

      expect(find.text('3 products found'), findsOneWidget);

      // Enter 'Math'
      await tester.enterText(find.byKey(const Key('search_text_field')), 'Math');
      await tester.pumpAndSettle();

      // Only Math Textbook should match
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('NCERT Class 6 Math Textbook'), findsOneWidget);
      expect(find.byKey(const Key('search_clear_button')), findsOneWidget);
      expect(find.byKey(const Key('tag_search_query')), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byKey(const Key('search_clear_button')));
      await tester.pumpAndSettle();

      expect(find.text('3 products found'), findsOneWidget);
      expect(find.byType(ProductCard), findsWidgets);
      expect(find.byKey(const Key('search_clear_button')), findsNothing);
    });

    testWidgets('displays empty state when query returns no items',
        (tester) async {
      await tester.pumpWidget(buildTestApp(debounceDuration: Duration.zero));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('search_text_field')), 'NonExistentProduct');
      await tester.pumpAndSettle();

      expect(find.text('No products found'), findsOneWidget);
      expect(find.byKey(const Key('empty_state_reset_btn')), findsOneWidget);

      // Tap reset all filters button
      await tester.tap(find.byKey(const Key('empty_state_reset_btn')));
      await tester.pumpAndSettle();

      expect(find.text('3 products found'), findsOneWidget);
      expect(find.byType(ProductCard), findsWidgets);
    });
  });

  group('Active Filter Tags & Quick Tag Dismissal', () {
    testWidgets('active tags rail renders and individual tag dismissal works',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        initialState: const CatalogFilterState(
          categoryId: 'cat_uniforms',
          schoolName: 'Delhi Public School',
          grade: 'Class 6',
          inStockOnly: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tag_category')), findsOneWidget);
      expect(find.byKey(const Key('tag_school')), findsOneWidget);
      expect(find.byKey(const Key('tag_grade')), findsOneWidget);
      expect(find.byKey(const Key('tag_in_stock')), findsOneWidget);

      // Only DPS Boys White Shirt matches this specific filter
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('DPS Boys White Shirt'), findsOneWidget);

      // Tap remove on in-stock tag
      await tester.tap(find.descendant(
        of: find.byKey(const Key('tag_in_stock')),
        matching: find.byIcon(Icons.close),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tag_in_stock')), findsNothing);
    });

    testWidgets('tapping Clear All tag button clears all active filters',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        initialState: const CatalogFilterState(
          categoryId: 'cat_books',
          grade: 'Class 6',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('search_clear_all_tags_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('search_clear_all_tags_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(ProductCard), findsWidgets);
      expect(find.text('3 products found'), findsOneWidget);
      expect(find.byKey(const Key('search_clear_all_tags_btn')), findsNothing);
    });
  });

  group('FilterModal Launch & Interactions', () {
    testWidgets('tapping filter button opens FilterModal with all sections',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('search_filter_modal_btn')));
      await tester.pumpAndSettle();

      // Modal is visible with 5 website sections
      expect(find.text('Filters & Sorting'), findsOneWidget);
      expect(find.text('SORT BY'), findsOneWidget);
      expect(find.text('PRICE RANGE'), findsOneWidget);
      expect(find.text('RATING'), findsOneWidget);
      expect(find.text('AVAILABILITY'), findsOneWidget);
      expect(find.text('SPECIAL OFFERS'), findsOneWidget);
      expect(find.byKey(const Key('filter_clear_all_btn')), findsOneWidget);
      expect(find.byKey(const Key('filter_apply_btn')), findsOneWidget);
    });

    testWidgets('selecting sorting in FilterModal updates search screen',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Open filter modal
      await tester.tap(find.byKey(const Key('search_filter_modal_btn')));
      await tester.pumpAndSettle();

      // Select 'Price: Low to High'
      await tester.tap(find.byKey(const Key('sort_chip_priceLowToHigh')));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.byKey(const Key('filter_apply_btn')));
      await tester.pumpAndSettle();

      // Modal closed, products displayed
      expect(find.byType(FilterModal), findsNothing);
      expect(find.byType(ProductCard), findsWidgets);
    });

    testWidgets('selecting In Stock in FilterModal excludes out-of-stock items',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Open filter modal
      await tester.tap(find.byKey(const Key('search_filter_modal_btn')));
      await tester.pumpAndSettle();

      // Tap In Stock chip
      await tester.ensureVisible(find.byKey(const Key('availability_chip_inStock')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('availability_chip_inStock')));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.byKey(const Key('filter_apply_btn')));
      await tester.pumpAndSettle();

      // Prod 3 (St. Xavier Blazer) is out of stock, so only 2 items should remain
      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('St. Xavier Navy Blazer'), findsNothing);
    });
  });

  group('Product Interactions & Navigation', () {
    testWidgets('tapping product card invokes onProductTap callback',
        (tester) async {
      String? tappedId;
      await tester.pumpWidget(buildTestApp(
        onProductTap: (id) => tappedId = id,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DPS Boys White Shirt'));
      await tester.pumpAndSettle();

      expect(tappedId, equals('prod_1'));
    });
  });

  group('SearchScreen Viewport Resiliency (360px to 428px)', () {
    final viewports = [
      const Size(360.0, 640.0), // Compact standard
      const Size(375.0, 667.0), // iPhone SE / standard
      const Size(390.0, 844.0), // iPhone 14
      const Size(412.0, 915.0), // Pixel 7
      const Size(428.0, 926.0), // Large Pro Max
    ];

    for (final size in viewports) {
      testWidgets('renders cleanly with 0 overflow on ${size.width}x${size.height} viewport',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(
          initialState: const CatalogFilterState(
            categoryId: 'cat_uniforms',
            schoolName: 'Delhi Public School',
            grade: 'Class 6',
          ),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ProductCard), findsWidgets);
      });
    }
  });
}
