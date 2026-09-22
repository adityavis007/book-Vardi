import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';

void main() {
  group('PriceBreakupModel Domain & Pricing Engine Tests', () {
    test('validates core formula: Grand Total = Subtotal + Delivery - Discounts', () {
      // Subtotal: 800, Delivery: 50, Discounts: 50 + 20 = 70 -> GrandTotal: 780
      final breakup = PriceBreakupModel.calculate(
        subtotal: 800.0,
        schoolBulkDiscount: 50.0,
        couponDiscount: 20.0,
      );

      expect(breakup.subtotal, equals(800.0));
      expect(breakup.deliveryCharge, equals(50.0));
      expect(breakup.schoolBulkDiscount, equals(50.0));
      expect(breakup.couponDiscount, equals(20.0));
      expect(breakup.totalDiscounts, equals(70.0));
      // Formula: 800 + 50 - 70 = 780
      expect(breakup.grandTotal, equals(780.0));
      expect(breakup.isFreeDelivery, isFalse);
      expect(breakup.amountToFreeDelivery, equals(199.0)); // 999 - 800 = 199
    });

    test('delivery fee is FREE (₹0) when subtotal > ₹999', () {
      // Subtotal: 1000 (> 999 threshold)
      final breakup = PriceBreakupModel.calculate(
        subtotal: 1000.0,
        schoolBulkDiscount: 100.0,
      );

      expect(breakup.subtotal, equals(1000.0));
      expect(breakup.deliveryCharge, equals(0.0));
      expect(breakup.isFreeDelivery, isTrue);
      expect(breakup.amountToFreeDelivery, equals(0.0));
      // Formula: 1000 + 0 - 100 = 900
      expect(breakup.grandTotal, equals(900.0));
    });

    test('delivery fee is ₹50 when subtotal is exactly ₹999', () {
      // Threshold requires subtotal > 999. Exactly 999 still incurs ₹50 delivery
      final breakup = PriceBreakupModel.calculate(
        subtotal: 999.0,
      );

      expect(breakup.subtotal, equals(999.0));
      expect(breakup.deliveryCharge, equals(50.0));
      expect(breakup.isFreeDelivery, isFalse);
      expect(breakup.amountToFreeDelivery, equals(0.0));
      // Formula: 999 + 50 - 0 = 1049
      expect(breakup.grandTotal, equals(1049.0));
    });

    test('empty cart (subtotal = 0) incurs ₹0 delivery and ₹0 grand total', () {
      final breakup = PriceBreakupModel.calculate(
        subtotal: 0.0,
      );

      expect(breakup.subtotal, equals(0.0));
      expect(breakup.deliveryCharge, equals(0.0));
      expect(breakup.isFreeDelivery, isFalse);
      expect(breakup.grandTotal, equals(0.0));
      expect(breakup.amountToFreeDelivery, equals(999.0));
    });

    test('grandTotal clamps to 0.0 when discounts exceed subtotal + delivery', () {
      // Subtotal: 100, Delivery: 50 (Total: 150), Discounts: 200
      final breakup = PriceBreakupModel.calculate(
        subtotal: 100.0,
        schoolBulkDiscount: 100.0,
        couponDiscount: 100.0,
      );

      expect(breakup.subtotal, equals(100.0));
      expect(breakup.deliveryCharge, equals(50.0));
      expect(breakup.totalDiscounts, equals(200.0));
      // 100 + 50 - 200 = -50 -> clamped to 0.0
      expect(breakup.grandTotal, equals(0.0));
    });

    test('fromItems computes subtotal accurately across multiple cart items', () {
      final items = [
        const CartItemModel(
          productId: 'prod_1',
          productName: 'Shirt',
          unitPrice: 400.0,
          quantity: 2, // 800
        ),
        const CartItemModel(
          productId: 'prod_2',
          productName: 'Tie',
          unitPrice: 150.0,
          quantity: 1, // 150
        ),
        const CartItemModel(
          productId: 'prod_3',
          productName: 'Socks',
          unitPrice: 100.0,
          quantity: 2, // 200
        ),
      ];
      // Total subtotal = 800 + 150 + 200 = 1150 (> 999 => free delivery)
      final breakup = PriceBreakupModel.fromItems(
        items,
        schoolBulkDiscount: 50.0,
        couponDiscount: 100.0,
      );

      expect(breakup.subtotal, equals(1150.0));
      expect(breakup.deliveryCharge, equals(0.0));
      expect(breakup.isFreeDelivery, isTrue);
      expect(breakup.totalDiscounts, equals(150.0));
      // Formula: 1150 + 0 - 150 = 1000
      expect(breakup.grandTotal, equals(1000.0));
    });

    test('copyWith updates specified fields only', () {
      final initial = PriceBreakupModel.calculate(subtotal: 500.0);
      final updated = initial.copyWith(grandTotal: 520.0);

      expect(updated.subtotal, equals(500.0));
      expect(updated.deliveryCharge, equals(50.0));
      expect(updated.grandTotal, equals(520.0));
    });

    test('serialization toMap / fromMap and toJson / fromJson round-trips cleanly', () {
      final original = PriceBreakupModel.calculate(
        subtotal: 750.0,
        schoolBulkDiscount: 30.0,
        couponDiscount: 50.0,
      );

      final map = original.toMap();
      final fromMap = PriceBreakupModel.fromMap(map);
      expect(fromMap, equals(original));

      final json = original.toJson();
      final fromJson = PriceBreakupModel.fromJson(json);
      expect(fromJson, equals(original));
      expect(fromJson.hashCode, equals(original.hashCode));
    });

    test('value equality and toString', () {
      final a = PriceBreakupModel.calculate(subtotal: 600.0);
      final b = PriceBreakupModel.calculate(subtotal: 600.0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('PriceBreakupModel'));
      expect(a.toString(), contains('subtotal: 600.0'));
      expect(a.toString(), contains('grandTotal: 650.0'));
    });
  });
}
