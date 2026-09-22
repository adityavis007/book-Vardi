import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/wishlist_item_model.dart';

/// Abstract contract for Wishlist operations.
abstract class IWishlistRepository {
  /// Watches real-time updates of all saved items in the user's wishlist.
  Stream<List<WishlistItemModel>> watchWishlist(String userId);

  /// Fetches a one-time snapshot of the user's wishlist.
  Future<List<WishlistItemModel>> fetchWishlist(String userId);

  /// Checks whether a specific product is in the user's wishlist.
  Future<bool> isInWishlist(String userId, String productId);

  /// Watches whether a specific product is in the user's wishlist in real-time.
  Stream<bool> watchIsInWishlist(String userId, String productId);

  /// Toggles presence of an item in the wishlist.
  /// If item exists, removes it and returns `false`.
  /// If absent, adds it and returns `true`.
  Future<bool> toggleWishlist(String userId, WishlistItemModel item);

  /// Adds an item to the user's wishlist.
  Future<void> addToWishlist(String userId, WishlistItemModel item);

  /// Removes an item from the user's wishlist by [productId].
  Future<void> removeFromWishlist(String userId, String productId);

  /// Clears all items in the user's wishlist.
  Future<void> clearWishlist(String userId);
}

/// Cloud Firestore implementation of [IWishlistRepository].
/// Stores wishlist items at: `users/{userId}/wishlist/{productId}`.
class FirestoreWishlistRepository implements IWishlistRepository {
  final FirebaseFirestore _firestore;

  FirestoreWishlistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _wishlistCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('wishlist');
  }

  @override
  Stream<List<WishlistItemModel>> watchWishlist(String userId) {
    return _wishlistCollection(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('productId') || (data['productId'] as String).isEmpty) {
          data['productId'] = doc.id;
        }
        return WishlistItemModel.fromMap(data);
      }).toList();
    });
  }

  @override
  Future<List<WishlistItemModel>> fetchWishlist(String userId) async {
    final snapshot = await _wishlistCollection(userId)
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      if (!data.containsKey('productId') || (data['productId'] as String).isEmpty) {
        data['productId'] = doc.id;
      }
      return WishlistItemModel.fromMap(data);
    }).toList();
  }

  @override
  Future<bool> isInWishlist(String userId, String productId) async {
    final docSnapshot = await _wishlistCollection(userId).doc(productId).get();
    return docSnapshot.exists;
  }

  @override
  Stream<bool> watchIsInWishlist(String userId, String productId) {
    return _wishlistCollection(userId)
        .doc(productId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Future<bool> toggleWishlist(String userId, WishlistItemModel item) async {
    final docRef = _wishlistCollection(userId).doc(item.productId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.delete();
      return false;
    } else {
      await docRef.set(item.toMap());
      return true;
    }
  }

  @override
  Future<void> addToWishlist(String userId, WishlistItemModel item) async {
    await _wishlistCollection(userId).doc(item.productId).set(item.toMap());
  }

  @override
  Future<void> removeFromWishlist(String userId, String productId) async {
    await _wishlistCollection(userId).doc(productId).delete();
  }

  @override
  Future<void> clearWishlist(String userId) async {
    final snapshot = await _wishlistCollection(userId).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

/// Global Riverpod provider for Wishlist Repository.
final wishlistRepositoryProvider = Provider<IWishlistRepository>((ref) {
  return FirestoreWishlistRepository();
});
