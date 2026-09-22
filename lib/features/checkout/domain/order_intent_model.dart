import 'package:flutter/foundation.dart';
import '../../cart/domain/cart_item_model.dart';
import '../../cart/domain/price_breakup_model.dart';
import 'address_model.dart';

/// Ephemeral checkout state domain entity encapsulating the active order intent.
/// Used across the 3-step checkout pipeline:
/// Step 1: Review items & pricing
/// Step 2: Select/Add shipping address
/// Step 3: Select payment method & complete transaction
///
/// Supports standard persistent cart checkout as well as direct PDP "Buy Now" bypass sessions.
@immutable
class OrderIntentModel {
  /// Line items to be ordered.
  final List<CartItemModel> items;

  /// Selected shipping destination address (null until Step 2).
  final AddressModel? shippingAddress;

  /// Active financial calculation breakdown.
  final PriceBreakupModel pricing;

  /// Whether this checkout session directly bypasses persistent Firestore cart.
  final bool isBuyNowBypass;

  /// Ephemeral draft order reference ID.
  final String? orderId;

  /// User ID placing the order.
  final String? userId;

  /// Selected payment mode ('ONLINE' | 'COD' | 'UPI' | 'CARD').
  final String paymentMethod;

  /// Creation timestamp.
  final DateTime createdAt;

  const OrderIntentModel({
    required this.items,
    this.shippingAddress,
    required this.pricing,
    this.isBuyNowBypass = false,
    this.orderId,
    this.userId,
    this.paymentMethod = 'ONLINE',
    required this.createdAt,
  });

  /// Factory constructor to initialize an intent from items and pricing.
  factory OrderIntentModel.create({
    required List<CartItemModel> items,
    required PriceBreakupModel pricing,
    AddressModel? shippingAddress,
    bool isBuyNowBypass = false,
    String? orderId,
    String? userId,
    String paymentMethod = 'ONLINE',
    DateTime? createdAt,
  }) {
    return OrderIntentModel(
      items: List.unmodifiable(items),
      shippingAddress: shippingAddress,
      pricing: pricing,
      isBuyNowBypass: isBuyNowBypass,
      orderId: orderId,
      userId: userId,
      paymentMethod: paymentMethod,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Total units across all items in this order intent.
  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Whether the checkout intent has met all prerequisites to proceed to payment.
  bool get isReadyForPayment =>
      items.isNotEmpty &&
      shippingAddress != null &&
      shippingAddress!.isValid &&
      pricing.grandTotal >= 0;

  OrderIntentModel copyWith({
    List<CartItemModel>? items,
    AddressModel? shippingAddress,
    PriceBreakupModel? pricing,
    bool? isBuyNowBypass,
    String? orderId,
    String? userId,
    String? paymentMethod,
    DateTime? createdAt,
  }) {
    return OrderIntentModel(
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      pricing: pricing ?? this.pricing,
      isBuyNowBypass: isBuyNowBypass ?? this.isBuyNowBypass,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory OrderIntentModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => CartItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    AddressModel? address;
    if (map['shippingAddress'] != null) {
      address = AddressModel.fromMap(
        Map<String, dynamic>.from(map['shippingAddress'] as Map),
      );
    }

    PriceBreakupModel pricing;
    if (map['pricing'] != null) {
      pricing = PriceBreakupModel.fromMap(
        Map<String, dynamic>.from(map['pricing'] as Map),
      );
    } else {
      pricing = PriceBreakupModel.fromItems(items);
    }

    DateTime parsedDate;
    if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return OrderIntentModel(
      items: items,
      shippingAddress: address,
      pricing: pricing,
      isBuyNowBypass: map['isBuyNowBypass'] as bool? ?? false,
      orderId: map['orderId'] as String?,
      userId: map['userId'] as String?,
      paymentMethod: map['paymentMethod'] as String? ?? 'ONLINE',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((i) => i.toMap()).toList(),
      'shippingAddress': shippingAddress?.toMap(),
      'pricing': pricing.toMap(),
      'isBuyNowBypass': isBuyNowBypass,
      'orderId': orderId,
      'userId': userId,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderIntentModel.fromJson(Map<String, dynamic> json) =>
      OrderIntentModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderIntentModel &&
        listEquals(other.items, items) &&
        other.shippingAddress == shippingAddress &&
        other.pricing == pricing &&
        other.isBuyNowBypass == isBuyNowBypass &&
        other.orderId == orderId &&
        other.userId == userId &&
        other.paymentMethod == paymentMethod;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        shippingAddress,
        pricing,
        isBuyNowBypass,
        orderId,
        userId,
        paymentMethod,
      );

  @override
  String toString() {
    return 'OrderIntentModel(items: ${items.length}, totalUnits: $totalItemCount, grandTotal: ${pricing.grandTotal}, isBuyNow: $isBuyNowBypass, hasAddress: ${shippingAddress != null})';
  }
}
