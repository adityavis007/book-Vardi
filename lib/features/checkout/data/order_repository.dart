import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order_intent_model.dart';
import '../domain/order_model.dart';

/// Abstract contract for the customer orders persistence repository.
abstract class IOrderRepository {
  /// Writes a new customer order to the `orders` collection and returns the generated business [orderId].
  Future<String> createOrder({
    required String userId,
    required OrderIntentModel intent,
    required String deliveryMode,
    required String status,
    String? paymentId,
    String? razorpayOrderId,
    String? signature,
    String? paymentStatus,
  });

  /// Fetches an [OrderModel] by its unique [orderId].
  Future<OrderModel?> fetchOrder(String orderId);

  /// Fetches all orders belonging to [userId] sorted by creation timestamp descending.
  Future<List<OrderModel>> fetchUserOrders(String userId);

  /// Real-time stream of all orders for [userId].
  Stream<List<OrderModel>> watchUserOrders(String userId);
}

/// Production implementation of [IOrderRepository] backed by Cloud Firestore.
class FirestoreOrderRepository implements IOrderRepository {
  final FirebaseFirestore _firestore;

  FirestoreOrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  /// Generates a standardized human-readable order identifier (e.g. `#BV-2026-9812`).
  static String generateOrderId() {
    final year = DateTime.now().year;
    final randomSuffix = 1000 + Random().nextInt(9000);
    return '#BV-$year-$randomSuffix';
  }

  @override
  Future<String> createOrder({
    required String userId,
    required OrderIntentModel intent,
    required String deliveryMode,
    required String status,
    String? paymentId,
    String? razorpayOrderId,
    String? signature,
    String? paymentStatus,
  }) async {
    final orderId = generateOrderId();

    final order = OrderModel.fromIntent(
      orderId: orderId,
      userId: userId,
      intent: intent,
      deliveryMode: deliveryMode,
      orderStatus: status,
      paymentId: paymentId,
      razorpayOrderId: razorpayOrderId,
      signature: signature,
      paymentStatus: paymentStatus,
    );

    await _ordersCollection.doc(orderId).set(order.toMap());
    return orderId;
  }

  @override
  Future<OrderModel?> fetchOrder(String orderId) async {
    final snapshot = await _ordersCollection.doc(orderId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return OrderModel.fromMap(snapshot.data()!);
  }

  @override
  Future<List<OrderModel>> fetchUserOrders(String userId) async {
    final snapshot = await _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList());
  }
}

/// Global Riverpod provider for [IOrderRepository].
final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  return FirestoreOrderRepository();
});

/// Riverpod FutureProvider to fetch an order document by its business [orderId].
final orderByIdProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.fetchOrder(orderId);
});
