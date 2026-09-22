import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../domain/order_model.dart';

/// Abstract contract for customer order queries, live tracking streams, and cancellations.
abstract class IOrdersRepository {
  /// Real-time stream of all orders belonging to [userId] sorted chronologically descending.
  Stream<List<OrderModel>> watchUserOrders(String userId);

  /// Real-time stream of a single order by [orderId] for live milestone tracking updates.
  Stream<OrderModel?> watchOrderById(String orderId);

  /// Direct one-time fetch of order details.
  Future<OrderModel?> fetchOrderById(String orderId);

  /// Cancels an active order with customer provided [reason].
  Future<void> cancelOrder(String orderId, String reason);
}

/// Production implementation backed by Cloud Firestore `orders` collection.
class FirestoreOrdersRepository implements IOrdersRepository {
  final FirebaseFirestore _firestore;

  FirestoreOrdersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    if (userId.isEmpty) {
      return Stream.value(const []);
    }

    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort descending by createdAt
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  @override
  Stream<OrderModel?> watchOrderById(String orderId) {
    if (orderId.isEmpty) {
      return Stream.value(null);
    }

    return _ordersCollection.doc(orderId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return OrderModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  @override
  Future<OrderModel?> fetchOrderById(String orderId) async {
    if (orderId.isEmpty) return null;
    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return OrderModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> cancelOrder(String orderId, String reason) async {
    await _ordersCollection.doc(orderId).update({
      'orderStatus': 'CANCELLED',
      'cancellationReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Provider for [IOrdersRepository].
final ordersRepositoryProvider = Provider<IOrdersRepository>((ref) {
  return FirestoreOrdersRepository();
});

/// Real-time stream provider of all orders for currently authenticated user.
final userOrdersStreamProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null || user.userId.isEmpty) {
    return Stream.value(const []);
  }
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.watchUserOrders(user.userId);
});

/// Real-time stream provider of a single order for live tracking.
final orderTrackingStreamProvider =
    StreamProvider.family.autoDispose<OrderModel?, String>((ref, orderId) {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.watchOrderById(orderId);
});
