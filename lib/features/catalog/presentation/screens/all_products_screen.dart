import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/guards/guest_guard.dart';
import '../../../../core/guards/pending_action.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../cart/domain/wishlist_item_model.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../cart/presentation/controllers/wishlist_controller.dart';
import '../../domain/product_model.dart';
import '../../domain/variant_model.dart';
import '../controllers/catalog_controller.dart';
import '../widgets/filter_modal.dart';

/// Model representing a quick circular filter chip.
class CatalogQuickCategory {
  final String id;
  final String label;
  final String? imageUrl;
  final IconData? icon;
  final bool isSpecialAll;
  final bool isSpecialLiked;

  const CatalogQuickCategory({
    required this.id,
    required this.label,
    this.imageUrl,
    this.icon,
    this.isSpecialAll = false,
    this.isSpecialLiked = false,
  });
}

/// 1:1 "All Products Screen" matching the Book Vardi web catalog showcase.
class AllProductsScreen extends ConsumerStatefulWidget {
  const AllProductsScreen({super.key});

  static bool get isTestEnv {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  @override
  ConsumerState<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends ConsumerState<AllProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  String _selectedQuickCategory = 'all';
  bool _filterLikedOnly = false;

  static const List<CatalogQuickCategory> _quickCategories = [
    CatalogQuickCategory(
      id: 'all',
      label: 'All Items',
      icon: Icons.search_rounded,
      isSpecialAll: true,
    ),
    CatalogQuickCategory(
      id: 'liked',
      label: 'Liked',
      icon: Icons.favorite_rounded,
      isSpecialLiked: true,
    ),
    CatalogQuickCategory(
      id: 'uniforms',
      label: 'SCHOOL UNIFORMS',
      imageUrl:
          'https://images.unsplash.com/photo-1577896851231-70ef18881754?w=400&auto=format&fit=crop&q=80',
      icon: Icons.checkroom_rounded,
    ),
    CatalogQuickCategory(
      id: 'ncert_books',
      label: 'NCERT BOOKS',
      imageUrl:
          'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=400&auto=format&fit=crop&q=80',
      icon: Icons.menu_book_rounded,
    ),
    CatalogQuickCategory(
      id: 'practice_books',
      label: 'PRACTICE BOOKS',
      imageUrl:
          'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&auto=format&fit=crop&q=80',
      icon: Icons.edit_note_rounded,
    ),
    CatalogQuickCategory(
      id: 'drawing',
      label: 'DRAWING FOR KIDS',
      imageUrl:
          'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=400&auto=format&fit=crop&q=80',
      icon: Icons.palette_outlined,
    ),
    CatalogQuickCategory(
      id: 'stationery',
      label: 'STATIONERY',
      imageUrl:
          'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=400&auto=format&fit=crop&q=80',
      icon: Icons.border_color_rounded,
    ),
    CatalogQuickCategory(
      id: 'kits_bundles',
      label: 'KITS & BUNDLES',
      imageUrl:
          'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=400&auto=format&fit=crop&q=80',
      icon: Icons.inventory_2_outlined,
    ),
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(catalogFilterProvider.notifier)
          .setSearchQuery(query, debounceDuration: Duration.zero);
    });
    setState(() {});
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleQuickCategoryTap(CatalogQuickCategory item) {
    setState(() {
      _selectedQuickCategory = item.id;
    });

    if (item.isSpecialAll) {
      setState(() {
        _filterLikedOnly = false;
      });
      _searchController.clear();
      _debounceTimer?.cancel();
      ref.read(catalogFilterProvider.notifier).resetFilters();
      return;
    }

    if (item.isSpecialLiked) {
      setState(() {
        _filterLikedOnly = true;
      });
      return;
    }

    setState(() {
      _filterLikedOnly = false;
    });

    // Map quick chip to catalog filter
    final filterNotifier = ref.read(catalogFilterProvider.notifier);
    switch (item.id) {
      case 'uniforms':
        filterNotifier.setCategory('cat_uniforms');
        break;
      case 'ncert_books':
      case 'practice_books':
        filterNotifier.setCategory('cat_books');
        break;
      case 'drawing':
      case 'stationery':
        filterNotifier.setCategory('cat_stationery');
        break;
      case 'kits_bundles':
        filterNotifier.setSearchQuery('bundle', debounceDuration: Duration.zero);
        break;
      default:
        filterNotifier.setCategory(item.id);
    }
  }

  void _openFilterModal() {
    FilterModal.show(
      context,
      initialState: ref.read(catalogFilterProvider),
      onApply: (updatedState) {
        ref.read(catalogFilterProvider.notifier).applyState(updatedState);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final wishlistItems = ref.watch(wishlistItemsListProvider);
    final wishlistCount = ref.watch(wishlistCountProvider);
    final wishlistIdSet = wishlistItems.map((item) => item.productId).toSet();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.primaryNavy,
        onRefresh: () async {
          ref.invalidate(filteredProductsProvider);
          await ref.read(filteredProductsProvider.future);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // 1. Dark Green Pine Header Banner
            SliverToBoxAdapter(
              child: _buildDarkGreenHeader(
                totalCount: productsAsync.valueOrNull?.length ?? 0,
              ),
            ),

            // 2. Search & Filter Bar
            SliverToBoxAdapter(
              child: _buildSearchAndFilterRow(),
            ),

            // 3. Circular Quick Category Rail
            SliverToBoxAdapter(
              child: _buildCategoryRail(wishlistCount),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 16.0),
            ),

            // 4. Products Grid Section
            _buildProductsGrid(productsAsync, wishlistIdSet),

            // 5. End of Catalog Footer Card
            SliverToBoxAdapter(
              child: _buildEndOfCatalogFooter(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24.0),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Dark Green Header Banner (Clean, compact mobile header without web breadcrumb)
  Widget _buildDarkGreenHeader({required int totalCount}) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F291E), // Dark Pine Green
      padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warm Amber Pill Badge: "⚡ FULL STATIONERY CATALOG"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF08A).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color(0xFFFDE047).withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFFDE047),
                  size: 13.0,
                ),
                SizedBox(width: 4.0),
                Text(
                  'FULL STATIONERY CATALOG',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFDE047),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Title & Counter Pill Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'All Products',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: Colors.white,
                    fontSize: 22.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),

              // Translucent Counter Pill: "Showing X of Y items"
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.0,
                          color: Colors.white,
                        ),
                        children: [
                          const TextSpan(text: 'Showing '),
                          TextSpan(
                            text: '$totalCount',
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' of '),
                          TextSpan(
                            text: '$totalCount',
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' items'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Subtitle
          Text(
            'Browse our complete collection of premium uniforms, books & stationery.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12.0,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 2. Search & Filters Row with 300ms debounce, 12px corners and active filter badge
  Widget _buildSearchAndFilterRow() {
    final filter = ref.watch(catalogFilterProvider);
    final int activeFilterCount = (filter.categoryId != null ? 1 : 0) +
        (filter.schoolName != null ? 1 : 0) +
        (filter.grade != null ? 1 : 0) +
        (filter.inStockOnly ? 1 : 0) +
        (filter.minPrice != null || filter.maxPrice != null ? 1 : 0);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          // Search Input Box (44px height, rounded, slate background)
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
                          onPressed: () {
                            _searchController.clear();
                            _debounceTimer?.cancel();
                            ref
                                .read(catalogFilterProvider.notifier)
                                .setSearchQuery('', debounceDuration: Duration.zero);
                            setState(() {});
                          },
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

          const SizedBox(width: 10.0),

          // Outlined "Filters" Button with Active Filter Dot/Badge
          InkWell(
            onTap: _openFilterModal,
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              height: 44.0,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: activeFilterCount > 0
                    ? const Color(0xFF0F291E).withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: activeFilterCount > 0
                      ? const Color(0xFF0F291E)
                      : const Color(0xFFCBD5E1),
                  width: activeFilterCount > 0 ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18.0,
                    color: activeFilterCount > 0
                        ? const Color(0xFF0F291E)
                        : const Color(0xFF334155),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: activeFilterCount > 0
                          ? const Color(0xFF0F291E)
                          : const Color(0xFF334155),
                    ),
                  ),
                  if (activeFilterCount > 0) ...[
                    const SizedBox(width: 5.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.0,
                        vertical: 1.5,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F291E),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$activeFilterCount',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: Colors.white,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Horizontal Quick Category / Filter Rail (50px Circular Chips with 1-line label)
  Widget _buildCategoryRail(int wishlistCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _quickCategories.map((item) {
            final isSelected = _selectedQuickCategory == item.id;
            final labelText = item.isSpecialLiked
                ? 'Liked ($wishlistCount)'
                : item.label;

            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: InkWell(
                onTap: () => _handleQuickCategoryTap(item),
                borderRadius: BorderRadius.circular(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular Avatar Container (50px x 50px)
                    Container(
                      width: 50.0,
                      height: 50.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getCircleBg(item, isSelected),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F291E)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.2 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F291E)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 6.0,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: _buildCircleContent(item, isSelected),
                      ),
                    ),
                    const SizedBox(height: 5.0),

                    // Label Underneath (1 line, 10.5px)
                    SizedBox(
                      width: 62.0,
                      child: Text(
                        labelText,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF0F291E)
                              : const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getCircleBg(CatalogQuickCategory item, bool isSelected) {
    if (item.isSpecialAll) {
      return const Color(0xFF1E293B);
    }
    if (item.isSpecialLiked) {
      return const Color(0xFFFEE2E2);
    }
    return const Color(0xFFF1F5F9);
  }

  Widget _buildCircleContent(CatalogQuickCategory item, bool isSelected) {
    if (item.isSpecialAll) {
      return const Center(
        child: Icon(
          Icons.search_rounded,
          color: Colors.white,
          size: 26.0,
        ),
      );
    }

    if (item.isSpecialLiked) {
      return const Center(
        child: Icon(
          Icons.favorite_rounded,
          color: Color(0xFFEF4444),
          size: 24.0,
        ),
      );
    }

    if (!AllProductsScreen.isTestEnv &&
        item.imageUrl != null &&
        item.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Center(
          child: Icon(item.icon ?? Icons.category_outlined,
              size: 24.0, color: const Color(0xFF64748B)),
        ),
        errorWidget: (_, __, ___) => Center(
          child: Icon(item.icon ?? Icons.category_outlined,
              size: 24.0, color: const Color(0xFF64748B)),
        ),
      );
    }

    return Center(
      child: Icon(
        item.icon ?? Icons.category_outlined,
        size: 24.0,
        color: const Color(0xFF475569),
      ),
    );
  }

  /// 4. Products Grid Section
  Widget _buildProductsGrid(
    AsyncValue<List<ProductModel>> productsAsync,
    Set<String> wishlistIdSet,
  ) {
    if (productsAsync.isLoading && !productsAsync.hasValue) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 14.0,
            childAspectRatio: 0.54,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildShimmerProductCard(),
            childCount: 4,
          ),
        ),
      );
    }

    return productsAsync.when(
      skipLoadingOnReload: true,
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 14.0,
            childAspectRatio: 0.54,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildShimmerProductCard(),
            childCount: 4,
          ),
        ),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.destructiveRed),
                const SizedBox(height: 12),
                Text(
                  'Failed to load products: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(filteredProductsProvider),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (allProducts) {
        // Filter by Liked if Liked chip active
        final products = _filterLikedOnly
            ? allProducts
                .where((p) => wishlistIdSet.contains(p.productId))
                .toList()
            : allProducts;

        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 72.0,
                      height: 72.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 36.0,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      _filterLikedOnly
                          ? 'No Liked Products Yet'
                          : 'No Products Match Your Criteria',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _filterLikedOnly
                          ? 'Tap the heart icon on any product to save it to your wishlist.'
                          : 'Try changing your search terms or resetting filters.',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13.0,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedQuickCategory = 'all';
                          _filterLikedOnly = false;
                        });
                        _searchController.clear();
                        ref.read(catalogFilterProvider.notifier).resetFilters();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F291E),
                        side: const BorderSide(color: Color(0xFF0F291E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text('Clear All Filters'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.58,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                final isWishlisted = wishlistIdSet.contains(product.productId);
                return _Catalog1To1ProductCard(
                  key: ValueKey('catalog_card_${product.productId}'),
                  product: product,
                  isWishlisted: isWishlisted,
                );
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }

  /// 5. End of Catalog Footer Card
  Widget _buildEndOfCatalogFooter() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Party Popper Icon
            const Text(
              '🎉',
              style: TextStyle(fontSize: 32.0),
            ),
            const SizedBox(height: 8.0),

            // Text
            const Text(
              "You've Reached The End of the Catalog!",
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10.0),

            // Back to Top Action
            InkWell(
              onTap: _scrollToTop,
              borderRadius: BorderRadius.circular(8.0),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 16.0,
                      color: Color(0xFF0F291E),
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      'Back to Top',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F291E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerProductCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.18,
            child: ShimmerLoading(
              child: ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  child: ShimmerBox(width: 100, height: 13),
                ),
                SizedBox(height: 4),
                ShimmerLoading(
                  child: ShimmerBox(width: 70, height: 11),
                ),
                SizedBox(height: 6),
                ShimmerLoading(
                  child: ShimmerBox(width: double.infinity, height: 18),
                ),
                SizedBox(height: 8),
                ShimmerLoading(
                  child: ShimmerBox(width: double.infinity, height: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 1:1 Product Card matching the website layout with variant chips, 5-star rating,
/// and soft yellow Add-to-Cart button with auth guard.
class _Catalog1To1ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final bool isWishlisted;

  const _Catalog1To1ProductCard({
    super.key,
    required this.product,
    required this.isWishlisted,
  });

  @override
  ConsumerState<_Catalog1To1ProductCard> createState() =>
      _Catalog1To1ProductCardState();
}

class _Catalog1To1ProductCardState extends ConsumerState<_Catalog1To1ProductCard> {
  int _selectedVariantIndex = 0;

  static const List<String> _fallbackSizes = ['S', 'M', 'L', 'XL'];

  VariantModel? get _currentVariant {
    if (widget.product.variants.isEmpty) return null;
    if (_selectedVariantIndex >= 0 &&
        _selectedVariantIndex < widget.product.variants.length) {
      return widget.product.variants[_selectedVariantIndex];
    }
    return widget.product.variants.first;
  }

  void _handleToggleWishlist() {
    executeWithAuthGuard(
      context,
      ref,
      action: PendingAction(
        type: PendingActionType.toggleWishlist,
        productId: widget.product.productId,
      ),
      onAuthenticated: () {
        ref.read(wishlistControllerProvider).toggleWishlist(
              WishlistItemModel.fromProduct(widget.product),
            );
      },
    );
  }

  void _handleAddToCart() {
    if (!widget.product.inStock) return;

    executeWithAuthGuard(
      context,
      ref,
      action: PendingAction(
        type: PendingActionType.addToCart,
        productId: widget.product.productId,
        quantity: 1,
      ),
      onAuthenticated: () async {
        final success = await ref.read(cartControllerProvider).addToCart(
              widget.product,
              variant: _currentVariant,
              quantity: 1,
            );
        if (success && mounted) {
          AppSnackBar.showCartSnackBar(
            context,
            productTitle: widget.product.title,
          );
        }
      },
    );
  }

  String _formatPrice(double amount) {
    try {
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
      ).format(amount);
    } catch (_) {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool canAddToCart = product.inStock;

    // Available size options (variants labels or fallback S, M, L, XL)
    final List<String> sizeOptions = product.hasVariants
        ? product.variants.map((v) => v.label).toList()
        : _fallbackSizes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/product/${product.productId}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1:1.14 Image Container with Discount Tag & Wishlist Button
              AspectRatio(
                aspectRatio: 1.14,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFFF8FAFC),
                      child: _buildProductImage(product),
                    ),

                    // Burgundy / Amber Discount Tag (Top Left)
                    if (product.hasDiscount)
                      Positioned(
                        top: 6.0,
                        left: 6.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9F1239),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '${product.discountPercentage}% OFF',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                    // Circular White Wishlist Heart Button
                    Positioned(
                      top: 6.0,
                      right: 6.0,
                      child: InkWell(
                        onTap: _handleToggleWishlist,
                        borderRadius: BorderRadius.circular(14.0),
                        child: Container(
                          width: 28.0,
                          height: 28.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.95),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4.0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              widget.isWishlisted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 15.0,
                              color: widget.isWishlisted
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Details & Action Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Title (Bold, 0F172A, max 1 line ellipsis)
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),

                          // Description Subtitle clamped to 1 line
                          Text(
                            product.description.isNotEmpty
                                ? product.description
                                : 'Premium quality school uniform & supplies.',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),

                          // Variant Size Chips Row (Tight padding)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: List.generate(sizeOptions.length, (idx) {
                                final isChipSelected = _selectedVariantIndex == idx;
                                final label = sizeOptions[idx];

                                return Padding(
                                  padding: const EdgeInsets.only(right: 3.5),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedVariantIndex = idx;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(4.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isChipSelected
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4.0),
                                        border: Border.all(
                                          color: isChipSelected
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFCBD5E1),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 9.5,
                                          fontWeight: isChipSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isChipSelected
                                              ? Colors.white
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 4.0),

                          // Price & Star Rating Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Price (Bold ₹199)
                              Text(
                                _formatPrice(product.effectivePrice),
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),

                              // Star Rating Indicator (5 stars + 0.0)
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ...List.generate(5, (starIdx) {
                                        final bool isFilled =
                                            starIdx < product.rating.floor();
                                        return Icon(
                                          isFilled
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 10.5,
                                          color: isFilled
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFFCBD5E1),
                                        );
                                      }),
                                      const SizedBox(width: 2.0),
                                      Text(
                                        product.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Add to Cart Button (H: 30px, Soft Vibrant Amber)
                      SizedBox(
                        width: double.infinity,
                        height: 30.0,
                        child: ElevatedButton(
                          onPressed: canAddToCart ? _handleAddToCart : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAddToCart
                                ? const Color(0xFFFDE047) // Soft Vibrant Amber #FDE047
                                : const Color(0xFFE2E8F0),
                            foregroundColor: const Color(0xFF0F172A),
                            disabledBackgroundColor: const Color(0xFFE2E8F0),
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              side: BorderSide(
                                color: canAddToCart
                                    ? const Color(0xFFEAB308)
                                    : const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 13.0,
                                  color: canAddToCart
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  canAddToCart ? 'Add to Cart' : 'Out of Stock',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: canAddToCart
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(ProductModel product) {
    final imageUrl = product.primaryImage.trim();

    if (AllProductsScreen.isTestEnv || imageUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.school_outlined,
          size: 44.0,
          color: Color(0xFFCBD5E1),
        ),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.menu_book_rounded,
            size: 40.0,
            color: Color(0xFFCBD5E1),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F291E)),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 40.0,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
