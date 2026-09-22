import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/catalog/data/catalog_repository.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/school_model.dart';
import 'package:book_vardi/features/catalog/presentation/controllers/catalog_controller.dart';

class MockCatalogRepoForController implements ICatalogRepository {
  final List<CategoryModel> categories = [
    const CategoryModel(
      categoryId: 'cat_uniforms',
      name: 'Uniforms',
      iconUrl: 'u.png',
      displayOrder: 1,
    ),
    const CategoryModel(
      categoryId: 'cat_books',
      name: 'Books',
      iconUrl: 'b.png',
      displayOrder: 2,
    ),
  ];

  final List<ProductModel> products = [
    const ProductModel(
      productId: 'p_uniform_1',
      name: 'DPS School Shirt',
      description: 'White cotton shirt',
      categoryId: 'cat_uniforms',
      schoolId: 'sch_1',
      schoolName: 'DPS',
      targetGrade: 'Class 5',
      basePrice: 500.0,
      inStock: true,
      isFeatured: true,
    ),
    const ProductModel(
      productId: 'p_uniform_2',
      name: 'DPS School Blazer',
      description: 'Woolen winter blazer',
      categoryId: 'cat_uniforms',
      schoolId: 'sch_1',
      schoolName: 'DPS',
      targetGrade: 'Class 5',
      basePrice: 2000.0,
      discountPrice: 1800.0,
      inStock: false, // Out of stock
      isFeatured: true,
    ),
    const ProductModel(
      productId: 'p_book_1',
      name: 'Mathematics Class 5',
      description: 'NCERT Textbook',
      categoryId: 'cat_books',
      schoolId: 'sch_1',
      schoolName: 'DPS',
      targetGrade: 'Class 5',
      basePrice: 250.0,
      inStock: true,
      isFeatured: false,
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
    var list = List<ProductModel>.from(products);
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (schoolId != null && schoolId.isNotEmpty) {
      list = list.where((p) => p.schoolId == schoolId).toList();
    }
    if (grade != null && grade.isNotEmpty) {
      list = list.where((p) => p.targetGrade == grade).toList();
    }
    if (featuredOnly == true) {
      list = list.where((p) => p.isFeatured).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              p.description.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
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
    try {
      return products.firstWhere((p) => p.productId == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<ProductModel?> watchProductById(String id) => Stream.value(null);

  @override
  Future<List<SchoolModel>> fetchSchools() async => const [];

  @override
  Stream<List<SchoolModel>> watchSchools() => const Stream.empty();
}

void main() {
  group('CatalogFilterNotifier Tests', () {
    test('initial state has clean default values', () {
      final notifier = CatalogFilterNotifier();
      expect(notifier.state.categoryId, isNull);
      expect(notifier.state.schoolId, isNull);
      expect(notifier.state.schoolName, isNull);
      expect(notifier.state.grade, isNull);
      expect(notifier.state.searchQuery, isEmpty);
      expect(notifier.state.minPrice, isNull);
      expect(notifier.state.maxPrice, isNull);
      expect(notifier.state.inStockOnly, isFalse);
      expect(notifier.state.sort, equals(SortOption.relevance));
      expect(notifier.state.hasActiveFilters, isFalse);
    });

    test('mutates category, school, grade, price range, and sort state', () {
      final notifier = CatalogFilterNotifier();

      notifier.setCategory('cat_uniforms');
      expect(notifier.state.categoryId, equals('cat_uniforms'));
      expect(notifier.state.hasActiveFilters, isTrue);

      notifier.setSchool(schoolId: 'sch_dps', schoolName: 'Delhi Public School');
      expect(notifier.state.schoolId, equals('sch_dps'));
      expect(notifier.state.schoolName, equals('Delhi Public School'));

      notifier.setGrade('Class 5');
      expect(notifier.state.grade, equals('Class 5'));

      notifier.setPriceRange(min: 200, max: 1500);
      expect(notifier.state.minPrice, equals(200));
      expect(notifier.state.maxPrice, equals(1500));

      notifier.setInStockOnly(true);
      expect(notifier.state.inStockOnly, isTrue);

      notifier.setSort(SortOption.priceLowToHigh);
      expect(notifier.state.sort, equals(SortOption.priceLowToHigh));

      // Reset
      notifier.resetFilters();
      expect(notifier.state.hasActiveFilters, isFalse);
      expect(notifier.state.categoryId, isNull);
    });

    test('search term debouncing updates state after duration expires', () async {
      final notifier = CatalogFilterNotifier();

      // Fast typing simulation
      notifier.setSearchQuery('b', debounceDuration: const Duration(milliseconds: 50));
      notifier.setSearchQuery('bl', debounceDuration: const Duration(milliseconds: 50));
      notifier.setSearchQuery('blazer', debounceDuration: const Duration(milliseconds: 50));

      // Immediate state is still empty
      expect(notifier.state.searchQuery, isEmpty);

      // Await debounce expiry
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(notifier.state.searchQuery, equals('blazer'));

      // Instant update when duration is Duration.zero
      notifier.setSearchQuery('tie', debounceDuration: Duration.zero);
      expect(notifier.state.searchQuery, equals('tie'));
    });
  });

  group('Reactive Catalog Providers Tests', () {
    late MockCatalogRepoForController mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockCatalogRepoForController();
      container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('categoriesProvider fetches category taxonomy', () async {
      final categories = await container.read(categoriesProvider.future);
      expect(categories, hasLength(2));
      expect(categories.first.name, equals('Uniforms'));
    });

    test('featuredProductsProvider fetches only featured products', () async {
      final featured = await container.read(featuredProductsProvider.future);
      expect(featured, hasLength(2));
      expect(featured.every((p) => p.isFeatured), isTrue);
    });

    test('filteredProductsProvider reacts to category filter changes', () async {
      // 1. Initial (all products)
      final all = await container.read(filteredProductsProvider.future);
      expect(all, hasLength(3));

      // 2. Select category 'cat_books'
      container.read(catalogFilterProvider.notifier).setCategory('cat_books');
      final books = await container.read(filteredProductsProvider.future);
      expect(books, hasLength(1));
      expect(books.first.productId, equals('p_book_1'));
    });

    test('filteredProductsProvider applies inStockOnly filter', () async {
      // Set category to uniforms (has 1 in stock, 1 out of stock)
      container.read(catalogFilterProvider.notifier).setCategory('cat_uniforms');
      final withOos = await container.read(filteredProductsProvider.future);
      expect(withOos, hasLength(2));

      // Enable inStockOnly
      container.read(catalogFilterProvider.notifier).setInStockOnly(true);
      final inStockOnly = await container.read(filteredProductsProvider.future);
      expect(inStockOnly, hasLength(1));
      expect(inStockOnly.first.productId, equals('p_uniform_1'));
    });

    test('filteredProductsProvider applies price range constraints', () async {
      // Set price range between 300 and 1000
      container.read(catalogFilterProvider.notifier).setPriceRange(min: 300, max: 1000);
      final range = await container.read(filteredProductsProvider.future);
      expect(range, hasLength(1));
      expect(range.first.productId, equals('p_uniform_1')); // 500.0
    });

    test('productDetailProvider fetches single product by ID', () async {
      final product = await container.read(productDetailProvider('p_uniform_1').future);
      expect(product, isNotNull);
      expect(product?.name, equals('DPS School Shirt'));

      final nonExistent = await container.read(productDetailProvider('unknown').future);
      expect(nonExistent, isNull);
    });
  });
}
