import 'package:flutter/foundation.dart';
import '../../cart/domain/cart_item_model.dart';
import '../../cart/domain/price_breakup_model.dart';
import '../../checkout/domain/address_model.dart';
import 'tracking_step_model.dart';

/// Domain entity representing a customer order for order history and real-time tracking.
@immutable
class OrderModel {
  final String orderId;
  final String userId;
  final List<CartItemModel> items;
  final AddressModel shippingAddress;
  final PriceBreakupModel pricing;
  final String deliveryMode;
  final String paymentMethod;
  final String? paymentId;
  final String? razorpayOrderId;
  final String? signature;
  final String paymentStatus;
  final OrderStatus orderStatus;
  final DateTime createdAt;
  final DateTime estimatedDeliveryDate;
  final TrackingMetadata trackingMetadata;
  final String? cancellationReason;

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
    this.trackingMetadata = const TrackingMetadata(),
    this.cancellationReason,
  });

  /// Total count of items inside this order.
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Generates the ordered vertical timeline steps with live progress indicator.
  List<TrackingStepModel> buildTrackingSteps() {
    if (orderStatus == OrderStatus.cancelled) {
      return [
        TrackingStepModel(
          status: OrderStatus.confirmed,
          title: 'Order Placed',
          description: 'Your order was received.',
          timestamp: createdAt,
          isCompleted: true,
          isCurrent: false,
        ),
        TrackingStepModel(
          status: OrderStatus.cancelled,
          title: 'Order Cancelled',
          description: cancellationReason != null && cancellationReason!.isNotEmpty
              ? 'Reason: $cancellationReason'
              : 'Order was cancelled and refund initiated.',
          timestamp: null,
          isCompleted: true,
          isCurrent: true,
        ),
      ];
    }

    final currentIndex = orderStatus.stepIndex;

    return [
      TrackingStepModel(
        status: OrderStatus.confirmed,
        title: 'Order Confirmed',
        description: 'Order placed & payment verified.',
        timestamp: createdAt,
        isCompleted: currentIndex >= 0,
        isCurrent: currentIndex == 0,
      ),
      TrackingStepModel(
        status: OrderStatus.packed,
        title: 'Packed & Ready',
        description: 'Items packed & quality verified at warehouse.',
        timestamp: null,
        isCompleted: currentIndex >= 1,
        isCurrent: currentIndex == 1,
      ),
      TrackingStepModel(
        status: OrderStatus.shipped,
        title: 'Shipped',
        description: trackingMetadata.carrierName != null
            ? 'Handed over to ${trackingMetadata.carrierName}'
            : 'In transit to distribution hub',
        timestamp: trackingMetadata.shippedAt,
        isCompleted: currentIndex >= 2,
        isCurrent: currentIndex == 2,
      ),
      TrackingStepModel(
        status: OrderStatus.outForDelivery,
        title: 'Out for Delivery',
        description: 'Courier agent is on the way to your address.',
        timestamp: null,
        isCompleted: currentIndex >= 3,
        isCurrent: currentIndex == 3,
      ),
      TrackingStepModel(
        status: OrderStatus.delivered,
        title: 'Delivered',
        description: 'Package delivered at your doorstep.',
        timestamp: trackingMetadata.deliveredAt,
        isCompleted: currentIndex >= 4,
        isCurrent: currentIndex == 4,
      ),
    ];
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawItems = (map['items'] as List<dynamic>?) ?? [];
    final itemsList = rawItems
        .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final addressMap = (map['shippingAddress'] as Map<String, dynamic>?) ?? {};
    final pricingMap = (map['pricing'] as Map<String, dynamic>?) ?? {};

    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is String) {
        return DateTime.tryParse(value) ?? fallback;
      }
      try {
        // Handle Firestore Timestamp
        final dynamic dynamicVal = value;
        if (dynamicVal.toDate != null) {
          return dynamicVal.toDate() as DateTime;
        }
      } catch (_) {}
      return fallback;
    }

    final createdAt = parseDate(map['createdAt'], DateTime.now());
    final estimatedDeliveryDate = parseDate(
      map['estimatedDeliveryDate'],
      createdAt.add(const Duration(days: 4)),
    );

    return OrderModel(
      orderId: (map['orderId'] as String?) ?? docId ?? '',
      userId: (map['userId'] as String?) ?? '',
      items: itemsList,
      shippingAddress: AddressModel.fromMap(addressMap),
      pricing: PriceBreakupModel.fromJson(pricingMap),
      deliveryMode: (map['deliveryMode'] as String?) ?? 'standard',
      paymentMethod: (map['paymentMethod'] as String?) ?? 'COD',
      paymentId: map['paymentId'] as String?,
      razorpayOrderId: map['razorpayOrderId'] as String?,
      signature: map['signature'] as String?,
      paymentStatus: (map['paymentStatus'] as String?) ?? 'PENDING',
      orderStatus: OrderStatus.fromString(map['orderStatus'] as String?),
      createdAt: createdAt,
      estimatedDeliveryDate: estimatedDeliveryDate,
      trackingMetadata: TrackingMetadata.fromMap(
        map['trackingMetadata'] as Map<String, dynamic>?,
      ),
      cancellationReason: map['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items.map((i) => i.toJson()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'pricing': pricing.toJson(),
      'deliveryMode': deliveryMode,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'razorpayOrderId': razorpayOrderId,
      'signature': signature,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus.toFirestoreValue(),
      'createdAt': createdAt.toIso8601String(),
      'estimatedDeliveryDate': estimatedDeliveryDate.toIso8601String(),
      'trackingMetadata': trackingMetadata.toMap(),
      'cancellationReason': cancellationReason,
    };
  }

  OrderModel copyWith({
    String? orderId,
    String? userId,
    List<CartItemModel>? items,
    AddressModel? shippingAddress,
    PriceBreakupModel? pricing,
    String? deliveryMode,
    String? paymentMethod,
    String? paymentId,
    String? razorpayOrderId,
    String? signature,
    String? paymentStatus,
    OrderStatus? orderStatus,
    DateTime? createdAt,
    DateTime? estimatedDeliveryDate,
    TrackingMetadata? trackingMetadata,
    String? cancellationReason,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      pricing: pricing ?? this.pricing,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      signature: signature ?? this.signature,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      createdAt: createdAt ?? this.createdAt,
      estimatedDeliveryDate: estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      trackingMetadata: trackingMetadata ?? this.trackingMetadata,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
