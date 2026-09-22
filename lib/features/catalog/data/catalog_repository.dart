import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category_model.dart';
import '../domain/product_model.dart';
import '../domain/school_model.dart';

/// Available sorting options for product catalog browsing.
enum SortOption {
  relevance,
  priceLowToHigh,
  priceHighToLow,
  ratingHighToLow,
  newest,
  biggestDiscount,
}

/// Abstract contract for Catalog, Products, and Category data access.
abstract class ICatalogRepository {
  Future<List<CategoryModel>> fetchCategories();
  Stream<List<CategoryModel>> watchCategories();

  Future<List<ProductModel>> fetchProducts({
    String? categoryId,
    String? school,
    String? schoolId,
    String? grade,
    String? searchQuery,
    SortOption? sort,
    bool? featuredOnly,
    int? limit,
  });

  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    String? school,
    String? schoolId,
    String? grade,
    String? searchQuery,
    SortOption? sort,
    bool? featuredOnly,
    int? limit,
  });

  Future<ProductModel?> fetchProductById(String id);
  Stream<ProductModel?> watchProductById(String id);

  Future<List<SchoolModel>> fetchSchools();
  Stream<List<SchoolModel>> watchSchools();
}

/// Cloud Firestore implementation of [ICatalogRepository] with offline caching support.
class FirestoreCatalogRepository implements ICatalogRepository {
  final FirebaseFirestore _firestore;

  FirestoreCatalogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _schoolsCollection =>
      _firestore.collection('schools');

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    final snapshot = await _categoriesCollection
        .orderBy('displayOrder', descending: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      if (!data.containsKey('categoryId') || (data['categoryId'] as String).isEmpty) {
        data['categoryId'] = doc.id;
      }
      return CategoryModel.fromJson(data);
    }).toList();
  }

  @override
  Stream<List<CategoryModel>> watchCategories() {
    return _categoriesCollection
        .orderBy('displayOrder', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              if (!data.containsKey('categoryId') || (data['categoryId'] as String).isEmpty) {
                data['categoryId'] = doc.id;
              }
              return CategoryModel.fromJson(data);
            }).toList());
  }

  Query<Map<String, dynamic>> _buildProductsQuery({
    String? categoryId,
    String? school,
    String? schoolId,
    String? grade,
    SortOption? sort,
    bool? featuredOnly,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query =
        _productsCollection.where('isActive', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.where('schoolId', isEqualTo: schoolId);
    } else if (school != null && school.isNotEmpty) {
      query = query.where('schoolName', isEqualTo: school);
    }
    if (grade != null && grade.isNotEmpty) {
      query = query.where('targetGrade', isEqualTo: grade);
    }
    if (featuredOnly == true) {
      query = query.where('isFeatured', isEqualTo: true);
    }

    // Ordering
    switch (sort) {
      case SortOption.priceLowToHigh:
        query = query.orderBy('basePrice', descending: false);
        break;
      case SortOption.priceHighToLow:
        query = query.orderBy('basePrice', descending: true);
        break;
      case SortOption.ratingHighToLow:
        query = query.orderBy('rating', descending: true);
        break;
      case SortOption.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
      case SortOption.biggestDiscount:
      case SortOption.relevance:
      case null:
        // Default index ordering (in-memory sort for biggest discount)
        break;
    }

    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }

    return query;
  }

  List<ProductModel> _filterBySearch(List<ProductModel> items, String? searchQuery) {
    if (searchQuery == null || searchQuery.trim().isEmpty) {
      return items;
    }
    final query = searchQuery.trim().toLowerCase();
    return items.where((item) {
      final nameMatches = item.name.toLowerCase().contains(query);
      final descMatches = item.description.toLowerCase().contains(query);
      final schoolMatches =
          item.schoolName?.toLowerCase().contains(query) ?? false;
      return nameMatches || descMatches || schoolMatches;
    }).toList();
  }

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
    final query = _buildProductsQuery(
      categoryId: categoryId,
      school: school,
      schoolId: schoolId,
      grade: grade,
      sort: sort,
      featuredOnly: featuredOnly,
      limit: limit,
    );

    try {
      final snapshot = await query.get();
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('productId') ||
            (data['productId'] as String).isEmpty) {
          data['productId'] = doc.id;
        }
        return ProductModel.fromJson(data);
      }).toList();

      return _filterBySearch(items, searchQuery);
    } catch (_) {
      // Fallback: Fetch products without complex compound indexes and filter in memory
      try {
        final fallbackSnapshot = await _productsCollection.get();
        var items = fallbackSnapshot.docs.map((doc) {
          final data = doc.data();
          if (!data.containsKey('productId') ||
              (data['productId'] as String).isEmpty) {
            data['productId'] = doc.id;
          }
          return ProductModel.fromJson(data);
        }).where((p) => p.isActive).toList();

        if (categoryId != null && categoryId.isNotEmpty) {
          final catLower = categoryId.toLowerCase();
          items = items
              .where((p) =>
                  p.categoryId.toLowerCase() == catLower ||
                  p.categoryId.toLowerCase().contains(catLower) ||
                  catLower.contains(p.categoryId.toLowerCase()))
              .toList();
        }
        if (schoolId != null && schoolId.isNotEmpty) {
          items = items.where((p) => p.schoolId == schoolId).toList();
        } else if (school != null && school.isNotEmpty) {
          items = items
              .where((p) =>
                  p.schoolName?.toLowerCase() == school.toLowerCase())
              .toList();
        }
        if (grade != null && grade.isNotEmpty) {
          items = items
              .where((p) =>
                  p.targetGrade?.toLowerCase() == grade.toLowerCase())
              .toList();
        }
        return _filterBySearch(items, searchQuery);
      } catch (fallbackError) {
        rethrow;
      }
    }
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
  }) {
    final query = _buildProductsQuery(
      categoryId: categoryId,
      school: school,
      schoolId: schoolId,
      grade: grade,
      sort: sort,
      featuredOnly: featuredOnly,
      limit: limit,
    );

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('productId') || (data['productId'] as String).isEmpty) {
          data['productId'] = doc.id;
        }
        return ProductModel.fromJson(data);
      }).toList();

      return _filterBySearch(items, searchQuery);
    });
  }

  @override
  Future<ProductModel?> fetchProductById(String id) async {
    final doc = await _productsCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    if (!data.containsKey('productId') || (data['productId'] as String).isEmpty) {
      data['productId'] = doc.id;
    }
    return ProductModel.fromJson(data);
  }

  @override
  Stream<ProductModel?> watchProductById(String id) {
    return _productsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      if (!data.containsKey('productId') || (data['productId'] as String).isEmpty) {
        data['productId'] = doc.id;
      }
      return ProductModel.fromJson(data);
    });
  }

  @override
  Future<List<SchoolModel>> fetchSchools() async {
    final snapshot = await _schoolsCollection.orderBy('name').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      if (!data.containsKey('schoolId') || (data['schoolId'] as String).isEmpty) {
        data['schoolId'] = doc.id;
      }
      return SchoolModel.fromJson(data);
    }).toList();
  }

  @override
  Stream<List<SchoolModel>> watchSchools() {
    return _schoolsCollection.orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) {
          final data = doc.data();
          if (!data.containsKey('schoolId') || (data['schoolId'] as String).isEmpty) {
            data['schoolId'] = doc.id;
          }
          return SchoolModel.fromJson(data);
        }).toList());
  }
}

/// Global Riverpod provider for Catalog Repository.
final catalogRepositoryProvider = Provider<ICatalogRepository>((ref) {
  return FirestoreCatalogRepository();
});
