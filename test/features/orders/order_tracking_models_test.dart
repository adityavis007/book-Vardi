import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/features/orders/domain/tracking_step_model.dart';

void main() {
  group('OrderStatus Enum Tests', () {
    test('fromString parses all lifecycle states correctly', () {
      expect(OrderStatus.fromString('CONFIRMED'), equals(OrderStatus.confirmed));
      expect(OrderStatus.fromString('PACKED'), equals(OrderStatus.packed));
      expect(OrderStatus.fromString('SHIPPED'), equals(OrderStatus.shipped));
      expect(OrderStatus.fromString('OUT_FOR_DELIVERY'), equals(OrderStatus.outForDelivery));
      expect(OrderStatus.fromString('OUT FOR DELIVERY'), equals(OrderStatus.outForDelivery));
      expect(OrderStatus.fromString('DELIVERED'), equals(OrderStatus.delivered));
      expect(OrderStatus.fromString('CANCELLED'), equals(OrderStatus.cancelled));
      expect(OrderStatus.fromString('UNKNOWN'), equals(OrderStatus.pending));
      expect(OrderStatus.fromString(null), equals(OrderStatus.pending));
    });

    test('stepIndex assigns correct progressive hierarchy', () {
      expect(OrderStatus.confirmed.stepIndex, equals(0));
      expect(OrderStatus.packed.stepIndex, equals(1));
      expect(OrderStatus.shipped.stepIndex, equals(2));
      expect(OrderStatus.outForDelivery.stepIndex, equals(3));
      expect(OrderStatus.delivered.stepIndex, equals(4));
    });
  });

  group('OrderModel & Tracking Timeline Tests (TASK-053)', () {
    final sampleAddress = AddressModel(
      addressId: 'addr_1',
      fullName: 'Sunita Sharma',
      phone: '9876543210',
      addressLine1: 'Flat 402, Lotus Apartments',
      city: 'Lucknow',
      state: 'Uttar Pradesh',
      pincode: '226028',
    );

    final samplePricing = PriceBreakupModel(
      subtotal: 999.0,
      deliveryCharge: 0.0,
      grandTotal: 999.0,
    );

    final sampleItems = [
      CartItemModel(
        productId: 'prod_uniform_boys_summer',
        productName: 'Boys Summer Uniform Set',
        unitPrice: 399.0,
        quantity: 2,
        variantId: 'var_u_b_28',
        variantLabel: 'Size 28',
      ),
    ];

    test('buildTrackingSteps marks progressive milestones for SHIPPED order', () {
      final order = OrderModel(
        orderId: '#BV-2026-9812',
        userId: 'user_1',
        items: sampleItems,
        shippingAddress: sampleAddress,
        pricing: samplePricing,
        deliveryMode: 'standard',
        paymentMethod: 'COD',
        paymentStatus: 'PENDING',
        orderStatus: OrderStatus.shipped,
        createdAt: DateTime(2026, 9, 19, 10, 0),
        estimatedDeliveryDate: DateTime(2026, 9, 23, 18, 0),
        trackingMetadata: const TrackingMetadata(
          carrierName: 'BlueDart Express',
          trackingNumber: 'BD-991288',
        ),
      );

      final steps = order.buildTrackingSteps();
      expect(steps.length, equals(5));

      // Step 0: Confirmed (Completed)
      expect(steps[0].status, equals(OrderStatus.confirmed));
      expect(steps[0].isCompleted, isTrue);
      expect(steps[0].isCurrent, isFalse);

      // Step 1: Packed (Completed)
      expect(steps[1].status, equals(OrderStatus.packed));
      expect(steps[1].isCompleted, isTrue);
      expect(steps[1].isCurrent, isFalse);

      // Step 2: Shipped (Completed and Current)
      expect(steps[2].status, equals(OrderStatus.shipped));
      expect(steps[2].isCompleted, isTrue);
      expect(steps[2].isCurrent, isTrue);
      expect(steps[2].description, contains('BlueDart Express'));

      // Step 3: Out for Delivery (Pending)
      expect(steps[3].status, equals(OrderStatus.outForDelivery));
      expect(steps[3].isCompleted, isFalse);

      // Step 4: Delivered (Pending)
      expect(steps[4].status, equals(OrderStatus.delivered));
      expect(steps[4].isCompleted, isFalse);
    });

    test('buildTrackingSteps generates cancellation step for CANCELLED order', () {
      final order = OrderModel(
        orderId: '#BV-2026-9813',
        userId: 'user_1',
        items: sampleItems,
        shippingAddress: sampleAddress,
        pricing: samplePricing,
        deliveryMode: 'standard',
        paymentMethod: 'COD',
        paymentStatus: 'PENDING',
        orderStatus: OrderStatus.cancelled,
        cancellationReason: 'Ordered wrong size',
        createdAt: DateTime(2026, 9, 19, 10, 0),
        estimatedDeliveryDate: DateTime(2026, 9, 23, 18, 0),
      );

      final steps = order.buildTrackingSteps();
      expect(steps.length, equals(2));
      expect(steps[0].status, equals(OrderStatus.confirmed));
      expect(steps[1].status, equals(OrderStatus.cancelled));
      expect(steps[1].isCompleted, isTrue);
      expect(steps[1].description, contains('Ordered wrong size'));
    });

    test('fromMap and toMap serialize and deserialize accurately', () {
      final order = OrderModel(
        orderId: '#BV-2026-9814',
        userId: 'user_2',
        items: sampleItems,
        shippingAddress: sampleAddress,
        pricing: samplePricing,
        deliveryMode: 'express',
        paymentMethod: 'UPI',
        paymentId: 'pay_test_123',
        paymentStatus: 'PAID',
        orderStatus: OrderStatus.confirmed,
        createdAt: DateTime(2026, 9, 19, 11, 0),
        estimatedDeliveryDate: DateTime(2026, 9, 21, 18, 0),
      );

      final map = order.toMap();
      final reconstituted = OrderModel.fromMap(map);

      expect(reconstituted.orderId, equals(order.orderId));
      expect(reconstituted.userId, equals(order.userId));
      expect(reconstituted.items.length, equals(1));
      expect(reconstituted.items.first.productName, equals('Boys Summer Uniform Set'));
      expect(reconstituted.pricing.grandTotal, equals(999.0));
      expect(reconstituted.orderStatus, equals(OrderStatus.confirmed));
      expect(reconstituted.totalItemCount, equals(2));
    });
  });
}
