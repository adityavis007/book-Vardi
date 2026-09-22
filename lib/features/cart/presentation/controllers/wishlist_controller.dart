import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../data/cart_repository.dart';
import '../../data/wishlist_repository.dart';
import '../../domain/cart_item_model.dart';
import '../../domain/wishlist_item_model.dart';

/// Real-time stream of wishlisted items for the current authenticated user.
/// Returns empty stream for guest / unauthenticated sessions.
final wishlistItemsStreamProvider = StreamProvider<List<WishlistItemModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.user;

  if (user == null || user.userId.isEmpty) {
    return Stream.value(const <WishlistItemModel>[]);
  }

  final wishlistRepo = ref.watch(wishlistRepositoryProvider);
  return wishlistRepo.watchWishlist(user.userId);
});

/// Synchronous list of wishlisted items with fallback to empty list.
final wishlistItemsListProvider = Provider<List<WishlistItemModel>>((ref) {
  return ref.watch(wishlistItemsStreamProvider).valueOrNull ?? const <WishlistItemModel>[];
});

/// Reactive count of items in the user's wishlist.
final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistItemsListProvider).length;
});

/// Controller handling mutations for Wishlist items.
class WishlistController {
  final Ref _ref;

  WishlistController(this._ref);

  String? get _currentUserId => _ref.read(authControllerProvider).user?.userId;

  IWishlistRepository get _wishlistRepo => _ref.read(wishlistRepositoryProvider);
  ICartRepository get _cartRepo => _ref.read(cartRepositoryProvider);

  /// Removes an item from the user's wishlist.
  Future<void> removeFromWishlist(String productId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    await _wishlistRepo.removeFromWishlist(userId, productId);
  }

  /// Toggles an item in the wishlist.
  Future<bool> toggleWishlist(WishlistItemModel item) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return false;

    return await _wishlistRepo.toggleWishlist(userId, item);
  }

  /// Moves a wishlisted item into the user's cart and removes it from the wishlist.
  Future<void> moveToCart(WishlistItemModel item) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    final cartItem = CartItemModel(
      productId: item.productId,
      productName: item.productName,
      schoolName: item.schoolName,
      imageUrl: item.imageUrl,
      unitPrice: item.price,
      quantity: 1,
    );

    await _cartRepo.addToCart(userId, cartItem);
    await _wishlistRepo.removeFromWishlist(userId, item.productId);
  }

  /// Clears all items in the user's wishlist.
  Future<void> clearWishlist() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    await _wishlistRepo.clearWishlist(userId);
  }
}

/// Global Riverpod provider for [WishlistController].
final wishlistControllerProvider = Provider<WishlistController>((ref) {
  return WishlistController(ref);
});
