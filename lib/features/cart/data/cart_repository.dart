import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cart_item_model.dart';

/// Abstract contract for Cart data operations.
abstract class ICartRepository {
  /// Watches real-time updates of all items in the user's shopping cart.
  Stream<List<CartItemModel>> watchCart(String userId);

  /// Fetches a one-time snapshot of the user's cart items.
  Future<List<CartItemModel>> fetchCart(String userId);

  /// Adds a [CartItemModel] to the user's cart.
  /// If the line item already exists, merges and increments quantity up to max limit.
  Future<void> addToCart(String userId, CartItemModel item);

  /// Updates the quantity of a specific cart line item.
  /// If [quantity] is <= 0, the item is removed from the cart.
  /// Enforces maximum SKU unit constraints.
  Future<void> updateQuantity(String userId, String cartItemId, int quantity);

  /// Removes a single line item from the cart.
  Future<void> removeFromCart(String userId, String cartItemId);

  /// Clears all items from the user's cart.
  Future<void> clearCart(String userId);
}

/// Cloud Firestore implementation of [ICartRepository].
/// Stores line items at: `users/{userId}/cart/{productId_variantId}`.
class FirestoreCartRepository implements ICartRepository {
  /// Maximum units allowed per SKU in the cart (e.g. max 5 uniforms per SKU).
  static const int maxUnitsPerSku = 5;

  final FirebaseFirestore _firestore;

  FirestoreCartRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cartCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('cart');
  }

  @override
  Stream<List<CartItemModel>> watchCart(String userId) {
    return _cartCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItemModel.fromMap(data);
      }).toList();
    });
  }

  @override
  Future<List<CartItemModel>> fetchCart(String userId) async {
    final snapshot = await _cartCollection(userId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CartItemModel.fromMap(data);
    }).toList();
  }

  @override
  Future<void> addToCart(String userId, CartItemModel item) async {
    final docRef = _cartCollection(userId).doc(item.id);
    final docSnapshot = await docRef.get();

    final int allowedMax = _resolveAllowedMax(item.maxStock);

    if (docSnapshot.exists && docSnapshot.data() != null) {
      final existing = CartItemModel.fromMap(docSnapshot.data()!);
      final int newQuantity = (existing.quantity + item.quantity).clamp(1, allowedMax);
      await docRef.update({
        'quantity': newQuantity,
      });
    } else {
      final int initialQuantity = item.quantity.clamp(1, allowedMax);
      final itemToSave = item.copyWith(quantity: initialQuantity);
      await docRef.set(itemToSave.toMap());
    }
  }

  @override
  Future<void> updateQuantity(String userId, String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(userId, cartItemId);
      return;
    }

    final docRef = _cartCollection(userId).doc(cartItemId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists || docSnapshot.data() == null) return;

    final existing = CartItemModel.fromMap(docSnapshot.data()!);
    final int allowedMax = _resolveAllowedMax(existing.maxStock);
    final int clampedQuantity = quantity.clamp(1, allowedMax);

    await docRef.update({
      'quantity': clampedQuantity,
    });
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    await _cartCollection(userId).doc(cartItemId).delete();
  }

  @override
  Future<void> clearCart(String userId) async {
    final snapshot = await _cartCollection(userId).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  int _resolveAllowedMax(int itemMaxStock) {
    if (itemMaxStock <= 0) return maxUnitsPerSku;
    return itemMaxStock < maxUnitsPerSku ? itemMaxStock : maxUnitsPerSku;
  }
}

/// Global Riverpod provider for Cart Repository.
final cartRepositoryProvider = Provider<ICartRepository>((ref) {
  return FirestoreCartRepository();
});
