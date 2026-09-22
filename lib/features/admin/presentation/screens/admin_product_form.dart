import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/domain/product_model.dart';
import '../../../catalog/domain/variant_model.dart';
import '../controllers/admin_controller.dart';

/// Helper model representing an editable row in the dynamic variant matrix builder.
class VariantRowItem {
  String variantId;
  TextEditingController labelController;
  TextEditingController skuController;
  TextEditingController priceController;
  TextEditingController stockController;

  VariantRowItem({
    required this.variantId,
    required String label,
    required String sku,
    required double price,
    required int stock,
  })  : labelController = TextEditingController(text: label),
        skuController = TextEditingController(text: sku),
        priceController = TextEditingController(text: price > 0 ? price.toStringAsFixed(0) : ''),
        stockController = TextEditingController(text: stock.toString());

  void dispose() {
    labelController.dispose();
    skuController.dispose();
    priceController.dispose();
    stockController.dispose();
  }
}

/// Dynamic Product Studio Form supporting multi-variant matrices, pricing, and catalog sync.
class AdminProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AdminProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _gradeController = TextEditingController();

  String _selectedCategory = 'uniforms';
  bool _inStock = true;
  bool _isSaving = false;
  bool _isInitialized = false;

  final List<VariantRowItem> _variantRows = [];

  final List<String> _categoryOptions = [
    'uniforms',
    'books',
    'stationery',
    'shoes',
    'bags',
  ];

  @override
  void initState() {
    super.initState();
    _imageUrlController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductIfEditing();
    });
  }

  Future<void> _loadProductIfEditing() async {
    if (widget.productId == null || widget.productId!.isEmpty) {
      // Create mode: add one default variant row
      _addVariantRow(label: 'Standard', sku: 'SKU-${DateTime.now().millisecondsSinceEpoch % 10000}');
      setState(() => _isInitialized = true);
      return;
    }

    try {
      final product = await ref.read(catalogRepositoryProvider).fetchProductById(widget.productId!);
      if (product != null && mounted) {
        _nameController.text = product.name;
        _descController.text = product.description;
        _basePriceController.text = product.basePrice.toStringAsFixed(0);
        if (product.discountPrice != null) {
          _discountPriceController.text = product.discountPrice!.toStringAsFixed(0);
        }
        if (product.images.isNotEmpty) {
          _imageUrlController.text = product.primaryImage;
        }
        _schoolNameController.text = product.schoolName ?? '';
        _gradeController.text = product.targetGrade ?? '';
        _selectedCategory = _categoryOptions.contains(product.categoryId)
            ? product.categoryId
            : _categoryOptions.first;
        _inStock = product.inStock;

        // Populate variants
        for (final v in product.variants) {
          _addVariantRow(
            variantId: v.variantId,
            label: v.label,
            sku: v.sku,
            price: v.price,
            stock: v.stock,
          );
        }

        if (_variantRows.isEmpty) {
          _addVariantRow(label: 'Standard', sku: 'SKU-001', price: product.basePrice, stock: product.totalStock);
        }
      }
    } catch (e) {
      debugPrint('[AdminProductForm] Error loading product: $e');
    } finally {
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  void _addVariantRow({
    String? variantId,
    String label = '',
    String sku = '',
    double price = 0.0,
    int stock = 10,
  }) {
    final item = VariantRowItem(
      variantId: variantId ?? const Uuid().v4().substring(0, 8),
      label: label,
      sku: sku,
      price: price > 0 ? price : (double.tryParse(_basePriceController.text) ?? 0.0),
      stock: stock,
    );

    item.stockController.addListener(() => setState(() {}));
    setState(() {
      _variantRows.add(item);
    });
  }

  void _removeVariantRow(int index) {
    if (_variantRows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one variant row is required.')),
      );
      return;
    }
    setState(() {
      _variantRows[index].dispose();
      _variantRows.removeAt(index);
    });
  }

  int get _computedTotalStock {
    int total = 0;
    for (final row in _variantRows) {
      total += int.tryParse(row.stockController.text.trim()) ?? 0;
    }
    return total;
  }

  Future<void> _handleSaveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_variantRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one variant.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final basePrice = double.tryParse(_basePriceController.text.trim()) ?? 0.0;
      final discountPrice = double.tryParse(_discountPriceController.text.trim());

      final variants = _variantRows.map((row) {
        final vPrice = double.tryParse(row.priceController.text.trim()) ?? basePrice;
        final vStock = int.tryParse(row.stockController.text.trim()) ?? 0;
        final vLabel = row.labelController.text.trim().isEmpty ? 'Standard' : row.labelController.text.trim();
        final vSku = row.skuController.text.trim().isEmpty
            ? 'SKU-${row.variantId.toUpperCase()}'
            : row.skuController.text.trim();

        return VariantModel(
          variantId: row.variantId,
          label: vLabel,
          sku: vSku,
          price: vPrice,
          stock: vStock,
        );
      }).toList();

      final totalStock = _computedTotalStock;
      final images = _imageUrlController.text.trim().isNotEmpty
          ? [_imageUrlController.text.trim()]
          : <String>[];

      final product = ProductModel(
        productId: widget.productId ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategory,
        schoolName: _schoolNameController.text.trim().isEmpty ? 'All Schools' : _schoolNameController.text.trim(),
        targetGrade: _gradeController.text.trim().isEmpty ? null : _gradeController.text.trim(),
        basePrice: basePrice,
        discountPrice: discountPrice,
        images: images,
        variants: variants,
        totalStock: totalStock,
        inStock: _inStock && totalStock > 0,
      );

      final savedId = await ref.read(adminRepositoryProvider).saveProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$savedId" successfully saved to catalog!'),
            backgroundColor: AppColors.primaryNavy,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: $e'),
            backgroundColor: AppColors.destructiveRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _basePriceController.dispose();
    _discountPriceController.dispose();
    _imageUrlController.dispose();
    _schoolNameController.dispose();
    _gradeController.dispose();
    for (final row in _variantRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null && widget.productId!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product' : 'Add New Product',
          style: AppTypography.heading2.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.primaryNavy),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ElevatedButton.icon(
              key: const Key('admin_save_product_btn'),
              onPressed: _isSaving ? null : _handleSaveProduct,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(_isSaving ? 'Saving...' : 'Save Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedSmall),
              ),
            ),
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Basic Product Info Card
                    _buildBasicInfoCard(),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Pricing & Category Card
                    _buildPricingAndCategoryCard(),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Media & Image Preview Card
                    _buildMediaCard(),
                    const SizedBox(height: AppSpacing.md),

                    // 4. Dynamic Variant Matrix Builder
                    _buildVariantMatrixCard(),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedSmall,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Information', style: AppTypography.heading2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('product_name_input'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Product Name *',
              hintText: 'e.g. Boys Summer Uniform Shirt (Navy/White)',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('product_desc_input'),
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Enter material specifications, grade details, and sizing notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _schoolNameController,
                  decoration: const InputDecoration(
                    labelText: 'School Name',
                    hintText: 'e.g. Delhi Public School',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _gradeController,
                  decoration: const InputDecoration(
                    labelText: 'Target Grade / Class',
                    hintText: 'e.g. Class 4, All Classes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingAndCategoryCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedSmall,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category & Pricing', style: AppTypography.heading2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: _categoryOptions.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat[0].toUpperCase() + cat.substring(1)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: const Text('In Stock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    value: _inStock,
                    activeThumbColor: AppColors.primaryNavy,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _inStock = val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('product_base_price_input'),
                  controller: _basePriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Base Price (₹) *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  key: const Key('product_discount_price_input'),
                  controller: _discountPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Discount Price (₹)',
                    hintText: 'Optional sale price',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard() {
    final hasImage = _imageUrlController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedSmall,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Image URL', style: AppTypography.heading2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppSpacing.roundedSmall,
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.backgroundSlate,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: _imageUrlController.text.trim(),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 32),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  key: const Key('product_image_url_input'),
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image Web URL',
                    hintText: 'https://example.com/item.png',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantMatrixCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedSmall,
        border: Border.all(color: AppColors.borderGray),
        boxShadow: AppSpacing.elevationSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Variant Matrix Builder', style: AppTypography.heading2.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    'Total Stock: $_computedTotalStock units across ${_variantRows.length} variant(s)',
                    style: AppTypography.caption.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              TextButton.icon(
                key: const Key('admin_add_variant_row_btn'),
                onPressed: () => _addVariantRow(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Variant'),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderGray),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variantRows.length,
            separatorBuilder: (_, __) => const Divider(height: 16, color: AppColors.borderGray),
            itemBuilder: (context, index) {
              final row = _variantRows[index];
              return Row(
                children: [
                  // Label / Size
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: row.labelController,
                      decoration: const InputDecoration(
                        labelText: 'Size / Option',
                        hintText: 'Size 28',
                        isDense: true,
                        contentPadding: EdgeInsets.all(10),
                        border: OutlineInputBorder(borderRadius: AppSpacing.roundedSmall),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // SKU
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: row.skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        hintText: 'SKU-28',
                        isDense: true,
                        contentPadding: EdgeInsets.all(10),
                        border: OutlineInputBorder(borderRadius: AppSpacing.roundedSmall),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Price
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: row.priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '₹',
                        isDense: true,
                        contentPadding: EdgeInsets.all(10),
                        border: OutlineInputBorder(borderRadius: AppSpacing.roundedSmall),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Stock
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: row.stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        isDense: true,
                        contentPadding: EdgeInsets.all(10),
                        border: OutlineInputBorder(borderRadius: AppSpacing.roundedSmall),
                      ),
                    ),
                  ),

                  // Remove row
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.destructiveRed, size: 20),
                    onPressed: () => _removeVariantRow(index),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
