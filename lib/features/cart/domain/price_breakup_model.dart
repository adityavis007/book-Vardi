import 'package:flutter/foundation.dart';
import 'cart_item_model.dart';

/// Financial and pricing breakdown engine for Book Vardi checkout calculations.
/// Formula: Grand Total = Subtotal + Delivery - Discounts
@immutable
class PriceBreakupModel {
  /// Free delivery order threshold (orders strictly above ₹999 get free delivery)
  static const double freeDeliveryThreshold = 999.0;

  /// Standard shipping charge for orders at or below the threshold
  static const double standardDeliveryCharge = 50.0;

  final double subtotal;
  final double schoolBulkDiscount;
  final double couponDiscount;
  final double deliveryCharge;
  final double grandTotal;

  const PriceBreakupModel({
    required this.subtotal,
    this.schoolBulkDiscount = 0.0,
    this.couponDiscount = 0.0,
    required this.deliveryCharge,
    required this.grandTotal,
  });

  /// Total discount applied across bulk and coupons
  double get totalDiscounts => schoolBulkDiscount + couponDiscount;

  /// Whether the order qualified for free shipping
  bool get isFreeDelivery => deliveryCharge == 0.0 && subtotal > 0.0;

  /// Remaining amount needed in cart subtotal to qualify for free delivery
  double get amountToFreeDelivery {
    if (subtotal >= freeDeliveryThreshold) return 0.0;
    return (freeDeliveryThreshold - subtotal).clamp(0.0, freeDeliveryThreshold);
  }

  /// Calculates the delivery fee based on order subtotal
  static double calculateDeliveryCharge(double subtotal) {
    if (subtotal <= 0.0) return 0.0;
    if (subtotal > freeDeliveryThreshold) return 0.0;
    return standardDeliveryCharge;
  }

  /// Calculates pricing breakdown from a collection of cart items
  factory PriceBreakupModel.fromItems(
    List<CartItemModel> items, {
    double schoolBulkDiscount = 0.0,
    double couponDiscount = 0.0,
  }) {
    final double subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    return PriceBreakupModel.calculate(
      subtotal: subtotal,
      schoolBulkDiscount: schoolBulkDiscount,
      couponDiscount: couponDiscount,
    );
  }

  /// Calculates pricing breakdown given raw numerical parameters
  factory PriceBreakupModel.calculate({
    required double subtotal,
    double schoolBulkDiscount = 0.0,
    double couponDiscount = 0.0,
  }) {
    final double delivery = calculateDeliveryCharge(subtotal);
    final double totalDiscount = schoolBulkDiscount + couponDiscount;
    // Grand Total = Subtotal + Delivery - Discounts (clamped to 0 minimum)
    final double rawGrandTotal = subtotal + delivery - totalDiscount;
    final double grandTotal = rawGrandTotal < 0.0 ? 0.0 : rawGrandTotal;

    return PriceBreakupModel(
      subtotal: subtotal,
      schoolBulkDiscount: schoolBulkDiscount,
      couponDiscount: couponDiscount,
      deliveryCharge: delivery,
      grandTotal: grandTotal,
    );
  }

  PriceBreakupModel copyWith({
    double? subtotal,
    double? schoolBulkDiscount,
    double? couponDiscount,
    double? deliveryCharge,
    double? grandTotal,
  }) {
    return PriceBreakupModel(
      subtotal: subtotal ?? this.subtotal,
      schoolBulkDiscount: schoolBulkDiscount ?? this.schoolBulkDiscount,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      grandTotal: grandTotal ?? this.grandTotal,
    );
  }

  factory PriceBreakupModel.fromMap(Map<String, dynamic> map) {
    return PriceBreakupModel(
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      schoolBulkDiscount: (map['schoolBulkDiscount'] as num?)?.toDouble() ?? 0.0,
      couponDiscount: (map['couponDiscount'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subtotal': subtotal,
      'schoolBulkDiscount': schoolBulkDiscount,
      'couponDiscount': couponDiscount,
      'deliveryCharge': deliveryCharge,
      'grandTotal': grandTotal,
    };
  }

  factory PriceBreakupModel.fromJson(Map<String, dynamic> json) =>
      PriceBreakupModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PriceBreakupModel &&
        other.subtotal == subtotal &&
        other.schoolBulkDiscount == schoolBulkDiscount &&
        other.couponDiscount == couponDiscount &&
        other.deliveryCharge == deliveryCharge &&
        other.grandTotal == grandTotal;
  }

  @override
  int get hashCode => Object.hash(
        subtotal,
        schoolBulkDiscount,
        couponDiscount,
        deliveryCharge,
        grandTotal,
      );

  @override
  String toString() {
    return 'PriceBreakupModel(subtotal: $subtotal, deliveryCharge: $deliveryCharge, totalDiscounts: $totalDiscounts, grandTotal: $grandTotal)';
  }
}
