import 'package:flutter/foundation.dart';
import 'variant_model.dart';

/// Represents a product in the Book Vardi catalog (Uniforms, Textbooks, Stationery, Footwear).
/// Fully compliant with PRD Section 5 Firestore Schema.
@immutable
class ProductModel {
  final String productId;
  final String name;
  final String description;
  final String categoryId;
  final String? schoolId;
  final String? schoolName;
  final String? targetGrade;
  final double basePrice;
  final double? discountPrice;
  final List<String> images;
  final List<VariantModel> variants;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final bool isActive;
  final bool isFeatured;
  final int totalStock;
  final Map<String, dynamic> specifications;

  const ProductModel({
    required this.productId,
    String? name,
    String? title,
    required this.description,
    required this.categoryId,
    this.schoolId,
    this.schoolName,
    this.targetGrade,
    required this.basePrice,
    this.discountPrice,
    this.images = const [],
    this.variants = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.inStock = true,
    this.isActive = true,
    this.isFeatured = false,
    this.totalStock = 0,
    this.specifications = const {},
  }) : name = name ?? title ?? '';

  /// Backward-compatible alias for name
  String get title => name;

  /// Whether product has selectable variant choices
  bool get hasVariants => variants.isNotEmpty;

  /// True if a valid discount is present and lower than base price
  bool get hasDiscount =>
      discountPrice != null && discountPrice! > 0 && discountPrice! < basePrice;

  /// Effective price after discount if available
  double get effectivePrice => hasDiscount ? discountPrice! : basePrice;

  /// Percentage discount computed against base price
  int get discountPercentage {
    if (!hasDiscount || basePrice <= 0) return 0;
    return (((basePrice - discountPrice!) / basePrice) * 100).round();
  }

  /// Primary display image or empty string
  String get primaryImage => images.isNotEmpty ? images.first : '';

  ProductModel copyWith({
    String? productId,
    String? name,
    String? title,
    String? description,
    String? categoryId,
    String? schoolId,
    String? schoolName,
    String? targetGrade,
    double? basePrice,
    double? discountPrice,
    List<String>? images,
    List<VariantModel>? variants,
    double? rating,
    int? reviewCount,
    bool? inStock,
    bool? isActive,
    bool? isFeatured,
    int? totalStock,
    Map<String, dynamic>? specifications,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      name: name ?? title ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      targetGrade: targetGrade ?? this.targetGrade,
      basePrice: basePrice ?? this.basePrice,
      discountPrice: discountPrice ?? this.discountPrice,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      inStock: inStock ?? this.inStock,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      totalStock: totalStock ?? this.totalStock,
      specifications: specifications ?? this.specifications,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawVariants = (json['variants'] as List<dynamic>?)
            ?.map((v) => VariantModel.fromJson(v as Map<String, dynamic>))
            .toList() ??
        const [];

    return ProductModel(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      schoolId: json['schoolId'] as String?,
      schoolName: json['schoolName'] as String?,
      targetGrade: json['targetGrade'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      variants: rawVariants,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      inStock: json['inStock'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      totalStock: (json['totalStock'] as num?)?.toInt() ??
          rawVariants.fold<int>(0, (sum, v) => sum + v.stock),
      specifications: (json['specifications'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'title': name,
      'description': description,
      'categoryId': categoryId,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'targetGrade': targetGrade,
      'basePrice': basePrice,
      'discountPrice': discountPrice,
      'images': images,
      'variants': variants.map((v) => v.toJson()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
      'inStock': inStock,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'hasVariants': hasVariants,
      'totalStock': totalStock,
      'specifications': specifications,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          name == other.name &&
          description == other.description &&
          categoryId == other.categoryId &&
          schoolId == other.schoolId &&
          schoolName == other.schoolName &&
          targetGrade == other.targetGrade &&
          basePrice == other.basePrice &&
          discountPrice == other.discountPrice &&
          rating == other.rating &&
          reviewCount == other.reviewCount &&
          inStock == other.inStock &&
          isActive == other.isActive &&
          isFeatured == other.isFeatured &&
          totalStock == other.totalStock &&
          mapEquals(specifications, other.specifications) &&
          listEquals(images, other.images) &&
          listEquals(variants, other.variants);

  @override
  int get hashCode =>
      productId.hashCode ^
      name.hashCode ^
      description.hashCode ^
      categoryId.hashCode ^
      schoolId.hashCode ^
      schoolName.hashCode ^
      targetGrade.hashCode ^
      basePrice.hashCode ^
      discountPrice.hashCode ^
      rating.hashCode ^
      reviewCount.hashCode ^
      inStock.hashCode ^
      isActive.hashCode ^
      isFeatured.hashCode ^
      totalStock.hashCode ^
      images.hashCode ^
      variants.hashCode;

  @override
  String toString() =>
      'ProductModel(id: $productId, name: $name, basePrice: ₹$basePrice, discountPrice: ₹$discountPrice, variants: ${variants.length}, stock: $totalStock)';
}
