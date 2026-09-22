import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/catalog/data/catalog_repository.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/school_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';

class MockCatalogRepository implements ICatalogRepository {
  final List<CategoryModel> _categories = [
    const CategoryModel(
      categoryId: 'cat_uniforms',
      name: 'School Uniforms',
      iconUrl: 'uniforms.png',
      displayOrder: 1,
    ),
    const CategoryModel(
      categoryId: 'cat_textbooks',
      name: 'Textbooks & Workbooks',
      iconUrl: 'books.png',
      displayOrder: 2,
    ),
    const CategoryModel(
      categoryId: 'cat_stationery',
      name: 'Stationery & Art',
      iconUrl: 'pens.png',
      displayOrder: 3,
    ),
  ];

  final List<ProductModel> _products = [
    const ProductModel(
      productId: 'prod_1',
      name: 'DPS Winter Blazer (Woolen)',
      description: 'Navy blue school blazer with crest',
      categoryId: 'cat_uniforms',
      schoolId: 'sch_dps',
      schoolName: 'Delhi Public School',
      targetGrade: 'Class 9',
      basePrice: 2200.0,
      discountPrice: 1999.0,
      rating: 4.8,
      reviewCount: 35,
      isFeatured: true,
      variants: [
        VariantModel(
          variantId: 'v_34',
          sku: 'DPS-BLZ-34',
          label: 'Size 34',
          price: 1999.0,
          stock: 10,
        ),
      ],
    ),
    const ProductModel(
      productId: 'prod_2',
      name: 'Standard Class 5 NCERT Textbook Set',
      description: 'Complete set of 5 textbooks for class 5',
      categoryId: 'cat_textbooks',
      schoolId: 'sch_dps',
      schoolName: 'Delhi Public School',
      targetGrade: 'Class 5',
      basePrice: 1400.0,
      rating: 4.9,
      reviewCount: 50,
      isFeatured: false,
    ),
    const ProductModel(
      productId: 'prod_3',
      name: 'Classmate Spiral Notebook 6-Pack',
      description: 'Ruled 300-page notebook pack',
      categoryId: 'cat_stationery',
      basePrice: 360.0,
      discountPrice: 320.0,
      rating: 4.6,
      reviewCount: 120,
      isFeatured: true,
    ),
  ];

  final List<SchoolModel> _schools = [
    const SchoolModel(
      schoolId: 'sch_dps',
      name: 'Delhi Public School, R.K. Puram',
      city: 'New Delhi',
      logoUrl: 'dps.png',
      grades: ['Class 1', 'Class 5', 'Class 9'],
    ),
  ];

  final _categoryStreamController =
      StreamController<List<CategoryModel>>.broadcast();
  final _productStreamController =
      StreamController<List<ProductModel>>.broadcast();

  @override
  Future<List<CategoryModel>> fetchCategories() async => _categories;

  @override
  Stream<List<CategoryModel>> watchCategories() =>
      _categoryStreamController.stream;

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
    var items = List<ProductModel>.from(_products);

    if (categoryId != null && categoryId.isNotEmpty) {
      items = items.where((p) => p.categoryId == categoryId).toList();
    }
    if (schoolId != null && schoolId.isNotEmpty) {
      items = items.where((p) => p.schoolId == schoolId).toList();
    } else if (school != null && school.isNotEmpty) {
      items = items.where((p) => p.schoolName == school).toList();
    }
    if (grade != null && grade.isNotEmpty) {
      items = items.where((p) => p.targetGrade == grade).toList();
    }
    if (featuredOnly == true) {
      items = items.where((p) => p.isFeatured).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      items = items.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            (p.schoolName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (sort != null) {
      switch (sort) {
        case SortOption.priceLowToHigh:
          items.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
          break;
        case SortOption.priceHighToLow:
          items.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
          break;
        case SortOption.ratingHighToLow:
          items.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        default:
          break;
      }
    }

    if (limit != null && limit > 0 && items.length > limit) {
      items = items.sublist(0, limit);
    }

    return items;
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
      _productStreamController.stream;

  @override
  Future<ProductModel?> fetchProductById(String id) async {
    try {
      return _products.firstWhere((p) => p.productId == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<ProductModel?> watchProductById(String id) {
    return _productStreamController.stream.map((list) {
      try {
        return list.firstWhere((p) => p.productId == id);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<List<SchoolModel>> fetchSchools() async => _schools;

  @override
  Stream<List<SchoolModel>> watchSchools() => const Stream.empty();

  void emitCategories(List<CategoryModel> categories) {
    _categoryStreamController.add(categories);
  }

  void emitProducts(List<ProductModel> products) {
    _productStreamController.add(products);
  }

  void dispose() {
    _categoryStreamController.close();
    _productStreamController.close();
  }
}

void main() {
  group('CatalogRepository Contract & Filter Tests', () {
    late MockCatalogRepository repo;

    setUp(() {
      repo = MockCatalogRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('fetchCategories returns ordered list of categories', () async {
      final categories = await repo.fetchCategories();
      expect(categories, hasLength(3));
      expect(categories.first.name, equals('School Uniforms'));
      expect(categories.last.name, equals('Stationery & Art'));
    });

    test('fetchProducts filters by categoryId correctly', () async {
      final uniforms = await repo.fetchProducts(categoryId: 'cat_uniforms');
      expect(uniforms, hasLength(1));
      expect(uniforms.first.productId, equals('prod_1'));

      final textbooks = await repo.fetchProducts(categoryId: 'cat_textbooks');
      expect(textbooks, hasLength(1));
      expect(textbooks.first.productId, equals('prod_2'));
    });

    test('fetchProducts filters by school and targetGrade', () async {
      final class9Uniforms = await repo.fetchProducts(
        schoolId: 'sch_dps',
        grade: 'Class 9',
      );
      expect(class9Uniforms, hasLength(1));
      expect(class9Uniforms.first.name, contains('DPS Winter Blazer'));

      final nonExistent = await repo.fetchProducts(
        schoolId: 'sch_dps',
        grade: 'Class 12',
      );
      expect(nonExistent, isEmpty);
    });

    test('fetchProducts filters by isFeatured flag', () async {
      final featured = await repo.fetchProducts(featuredOnly: true);
      expect(featured, hasLength(2));
      expect(featured.every((p) => p.isFeatured), isTrue);
    });

    test('fetchProducts performs case-insensitive text search matching name and description',
        () async {
      final searchSpiral = await repo.fetchProducts(searchQuery: 'spiral');
      expect(searchSpiral, hasLength(1));
      expect(searchSpiral.first.productId, equals('prod_3'));

      final searchBlazer = await repo.fetchProducts(searchQuery: 'BLAZER');
      expect(searchBlazer, hasLength(1));
      expect(searchBlazer.first.productId, equals('prod_1'));
    });

    test('fetchProducts sorts by price low to high and high to low', () async {
      final lowToHigh =
          await repo.fetchProducts(sort: SortOption.priceLowToHigh);
      expect(lowToHigh.first.effectivePrice, equals(320.0)); // Notebooks
      expect(lowToHigh.last.effectivePrice, equals(1999.0)); // Blazer

      final highToLow =
          await repo.fetchProducts(sort: SortOption.priceHighToLow);
      expect(highToLow.first.effectivePrice, equals(1999.0));
      expect(highToLow.last.effectivePrice, equals(320.0));
    });

    test('fetchProducts respects limit constraint', () async {
      final limited = await repo.fetchProducts(limit: 2);
      expect(limited, hasLength(2));
    });

    test('fetchProductById returns matching product or null', () async {
      final product = await repo.fetchProductById('prod_1');
      expect(product, isNotNull);
      expect(product?.name, equals('DPS Winter Blazer (Woolen)'));

      final missing = await repo.fetchProductById('non_existent_id');
      expect(missing, isNull);
    });

    test('watchCategories emits updates via stream subscription', () async {
      final emitted = <List<CategoryModel>>[];
      final sub = repo.watchCategories().listen((cats) => emitted.add(cats));

      repo.emitCategories([
        const CategoryModel(
          categoryId: 'cat_new',
          name: 'Sports Gear',
          iconUrl: 'sports.png',
        ),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emitted, hasLength(1));
      expect(emitted.first.first.name, equals('Sports Gear'));

      await sub.cancel();
    });

    test('fetchSchools returns affiliated school list', () async {
      final schools = await repo.fetchSchools();
      expect(schools, hasLength(1));
      expect(schools.first.name, contains('Delhi Public School'));
    });

    test('Riverpod catalogRepositoryProvider provides ICatalogRepository instance',
        () {
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final instance = container.read(catalogRepositoryProvider);
      expect(instance, isA<ICatalogRepository>());
      container.dispose();
    });
  });
}
