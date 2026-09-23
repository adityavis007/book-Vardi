import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/stationery_background.dart';
import '../../data/catalog_repository.dart';
import '../../domain/product_model.dart';
import '../controllers/catalog_controller.dart';
import '../widgets/filter_modal.dart';
import '../widgets/product_card.dart';

/// Full-featured Search & Filtering Screen supporting instant debounced search,
/// active filter tags, responsive 2-column catalog grid, and quick sort.
class SearchScreen extends ConsumerStatefulWidget {
  final ValueChanged<String>? onProductTap;
  final VoidCallback? onBackTap;
  final Duration? debounceDuration;
  final bool autoFocus;

  const SearchScreen({
    super.key,
    this.onProductTap,
    this.onBackTap,
    this.debounceDuration,
    this.autoFocus = false,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(catalogFilterProvider).searchQuery;
    _searchController = TextEditingController(text: initialQuery);
    _focusNode = FocusNode();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(catalogFilterProvider.notifier).setSearchQuery(
          query,
          debounceDuration:
              widget.debounceDuration ?? const Duration(milliseconds: 300),
        );
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(catalogFilterProvider.notifier).setSearchQuery(
          '',
          debounceDuration: Duration.zero,
        );
    setState(() {});
  }

  int _calculateActiveFilterCount(CatalogFilterState filter) {
    var count = 0;
    if (filter.categoryId != null) count++;
    if (filter.schoolId != null || filter.schoolName != null) count++;
    if (filter.grade != null) count++;
    if (filter.minPrice != null || filter.maxPrice != null) count++;
    if (filter.inStockOnly) count++;
    if (filter.sort != SortOption.relevance) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(catalogFilterProvider);
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final activeFilterCount = _calculateActiveFilterCount(filterState);

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      body: StationeryBackground(
        child: SafeArea(
          child: Column(
          children: [
            // Accessible anchor for screen identification
            const SizedBox(
              height: 0,
              width: 0,
              child: Opacity(
                opacity: 0.0,
                child: Text('Search Screen'),
              ),
            ),

            // 1. Top Search Header
            _buildTopSearchBar(context, activeFilterCount),

            // 2. Active Filters Pill Rail (if any filter is active)
            if (activeFilterCount > 0 || filterState.searchQuery.isNotEmpty)
              _buildActiveFiltersRail(filterState),

            // 3. Results count & quick sort bar
            _buildResultsHeader(filteredProductsAsync, filterState),

            const Divider(height: 1.0, color: AppColors.borderGray),

            // 4. Products Grid / States
            Expanded(
              child: _buildProductsContent(filteredProductsAsync),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTopSearchBar(BuildContext context, int activeFilterCount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.surfaceWhite,
      child: Row(
        children: [
          // Back Button
          IconButton(
            key: const Key('search_back_button'),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.primaryNavy,
            ),
            onPressed: () {
              if (widget.onBackTap != null) {
                widget.onBackTap!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/');
              }
            },
          ),

          // Search Input
          Expanded(
            child: Container(
              height: 44.0,
              decoration: BoxDecoration(
                color: AppColors.backgroundSlate,
                borderRadius: AppSpacing.roundedSmall,
                border: Border.all(color: AppColors.borderGray),
              ),
              child: TextField(
                key: const Key('search_text_field'),
                controller: _searchController,
                focusNode: _focusNode,
                style: AppTypography.bodyRegular.copyWith(
                  color: AppColors.textDark,
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (query) {
                  ref.read(catalogFilterProvider.notifier).setSearchQuery(
                        query,
                        debounceDuration: Duration.zero,
                      );
                },
                decoration: InputDecoration(
                  hintText: 'Search books, uniforms, stationery...',
                  hintStyle: AppTypography.bodyRegular.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.0,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primaryNavy,
                    size: 20.0,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          key: const Key('search_clear_button'),
                          icon: const Icon(
                            Icons.cancel,
                            color: AppColors.textSecondary,
                            size: 18.0,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 12.0,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          // Filter Trigger Button with Badge Counter
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                key: const Key('search_filter_modal_btn'),
                icon: const Icon(
                  Icons.tune,
                  color: AppColors.primaryNavy,
                ),
                onPressed: () => FilterModal.show(context),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryAmber,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18.0,
                      minHeight: 18.0,
                    ),
                    child: Center(
                      child: Text(
                        '$activeFilterCount',
                        style: AppTypography.micro.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRail(CatalogFilterState filter) {
    final categoriesAsync = ref.watch(categoriesProvider);
    String? categoryName;
    if (filter.categoryId != null) {
      categoriesAsync.whenData((cats) {
        final match = cats.where((c) => c.categoryId == filter.categoryId);
        if (match.isNotEmpty) categoryName = match.first.name;
      });
    }

    final chips = <Widget>[];

    // Search query tag
    if (filter.searchQuery.isNotEmpty) {
      chips.add(_buildFilterTag(
        key: const Key('tag_search_query'),
        label: '"${filter.searchQuery}"',
        onRemove: _clearSearch,
      ));
    }

    // Category tag
    if (filter.categoryId != null) {
      chips.add(_buildFilterTag(
        key: const Key('tag_category'),
        label: categoryName ?? 'Category',
        onRemove: () {
          ref.read(catalogFilterProvider.notifier).setCategory(null);
        },
      ));
    }

    // School tag
    if (filter.schoolName != null) {
      chips.add(_buildFilterTag(
        key: const Key('tag_school'),
        label: filter.schoolName!,
        onRemove: () {
          ref.read(catalogFilterProvider.notifier).setSchool();
        },
      ));
    }

    // Grade tag
    if (filter.grade != null) {
      chips.add(_buildFilterTag(
        key: const Key('tag_grade'),
        label: filter.grade!,
        onRemove: () {
          ref.read(catalogFilterProvider.notifier).setGrade(null);
        },
      ));
    }

    // Price tag
    if (filter.minPrice != null || filter.maxPrice != null) {
      final minP = filter.minPrice?.round() ?? 0;
      final maxP = filter.maxPrice?.round() ?? 5000;
      chips.add(_buildFilterTag(
        key: const Key('tag_price'),
        label: '₹$minP - ₹$maxP',
        onRemove: () {
          ref.read(catalogFilterProvider.notifier).setPriceRange();
        },
      ));
    }

    // In-Stock tag
    if (filter.inStockOnly) {
      chips.add(_buildFilterTag(
        key: const Key('tag_in_stock'),
        label: 'In-Stock Only',
        onRemove: () {
          ref.read(catalogFilterProvider.notifier).setInStockOnly(false);
        },
      ));
    }

    // Sort tag (if non-default)
    if (filter.sort != SortOption.relevance) {
      chips.add(_buildFilterTag(
        key: const Key('tag_sort'),
        label: _getSortLabel(filter.sort),
        onRemove: () {
          ref.read(catalogFilterProvider.notifier).setSort(SortOption.relevance);
        },
      ));
    }

    return Container(
      width: double.infinity,
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            ...chips,
            TextButton(
              key: const Key('search_clear_all_tags_btn'),
              onPressed: () {
                _searchController.clear();
                ref.read(catalogFilterProvider.notifier).resetFilters();
              },
              child: Text(
                'Clear All',
                style: AppTypography.caption.copyWith(
                  color: AppColors.destructiveRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTag({
    required Key key,
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedFull,
        border: Border.all(
          color: AppColors.primaryNavy.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4.0),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14.0,
              color: AppColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(
    AsyncValue<List<ProductModel>> productsAsync,
    CatalogFilterState filter,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.surfaceWhite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: productsAsync.when(
              data: (products) => Text(
                '${products.length} ${products.length == 1 ? "product" : "products"} found',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => Text(
                'Searching products...',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              error: (_, __) => Text(
                '0 products',
                style: AppTypography.caption.copyWith(
                  color: AppColors.destructiveRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<SortOption>(
            key: const Key('quick_sort_button'),
            initialValue: filter.sort,
            onSelected: (sort) {
              ref.read(catalogFilterProvider.notifier).setSort(sort);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sort,
                  size: 16.0,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 4.0),
                Text(
                  _getSortLabel(filter.sort),
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18.0,
                  color: AppColors.primaryNavy,
                ),
              ],
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.relevance,
                child: Text('Popularity'),
              ),
              const PopupMenuItem(
                value: SortOption.priceLowToHigh,
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: SortOption.priceHighToLow,
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem(
                value: SortOption.ratingHighToLow,
                child: Text('Customer Rating'),
              ),
              const PopupMenuItem(
                value: SortOption.newest,
                child: Text('Newest Arrivals'),
              ),
              const PopupMenuItem(
                value: SortOption.biggestDiscount,
                child: Text('Biggest Discount'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsContent(AsyncValue<List<ProductModel>> productsAsync) {
    return productsAsync.when(
      loading: () => _buildShimmerGrid(),
      error: (err, _) => _buildErrorState(err.toString()),
      data: (products) {
        if (products.isEmpty) {
          return _buildEmptyState();
        }
        return GridView.builder(
          key: const Key('search_results_grid'),
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.46,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: (prod) {
                if (widget.onProductTap != null) {
                  widget.onProductTap!(prod.productId);
                } else {
                  context.push('/product/${prod.productId}');
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.46,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerProductCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.0,
              height: 80.0,
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 40.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No products found',
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'We couldn\'t find any items matching your filters.\nTry searching with different keywords or clearing filters.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyRegular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              key: const Key('empty_state_reset_btn'),
              text: 'Reset All Filters',
              variant: CustomButtonVariant.filled,
              onPressed: () {
                _searchController.clear();
                ref.read(catalogFilterProvider.notifier).resetFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48.0,
              color: AppColors.destructiveRed,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load search results',
              style: AppTypography.heading2.copyWith(
                color: AppColors.destructiveRed,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              text: 'Retry',
              variant: CustomButtonVariant.outline,
              onPressed: () {
                ref.invalidate(filteredProductsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(SortOption sort) {
    switch (sort) {
      case SortOption.relevance:
        return 'Popularity';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.ratingHighToLow:
        return 'Customer Rating';
      case SortOption.newest:
        return 'Newest Arrivals';
      case SortOption.biggestDiscount:
        return 'Biggest Discount';
    }
  }
}
