import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/checkout/domain/order_intent_model.dart';

void main() {
  group('OrderIntentModel Domain Entity Tests', () {
    const address = AddressModel(
      addressId: 'addr_123',
      fullName: 'Sunita Sharma',
      phone: '9812345678',
      addressLine1: 'House 12, Green Avenue',
      city: 'Jaipur',
      state: 'Rajasthan',
      pincode: '302001',
    );

    const item1 = CartItemModel(
      productId: 'prod_book_1',
      productName: 'Science Class 7',
      unitPrice: 350.0,
      quantity: 2,
    );

    const item2 = CartItemModel(
      productId: 'prod_uniform_1',
      productName: 'School Polo Shirt',
      unitPrice: 600.0,
      quantity: 1,
    );

    final pricing = PriceBreakupModel.fromItems(const [item1, item2]);

    test('initializes with accurate properties and calculates totalItemCount', () {
      final intent = OrderIntentModel.create(
        items: const [item1, item2],
        pricing: pricing,
        shippingAddress: address,
        isBuyNowBypass: false,
      );

      expect(intent.items.length, equals(2));
      expect(intent.totalItemCount, equals(3)); // 2 + 1
      expect(intent.shippingAddress, equals(address));
      expect(intent.pricing.subtotal, equals(1300.0)); // (350 * 2) + 600
      expect(intent.isBuyNowBypass, isFalse);
      expect(intent.isReadyForPayment, isTrue);
    });

    test('isReadyForPayment returns false if items empty or address is missing/invalid', () {
      final noAddressIntent = OrderIntentModel.create(
        items: const [item1],
        pricing: PriceBreakupModel.fromItems(const [item1]),
        shippingAddress: null,
      );
      expect(noAddressIntent.isReadyForPayment, isFalse);

      final emptyItemsIntent = OrderIntentModel.create(
        items: const [],
        pricing: const PriceBreakupModel(deliveryCharge: 0, grandTotal: 0, subtotal: 0),
        shippingAddress: address,
      );
      expect(emptyItemsIntent.isReadyForPayment, isFalse);

      final invalidAddressIntent = OrderIntentModel.create(
        items: const [item1],
        pricing: PriceBreakupModel.fromItems(const [item1]),
        shippingAddress: address.copyWith(phone: 'invalid_phone'),
      );
      expect(invalidAddressIntent.isReadyForPayment, isFalse);
    });

    test('supports Buy Now direct bypass session flag', () {
      final buyNowIntent = OrderIntentModel.create(
        items: const [item2],
        pricing: PriceBreakupModel.fromItems(const [item2]),
        shippingAddress: address,
        isBuyNowBypass: true,
      );

      expect(buyNowIntent.isBuyNowBypass, isTrue);
      expect(buyNowIntent.totalItemCount, equals(1));
    });

    test('roundtrip serialization toMap / fromMap produces identical entity', () {
      final intent = OrderIntentModel.create(
        items: const [item1, item2],
        pricing: pricing,
        shippingAddress: address,
        isBuyNowBypass: true,
        orderId: 'intent_draft_99',
        userId: 'usr_88',
        paymentMethod: 'COD',
      );

      final map = intent.toMap();
      final reconstructed = OrderIntentModel.fromMap(map);

      expect(reconstructed.items.length, equals(2));
      expect(reconstructed.totalItemCount, equals(3));
      expect(reconstructed.shippingAddress?.fullName, equals('Sunita Sharma'));
      expect(reconstructed.shippingAddress?.pincode, equals('302001'));
      expect(reconstructed.pricing.grandTotal, equals(pricing.grandTotal));
      expect(reconstructed.isBuyNowBypass, isTrue);
      expect(reconstructed.orderId, equals('intent_draft_99'));
      expect(reconstructed.userId, equals('usr_88'));
      expect(reconstructed.paymentMethod, equals('COD'));
    });

    test('roundtrip serialization toJson / fromJson produces identical entity', () {
      final intent = OrderIntentModel.create(
        items: const [item1],
        pricing: PriceBreakupModel.fromItems(const [item1]),
        shippingAddress: address,
      );

      final json = intent.toJson();
      final reconstructed = OrderIntentModel.fromJson(json);

      expect(reconstructed.items.first.productName, equals('Science Class 7'));
      expect(reconstructed.shippingAddress?.city, equals('Jaipur'));
    });

    test('copyWith produces updated entity preserving unmodified attributes', () {
      final intent = OrderIntentModel.create(
        items: const [item1],
        pricing: PriceBreakupModel.fromItems(const [item1]),
        paymentMethod: 'ONLINE',
      );

      final updated = intent.copyWith(
        shippingAddress: address,
        paymentMethod: 'UPI',
      );

      expect(updated.shippingAddress, equals(address));
      expect(updated.paymentMethod, equals('UPI'));
      expect(updated.items.first.productId, equals(item1.productId));
      expect(updated.pricing, equals(intent.pricing));
    });
  });
}
