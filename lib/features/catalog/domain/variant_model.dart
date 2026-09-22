import 'package:flutter/foundation.dart';

/// Represents a specific variant of a product (e.g. Size, Grade, Color option).
@immutable
class VariantModel {
  final String variantId;
  final String sku;
  final String label;
  final double price;
  final int stock;

  const VariantModel({
    required this.variantId,
    required this.sku,
    required this.label,
    required this.price,
    this.stock = 0,
  });

  bool get inStock => stock > 0;

  VariantModel copyWith({
    String? variantId,
    String? sku,
    String? label,
    double? price,
    int? stock,
  }) {
    return VariantModel(
      variantId: variantId ?? this.variantId,
      sku: sku ?? this.sku,
      label: label ?? this.label,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      variantId: json['variantId'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      label: json['label'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'sku': sku,
      'label': label,
      'price': price,
      'stock': stock,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantModel &&
          runtimeType == other.runtimeType &&
          variantId == other.variantId &&
          sku == other.sku &&
          label == other.label &&
          price == other.price &&
          stock == other.stock;

  @override
  int get hashCode =>
      variantId.hashCode ^
      sku.hashCode ^
      label.hashCode ^
      price.hashCode ^
      stock.hashCode;

  @override
  String toString() =>
      'VariantModel(id: $variantId, sku: $sku, label: $label, price: ₹$price, stock: $stock)';
}
