import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/admin/data/admin_repository.dart';
import 'package:book_vardi/features/admin/presentation/controllers/admin_controller.dart';
import 'package:book_vardi/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:book_vardi/features/admin/presentation/widgets/admin_carrier_modal.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/features/orders/domain/tracking_step_model.dart';

class MockOrdersAdminRepository implements IAdminRepository {
  List<OrderModel> orders;
  String? lastUpdatedOrderId;
  OrderStatus? lastUpdatedStatus;
  String? lastCarrier;
  String? lastAwb;

  MockOrdersAdminRepository({required this.orders});

  @override
  Stream<AdminDashboardStats> watchDashboardStats() => const Stream.empty();

  @override
  Stream<List<ProductModel>> watchLowStockProducts({int threshold = 5}) => const Stream.empty();

  @override
  Stream<List<ProductModel>> watchAllProducts({String? searchQuery}) => const Stream.empty();

  @override
  Stream<List<OrderModel>> watchAllOrders({OrderStatus? statusFilter}) {
    if (statusFilter == null) return Stream.value(orders);
    return Stream.value(orders.where((o) => o.orderStatus == statusFilter).toList());
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? carrierName,
    String? trackingNumber,
  }) async {
    lastUpdatedOrderId = orderId;
    lastUpdatedStatus = newStatus;
    lastCarrier = carrierName;
    lastAwb = trackingNumber;

    final index = orders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      final existing = orders[index];
      orders[index] = OrderModel(
        orderId: existing.orderId,
        userId: existing.userId,
        items: existing.items,
        shippingAddress: existing.shippingAddress,
        pricing: existing.pricing,
        deliveryMode: existing.deliveryMode,
        paymentMethod: existing.paymentMethod,
        paymentStatus: existing.paymentStatus,
        orderStatus: newStatus,
        createdAt: existing.createdAt,
        estimatedDeliveryDate: existing.estimatedDeliveryDate,
        trackingMetadata: TrackingMetadata(
          carrierName: carrierName ?? existing.trackingMetadata.carrierName,
          trackingNumber: trackingNumber ?? existing.trackingMetadata.trackingNumber,
        ),
      );
    }
  }

  @override
  Future<String> saveProduct(ProductModel product) async => 'id';

  @override
  Future<void> deleteProduct(String productId) async {}
}

void main() {
  const sampleAddress = AddressModel(
    addressId: 'addr_1',
    fullName: 'Ramesh Sharma',
    phone: '9876543210',
    addressLine1: 'Flat 402, Lotus Apartments',
    city: 'Noida',
    state: 'Uttar Pradesh',
    pincode: '201301',
    addressType: 'Home',
  );

  final sampleItems = [
    const CartItemModel(
      productId: 'p1',
      productName: 'Navy Blue Uniform Blazer',
      variantLabel: 'Size 32',
      unitPrice: 850.0,
      quantity: 1,
    ),
  ];

  final sampleOrders = [
    OrderModel(
      orderId: 'ORD-CONFIRMED-1',
      userId: 'u1',
      items: sampleItems,
      shippingAddress: sampleAddress,
      pricing: const PriceBreakupModel(
        subtotal: 850.0,
        deliveryCharge: 0.0,
        grandTotal: 850.0,
      ),
      deliveryMode: 'Standard Delivery',
      paymentMethod: 'COD',
      paymentStatus: 'pending',
      orderStatus: OrderStatus.confirmed,
      createdAt: DateTime(2026, 9, 19, 10, 0),
      estimatedDeliveryDate: DateTime(2026, 9, 23),
    ),
    OrderModel(
      orderId: 'ORD-PACKED-2',
      userId: 'u2',
      items: sampleItems,
      shippingAddress: sampleAddress,
      pricing: const PriceBreakupModel(
        subtotal: 850.0,
        deliveryCharge: 0.0,
        grandTotal: 850.0,
      ),
      deliveryMode: 'Standard Delivery',
      paymentMethod: 'PREPAID',
      paymentStatus: 'paid',
      orderStatus: OrderStatus.packed,
      createdAt: DateTime(2026, 9, 19, 11, 0),
      estimatedDeliveryDate: DateTime(2026, 9, 23),
    ),
  ];

  group('TASK-061: Admin Orders & Carrier Modal Tests', () {
    testWidgets('AdminOrdersScreen renders orders and advances status to Packed', (tester) async {
      final mockRepo = MockOrdersAdminRepository(orders: List.of(sampleOrders));

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AdminOrdersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fulfillment Center'), findsOneWidget);
      expect(find.text('All Orders'), findsOneWidget);
      expect(find.text('Ramesh Sharma • 9876543210'), findsNWidgets(2));

      // Test "Pack & Ready" progression button for confirmed order
      final packBtn = find.text('Pack & Ready');
      expect(packBtn, findsOneWidget);
      await tester.tap(packBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.lastUpdatedOrderId, 'ORD-CONFIRMED-1');
      expect(mockRepo.lastUpdatedStatus, OrderStatus.packed);
    });

    testWidgets('AdminCarrierModal validates AWB and dispatches order', (tester) async {
      final mockRepo = MockOrdersAdminRepository(orders: List.of(sampleOrders));

      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AdminCarrierModal.show(context, orderId: 'ORD-PACKED-2'),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify Modal rendered
      expect(find.text('Dispatch Order'), findsOneWidget);
      expect(find.text('SELECT COURIER PARTNER'), findsOneWidget);
      expect(find.text('Delhivery'), findsOneWidget);

      // Select Delhivery
      await tester.tap(find.text('Delhivery'));
      await tester.pumpAndSettle();

      // Enter AWB
      final awbField = find.widgetWithText(TextFormField, 'AWB / Tracking Number *');
      expect(awbField, findsOneWidget);
      await tester.enterText(awbField, 'DEL99482710');
      await tester.pumpAndSettle();

      // Confirm dispatch
      final dispatchBtn = find.text('Confirm Dispatch & Ship');
      expect(dispatchBtn, findsOneWidget);
      await tester.tap(dispatchBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.lastUpdatedOrderId, 'ORD-PACKED-2');
      expect(mockRepo.lastUpdatedStatus, OrderStatus.shipped);
      expect(mockRepo.lastCarrier, 'Delhivery');
      expect(mockRepo.lastAwb, 'DEL99482710');
    });
  });
}
