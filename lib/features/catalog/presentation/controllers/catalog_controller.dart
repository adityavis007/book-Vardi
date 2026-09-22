import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/catalog_repository.dart';
import '../../domain/category_model.dart';
import '../../domain/product_model.dart';
import '../../domain/school_model.dart';
import '../../../location/presentation/controllers/location_controller.dart';

/// Immutable state holding active catalog filters, search keywords, and sorting.
@immutable
class CatalogFilterState {
  final String? categoryId;
  final String? schoolId;
  final String? schoolName;
  final String? grade;
  final String searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;
  final bool outOfStockOnly;
  final double? minRating;
  final bool saleOnly;
  final SortOption sort;

  const CatalogFilterState({
    this.categoryId,
    this.schoolId,
    this.schoolName,
    this.grade,
    this.searchQuery = '',
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.outOfStockOnly = false,
    this.minRating,
    this.saleOnly = false,
    this.sort = SortOption.relevance,
  });

  bool get hasActiveFilters =>
      categoryId != null ||
      schoolId != null ||
      schoolName != null ||
      grade != null ||
      searchQuery.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      inStockOnly ||
      outOfStockOnly ||
      minRating != null ||
      saleOnly ||
      sort != SortOption.relevance;

  int get activeFiltersCount {
    int count = 0;
    if (sort != SortOption.relevance) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minRating != null) count++;
    if (inStockOnly || outOfStockOnly) count++;
    if (saleOnly) count++;
    if (categoryId != null && categoryId!.isNotEmpty) count++;
    if (schoolId != null || schoolName != null) count++;
    if (grade != null && grade!.isNotEmpty) count++;
    return count;
  }

  CatalogFilterState copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? schoolId,
    String? schoolName,
    bool clearSchool = false,
    String? grade,
    bool clearGrade = false,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    bool clearPriceRange = false,
    bool? inStockOnly,
    bool? outOfStockOnly,
    double? minRating,
    bool clearMinRating = false,
    bool? saleOnly,
    SortOption? sort,
  }) {
    return CatalogFilterState(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      schoolId: clearSchool ? null : (schoolId ?? this.schoolId),
      schoolName: clearSchool ? null : (schoolName ?? this.schoolName),
      grade: clearGrade ? null : (grade ?? this.grade),
      searchQuery: searchQuery ?? this.searchQuery,
      minPrice: clearPriceRange ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPriceRange ? null : (maxPrice ?? this.maxPrice),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      outOfStockOnly: outOfStockOnly ?? this.outOfStockOnly,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      saleOnly: saleOnly ?? this.saleOnly,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogFilterState &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          schoolId == other.schoolId &&
          schoolName == other.schoolName &&
          grade == other.grade &&
          searchQuery == other.searchQuery &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice &&
          inStockOnly == other.inStockOnly &&
          outOfStockOnly == other.outOfStockOnly &&
          minRating == other.minRating &&
          saleOnly == other.saleOnly &&
          sort == other.sort;

  @override
  int get hashCode =>
      categoryId.hashCode ^
      schoolId.hashCode ^
      schoolName.hashCode ^
      grade.hashCode ^
      searchQuery.hashCode ^
      minPrice.hashCode ^
      maxPrice.hashCode ^
      inStockOnly.hashCode ^
      outOfStockOnly.hashCode ^
      minRating.hashCode ^
      saleOnly.hashCode ^
      sort.hashCode;

  @override
  String toString() =>
      'CatalogFilterState(category: $categoryId, school: $schoolName, grade: $grade, search: "$searchQuery", sort: ${sort.name}, rating: $minRating, sale: $saleOnly)';
}

/// StateNotifier managing filter mutations and search term debounce.
class CatalogFilterNotifier extends StateNotifier<CatalogFilterState> {
  Timer? _debounceTimer;
  final Duration defaultDebounceDuration;

  CatalogFilterNotifier({
    this.defaultDebounceDuration = const Duration(milliseconds: 300),
  }) : super(const CatalogFilterState());

  void setCategory(String? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null || categoryId.isEmpty,
    );
  }

  void setSchool({String? schoolId, String? schoolName}) {
    state = state.copyWith(
      schoolId: schoolId,
      schoolName: schoolName,
      clearSchool: (schoolId == null || schoolId.isEmpty) &&
          (schoolName == null || schoolName.isEmpty),
    );
  }

  void setGrade(String? grade) {
    state = state.copyWith(
      grade: grade,
      clearGrade: grade == null || grade.isEmpty,
    );
  }

  /// Updates search query with reactive debounce (default 300ms, or 0ms for synchronous update)
  void setSearchQuery(String query, {Duration? debounceDuration}) {
    _debounceTimer?.cancel();
    final duration = debounceDuration ?? defaultDebounceDuration;
    if (duration == Duration.zero) {
      state = state.copyWith(searchQuery: query.trim());
      return;
    }
    _debounceTimer = Timer(duration, () {
      state = state.copyWith(searchQuery: query.trim());
    });
  }

  void setPriceRange({double? min, double? max}) {
    state = state.copyWith(
      minPrice: min,
      maxPrice: max,
      clearPriceRange: min == null && max == null,
    );
  }

  void setInStockOnly(bool inStockOnly) {
    state = state.copyWith(
      inStockOnly: inStockOnly,
      outOfStockOnly: inStockOnly ? false : state.outOfStockOnly,
    );
  }

  void setAvailability({bool inStockOnly = false, bool outOfStockOnly = false}) {
    state = state.copyWith(
      inStockOnly: inStockOnly,
      outOfStockOnly: outOfStockOnly,
    );
  }

  void setMinRating(double? rating) {
    state = state.copyWith(
      minRating: rating,
      clearMinRating: rating == null,
    );
  }

  void setSaleOnly(bool saleOnly) {
    state = state.copyWith(saleOnly: saleOnly);
  }

  void setSort(SortOption sort) {
    state = state.copyWith(sort: sort);
  }

  void resetFilters() {
    _debounceTimer?.cancel();
    state = const CatalogFilterState();
  }

  void applyState(CatalogFilterState newState) {
    state = newState;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for managing filter criteria and reactive search debounce
final catalogFilterProvider =
    StateNotifierProvider<CatalogFilterNotifier, CatalogFilterState>((ref) {
  return CatalogFilterNotifier();
});

/// Provider fetching categories asynchronously
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.fetchCategories();
});

/// Provider fetching featured products for home discovery
final featuredProductsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.fetchProducts(featuredOnly: true);
});

/// Reactive filtered products provider reflecting all active criteria in [catalogFilterProvider]
final filteredProductsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final filter = ref.watch(catalogFilterProvider);

  final products = await repo.fetchProducts(
    categoryId: filter.categoryId,
    schoolId: filter.schoolId,
    school: filter.schoolName,
    grade: filter.grade,
    searchQuery: filter.searchQuery,
    sort: filter.sort,
  );

  final filtered = products.where((p) {
    if (filter.inStockOnly && !p.inStock) {
      return false;
    }
    if (filter.outOfStockOnly && p.inStock) {
      return false;
    }
    if (filter.minPrice != null && p.effectivePrice < filter.minPrice!) {
      return false;
    }
    if (filter.maxPrice != null && p.effectivePrice > filter.maxPrice!) {
      return false;
    }
    if (filter.minRating != null && p.rating < filter.minRating!) {
      return false;
    }
    if (filter.saleOnly && !p.hasDiscount) {
      return false;
    }
    return true;
  }).toList();

  if (filter.sort == SortOption.biggestDiscount) {
    filtered.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
  }

  return filtered;
});

/// Provider fetching product details by product ID
final productDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.fetchProductById(id);
});

/// Provider fetching affiliated schools
final schoolsProvider = FutureProvider<List<SchoolModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.fetchSchools();
});

/// Provider fetching recommended bundles (e.g. Class kits, uniform sets)
final recommendedBundlesProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final all = await repo.fetchProducts();
  final filter = ref.watch(catalogFilterProvider);
  final location = ref.watch(selectedLocationProvider);

  // If school is selected, prioritize bundles for that school
  if (filter.schoolName != null && filter.schoolName!.isNotEmpty) {
    final schoolBundles = all
        .where((p) =>
            (p.schoolName ?? '').toLowerCase() ==
            filter.schoolName!.toLowerCase())
        .toList();
    if (schoolBundles.isNotEmpty) return schoolBundles;
  }

  // Filter or prioritize bundles matching selected location city
  final bundles = all
      .where((p) =>
          p.categoryId.toLowerCase().contains('bundle') ||
          p.name.toLowerCase().contains('bundle') ||
          p.name.toLowerCase().contains('set') ||
          p.name.toLowerCase().contains('kit'))
      .toList();

  if (bundles.isNotEmpty) {
    // Sort bundles: if product has school matching location city, prioritize
    final locCity = location.city.toLowerCase();
    bundles.sort((a, b) {
      final aCityMatch = (a.schoolName ?? '').toLowerCase().contains(locCity);
      final bCityMatch = (b.schoolName ?? '').toLowerCase().contains(locCity);
      if (aCityMatch && !bCityMatch) return -1;
      if (!aCityMatch && bCityMatch) return 1;
      return 0;
    });
    return bundles;
  }
  return all.take(4).toList();
});
