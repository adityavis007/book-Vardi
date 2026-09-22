import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../catalog/domain/product_model.dart';
import '../controllers/admin_controller.dart';

/// Product Catalog Studio listing all products with search, stock toggling, and CRUD access.
class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructiveRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(adminRepositoryProvider).deleteProduct(product.productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${product.name}" was deleted.'),
              backgroundColor: AppColors.primaryNavy,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppColors.destructiveRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        title: Text(
          'Catalog Studio',
          style: AppTypography.heading2.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('admin_add_product_fab'),
        onPressed: () => context.push('/admin/products/new'),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Container(
            color: AppColors.surfaceWhite,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              key: const Key('admin_product_search_field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name, school, category...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(adminProductSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: AppColors.backgroundSlate,
                border: const OutlineInputBorder(
                  borderRadius: AppSpacing.roundedSmall,
                  borderSide: BorderSide(color: AppColors.borderGray),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppSpacing.roundedSmall,
                  borderSide: BorderSide(color: AppColors.borderGray),
                ),
              ),
              onChanged: (val) {
                ref.read(adminProductSearchQueryProvider.notifier).state = val;
                setState(() {});
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGray),

          // Products List
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: AppSpacing.md),
                          Text('No Products Found', style: AppTypography.heading2),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No products match your search query.'
                                : 'Your catalog is empty. Tap "+ Add Product" to get started.',
                            style: AppTypography.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return _buildProductRowCard(context, p);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryNavy),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text('Error loading products: $err', style: AppTypography.caption),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRowCard(BuildContext context, ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedSmall,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Thumbnail
          ClipRRect(
            borderRadius: AppSpacing.roundedSmall,
            child: Container(
              width: 64,
              height: 64,
              color: AppColors.backgroundSlate,
              child: product.primaryImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.primaryImage,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primaryNavy,
                      ),
                    )
                  : const Icon(Icons.menu_book_rounded, color: AppColors.primaryNavy),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title & Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.inStock ? AppColors.mintPillBg : const Color(0xFFF8D7DA),
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Text(
                        product.inStock ? 'IN STOCK (${product.totalStock})' : 'OUT OF STOCK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: product.inStock ? const Color(0xFF0F5132) : AppColors.destructiveRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.categoryId.toUpperCase()} • ${product.schoolName ?? 'All Schools'}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${product.basePrice.toStringAsFixed(0)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${product.discountPrice!.toStringAsFixed(0)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    if (product.variants.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${product.variants.length} variants',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            onSelected: (action) {
              if (action == 'edit') {
                context.push('/admin/products/edit/${product.productId}');
              } else if (action == 'delete') {
                _handleDeleteProduct(product);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Product & Variants'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.destructiveRed),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.destructiveRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
