import 'package:flutter/foundation.dart';
import '../../catalog/domain/product_model.dart';
import '../../catalog/domain/variant_model.dart';

/// Represents an item in the user's shopping cart.
/// Corresponds to Firestore document in `users/{userId}/cart/{productId_variantId}`.
@immutable
class CartItemModel {
  final String productId;
  final String? variantId;
  final String productName;
  final String? schoolName;
  final String? variantLabel;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final int maxStock;

  const CartItemModel({
    required this.productId,
    this.variantId,
    required this.productName,
    this.schoolName,
    this.variantLabel,
    this.imageUrl,
    required this.unitPrice,
    this.quantity = 1,
    this.maxStock = 99,
  });

  /// Composite document ID used in Firestore: `${productId}_${variantId ?? 'default'}`
  String get id => '${productId}_${variantId ?? 'default'}';

  /// Total price for this cart line item
  double get totalPrice => unitPrice * quantity;

  /// Whether current quantity has reached maximum available stock
  bool get isAtMaxStock => quantity >= maxStock;

  /// Creates a [CartItemModel] from a [ProductModel] and optional [VariantModel].
  factory CartItemModel.fromProduct(
    ProductModel product, {
    VariantModel? variant,
    int quantity = 1,
  }) {
    final double price = variant != null
        ? variant.price
        : product.effectivePrice;

    final String? label = variant?.label;
    final int stock = variant != null
        ? variant.stock
        : (product.totalStock > 0 ? product.totalStock : 99);

    final String? img = product.images.isNotEmpty ? product.images.first : null;

    return CartItemModel(
      productId: product.productId,
      variantId: variant?.variantId,
      productName: product.name,
      schoolName: product.schoolName,
      variantLabel: label,
      imageUrl: img,
      unitPrice: price,
      quantity: quantity,
      maxStock: stock,
    );
  }

  CartItemModel copyWith({
    String? productId,
    String? variantId,
    String? productName,
    String? schoolName,
    String? variantLabel,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
    int? maxStock,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productName: productName ?? this.productName,
      schoolName: schoolName ?? this.schoolName,
      variantLabel: variantLabel ?? this.variantLabel,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock ?? this.maxStock,
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] as String? ?? '',
      variantId: map['variantId'] as String?,
      productName: map['productName'] as String? ?? '',
      schoolName: map['schoolName'] as String?,
      variantLabel: map['variantLabel'] as String?,
      imageUrl: map['imageUrl'] as String?,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      maxStock: (map['maxStock'] as num?)?.toInt() ?? 99,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'schoolName': schoolName,
      'variantLabel': variantLabel,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'maxStock': maxStock,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      CartItemModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemModel &&
        other.productId == productId &&
        other.variantId == variantId &&
        other.productName == productName &&
        other.schoolName == schoolName &&
        other.variantLabel == variantLabel &&
        other.imageUrl == imageUrl &&
        other.unitPrice == unitPrice &&
        other.quantity == quantity &&
        other.maxStock == maxStock;
  }

  @override
  int get hashCode => Object.hash(
        productId,
        variantId,
        productName,
        schoolName,
        variantLabel,
        imageUrl,
        unitPrice,
        quantity,
        maxStock,
      );

  @override
  String toString() {
    return 'CartItemModel(id: $id, productName: $productName, unitPrice: $unitPrice, quantity: $quantity, totalPrice: $totalPrice)';
  }
}
