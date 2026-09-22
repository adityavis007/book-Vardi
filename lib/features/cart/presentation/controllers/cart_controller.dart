import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';
import '../../data/cart_repository.dart';
import '../../domain/cart_item_model.dart';
import '../../domain/price_breakup_model.dart';

/// Stream provider for user's cart items from Firestore.
/// Emits empty list for unauthenticated/guest sessions.
final cartItemsStreamProvider = StreamProvider<List<CartItemModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.user;

  if (user == null || user.userId.isEmpty) {
    return Stream.value(const <CartItemModel>[]);
  }

  final cartRepo = ref.watch(cartRepositoryProvider);
  return cartRepo.watchCart(user.userId);
});

/// Synchronous provider extracting cart items from [cartItemsStreamProvider]
/// with safe fallback to empty list.
final cartItemsListProvider = Provider<List<CartItemModel>>((ref) {
  return ref.watch(cartItemsStreamProvider).valueOrNull ?? const <CartItemModel>[];
});

/// Reactive pricing breakdown provider calculating subtotal, shipping fees, and grand total.
final cartTotalProvider = Provider<PriceBreakupModel>((ref) {
  final items = ref.watch(cartItemsListProvider);
  return PriceBreakupModel.fromItems(items);
});

/// Reactive badge counter provider aggregating total units across all cart items.
final cartBadgeCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartItemsListProvider);
  return items.fold<int>(0, (total, item) => total + item.quantity);
});

/// Controller providing operations for Cart mutations.
class CartController {
  final Ref _ref;

  CartController(this._ref);

  String? get _currentUserId => _ref.read(authControllerProvider).user?.userId;

  ICartRepository get _cartRepo => _ref.read(cartRepositoryProvider);

  /// Adds a product to the cart with specified variant and quantity.
  /// Returns `true` if operation was dispatched to repository, `false` if user is unauthenticated.
  Future<bool> addToCart(
    ProductModel product, {
    VariantModel? variant,
    int quantity = 1,
  }) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      return false;
    }

    final cartItem = CartItemModel.fromProduct(
      product,
      variant: variant,
      quantity: quantity,
    );

    await _cartRepo.addToCart(userId, cartItem);
    return true;
  }

  /// Sets an explicit quantity for a given cart line item.
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    await _cartRepo.updateQuantity(userId, cartItemId, quantity);
  }

  /// Increments quantity of a line item by 1 unit.
  Future<void> incrementQuantity(String cartItemId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    final currentItems = await _cartRepo.fetchCart(userId);
    final itemIndex = currentItems.indexWhere((item) => item.id == cartItemId);
    if (itemIndex == -1) return;

    final currentItem = currentItems[itemIndex];
    await _cartRepo.updateQuantity(userId, cartItemId, currentItem.quantity + 1);
  }

  /// Decrements quantity of a line item by 1 unit.
  /// If quantity becomes 0, line item is removed.
  Future<void> decrementQuantity(String cartItemId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    final currentItems = await _cartRepo.fetchCart(userId);
    final itemIndex = currentItems.indexWhere((item) => item.id == cartItemId);
    if (itemIndex == -1) return;

    final currentItem = currentItems[itemIndex];
    await _cartRepo.updateQuantity(userId, cartItemId, currentItem.quantity - 1);
  }

  /// Removes an individual line item from the cart.
  Future<void> removeFromCart(String cartItemId) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    await _cartRepo.removeFromCart(userId, cartItemId);
  }

  /// Clears all line items from the user's cart.
  Future<void> clearCart() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    await _cartRepo.clearCart(userId);
  }
}

/// Global Riverpod provider for [CartController].
final cartControllerProvider = Provider<CartController>((ref) {
  return CartController(ref);
});
