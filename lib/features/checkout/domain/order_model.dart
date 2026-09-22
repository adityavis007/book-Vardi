import 'package:flutter/foundation.dart';
import '../../cart/domain/cart_item_model.dart';
import '../../cart/domain/price_breakup_model.dart';
import 'address_model.dart';
import 'order_intent_model.dart';

/// Domain entity representing a customer order persisted in the Firestore `orders` collection.
@immutable
class OrderModel {
  /// Unique business order identifier (e.g. `#BV-2026-9812`).
  final String orderId;

  /// User ID of the customer who placed the order.
  final String userId;

  /// Ordered line items.
  final List<CartItemModel> items;

  /// Delivery destination address.
  final AddressModel shippingAddress;

  /// Financial pricing breakdown of the order.
  final PriceBreakupModel pricing;

  /// Selected fulfillment mode ('standard', 'schoolDelivery', 'express').
  final String deliveryMode;

  /// Payment mode selected ('COD', 'UPI', 'CARD', 'NET_BANKING').
  final String paymentMethod;

  /// Gateway payment ID (e.g. `pay_29QQoUBi66xm2f` for Razorpay or 'COD').
  final String? paymentId;

  /// Razorpay server-side order ID if applicable.
  final String? razorpayOrderId;

  /// Razorpay payment signature for verification.
  final String? signature;

  /// Payment resolution status ('PENDING', 'PAID', 'CONFIRMED').
  final String paymentStatus;

  /// Fulfillment lifecycle status ('CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED').
  final String orderStatus;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Estimated arrival delivery date.
  final DateTime estimatedDeliveryDate;

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.pricing,
    required this.deliveryMode,
    required this.paymentMethod,
    this.paymentId,
    this.razorpayOrderId,
    this.signature,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    required this.estimatedDeliveryDate,
  });

  /// Factory constructor to build an [OrderModel] from an active [OrderIntentModel].
  factory OrderModel.fromIntent({
    required String orderId,
    required String userId,
    required OrderIntentModel intent,
    required String deliveryMode,
    required String orderStatus,
    String? paymentId,
    String? razorpayOrderId,
    String? signature,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? estimatedDeliveryDate,
  }) {
    if (intent.shippingAddress == null) {
      throw ArgumentError('Cannot create OrderModel with null shippingAddress.');
    }

    final now = createdAt ?? DateTime.now();
    final estimatedDate = estimatedDeliveryDate ??
        now.add(deliveryMode == 'express'
            ? const Duration(days: 2)
            : const Duration(days: 4));

    return OrderModel(
      orderId: orderId,
      userId: userId,
      items: List.unmodifiable(intent.items),
      shippingAddress: intent.shippingAddress!,
      pricing: intent.pricing,
      deliveryMode: deliveryMode,
      paymentMethod: intent.paymentMethod,
      paymentId: paymentId,
      razorpayOrderId: razorpayOrderId,
      signature: signature,
      paymentStatus: paymentStatus ?? (paymentId == 'COD' ? 'PENDING' : 'PAID'),
      orderStatus: orderStatus,
      createdAt: now,
      estimatedDeliveryDate: estimatedDate,
    );
  }

  /// Total item count across all ordered units.
  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items.map((i) => i.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'pricing': pricing.toMap(),
      'deliveryMode': deliveryMode,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'razorpayOrderId': razorpayOrderId,
      'signature': signature,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'createdAt': createdAt.toIso8601String(),
      'estimatedDeliveryDate': estimatedDeliveryDate.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => CartItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final addressMap = Map<String, dynamic>.from(map['shippingAddress'] as Map);
    final pricingMap = Map<String, dynamic>.from(map['pricing'] as Map);

    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return OrderModel(
      orderId: map['orderId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      items: items,
      shippingAddress: AddressModel.fromMap(addressMap),
      pricing: PriceBreakupModel.fromMap(pricingMap),
      deliveryMode: map['deliveryMode'] as String? ?? 'standard',
      paymentMethod: map['paymentMethod'] as String? ?? 'ONLINE',
      paymentId: map['paymentId'] as String?,
      razorpayOrderId: map['razorpayOrderId'] as String?,
      signature: map['signature'] as String?,
      paymentStatus: map['paymentStatus'] as String? ?? 'PENDING',
      orderStatus: map['orderStatus'] as String? ?? 'CONFIRMED',
      createdAt: parseDate(map['createdAt']),
      estimatedDeliveryDate: parseDate(map['estimatedDeliveryDate']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel &&
        other.orderId == orderId &&
        other.userId == userId &&
        listEquals(other.items, items) &&
        other.shippingAddress == shippingAddress &&
        other.pricing == pricing &&
        other.deliveryMode == deliveryMode &&
        other.paymentMethod == paymentMethod &&
        other.paymentId == paymentId &&
        other.paymentStatus == paymentStatus &&
        other.orderStatus == orderStatus;
  }

  @override
  int get hashCode => Object.hash(
        orderId,
        userId,
        Object.hashAll(items),
        shippingAddress,
        pricing,
        deliveryMode,
        paymentMethod,
        paymentId,
        paymentStatus,
        orderStatus,
      );

  @override
  String toString() {
    return 'OrderModel(orderId: $orderId, userId: $userId, items: ${items.length}, grandTotal: ${pricing.grandTotal}, status: $orderStatus)';
  }
}
