import 'package:flutter/foundation.dart';
import '../../catalog/domain/product_model.dart';

/// Represents a product saved in the user's wishlist.
/// Corresponds to Firestore document in `users/{userId}/wishlist/{productId}`.
@immutable
class WishlistItemModel {
  final String productId;
  final String productName;
  final String? schoolName;
  final String? imageUrl;
  final double price;
  final double? mrp;
  final bool inStock;
  final DateTime addedAt;

  const WishlistItemModel({
    required this.productId,
    required this.productName,
    this.schoolName,
    this.imageUrl,
    required this.price,
    this.mrp,
    this.inStock = true,
    required this.addedAt,
  });

  /// Whether a valid discount is present
  bool get hasDiscount => mrp != null && mrp! > price;

  /// Percentage discount off MRP
  int get discountPercent {
    if (!hasDiscount || mrp == null || mrp! <= 0) return 0;
    return (((mrp! - price) / mrp!) * 100).round();
  }

  /// Creates a [WishlistItemModel] from a [ProductModel].
  factory WishlistItemModel.fromProduct(
    ProductModel product, {
    DateTime? addedAt,
  }) {
    final String? img = product.images.isNotEmpty ? product.images.first : null;

    return WishlistItemModel(
      productId: product.productId,
      productName: product.name,
      schoolName: product.schoolName,
      imageUrl: img,
      price: product.effectivePrice,
      mrp: product.hasDiscount ? product.basePrice : null,
      inStock: product.inStock,
      addedAt: addedAt ?? DateTime.now(),
    );
  }

  WishlistItemModel copyWith({
    String? productId,
    String? productName,
    String? schoolName,
    String? imageUrl,
    double? price,
    double? mrp,
    bool? inStock,
    DateTime? addedAt,
  }) {
    return WishlistItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      schoolName: schoolName ?? this.schoolName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      inStock: inStock ?? this.inStock,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  factory WishlistItemModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['addedAt'] is String) {
      parsedDate = DateTime.tryParse(map['addedAt'] as String) ?? DateTime.now();
    } else if (map['addedAt'] != null && map['addedAt'].runtimeType.toString().contains('Timestamp')) {
      // Handle Firestore Timestamp if dynamic
      parsedDate = (map['addedAt'] as dynamic).toDate() as DateTime;
    } else {
      parsedDate = DateTime.now();
    }

    return WishlistItemModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      schoolName: map['schoolName'] as String?,
      imageUrl: map['imageUrl'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble(),
      inStock: map['inStock'] as bool? ?? true,
      addedAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'schoolName': schoolName,
      'imageUrl': imageUrl,
      'price': price,
      'mrp': mrp,
      'inStock': inStock,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) =>
      WishlistItemModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistItemModel &&
        other.productId == productId &&
        other.productName == productName &&
        other.schoolName == schoolName &&
        other.imageUrl == imageUrl &&
        other.price == price &&
        other.mrp == mrp &&
        other.inStock == inStock &&
        other.addedAt.millisecondsSinceEpoch ==
            addedAt.millisecondsSinceEpoch;
  }

  @override
  int get hashCode => Object.hash(
        productId,
        productName,
        schoolName,
        imageUrl,
        price,
        mrp,
        inStock,
        addedAt.millisecondsSinceEpoch,
      );

  @override
  String toString() {
    return 'WishlistItemModel(productId: $productId, productName: $productName, price: $price, inStock: $inStock)';
  }
}
