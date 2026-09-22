import 'package:flutter/foundation.dart';

/// Represents a product category (e.g. Uniforms, Textbooks, Stationery, Footwear).
@immutable
class CategoryModel {
  final String categoryId;
  final String name;
  final String iconUrl;
  final int displayOrder;

  const CategoryModel({
    required this.categoryId,
    required this.name,
    required this.iconUrl,
    this.displayOrder = 0,
  });

  CategoryModel copyWith({
    String? categoryId,
    String? name,
    String? iconUrl,
    int? displayOrder,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'iconUrl': iconUrl,
      'displayOrder': displayOrder,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          name == other.name &&
          iconUrl == other.iconUrl &&
          displayOrder == other.displayOrder;

  @override
  int get hashCode =>
      categoryId.hashCode ^
      name.hashCode ^
      iconUrl.hashCode ^
      displayOrder.hashCode;

  @override
  String toString() =>
      'CategoryModel(id: $categoryId, name: $name, order: $displayOrder)';
}
