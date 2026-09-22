import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/cart/data/cart_repository.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/presentation/controllers/cart_controller.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';
import 'package:book_vardi/features/catalog/presentation/screens/product_detail_screen.dart';

class FakeAuthController extends StateNotifier<AuthState>
    implements AuthController {
  FakeAuthController(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCartRepository implements ICartRepository {
  final List<CartItemModel> _items = [];
  final StreamController<List<CartItemModel>> _controller =
      StreamController<List<CartItemModel>>.broadcast();

  FakeCartRepository([List<CartItemModel>? initialItems]) {
    if (initialItems != null) {
      _items.addAll(initialItems);
    }
  }

  void _notify() {
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Stream<List<CartItemModel>> watchCart(String userId) async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<List<CartItemModel>> fetchCart(String userId) async {
    return List.unmodifiable(_items);
  }

  @override
  Future<void> addToCart(String userId, CartItemModel item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      final existing = _items[index];
      _items[index] = existing.copyWith(quantity: existing.quantity + item.quantity);
    } else {
      _items.add(item);
    }
    _notify();
  }

  @override
  Future<void> updateQuantity(String userId, String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(userId, cartItemId);
      return;
    }
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      _notify();
    }
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    _items.removeWhere((i) => i.id == cartItemId);
    _notify();
  }

  @override
  Future<void> clearCart(String userId) async {
    _items.clear();
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('CartController & Reactive Providers Tests', () {
    const testUser = UserModel(
      userId: 'user_parent_77',
      email: 'parent@bookvardi.com',
      name: 'Aditya Test',
      role: UserRole.customer,
    );

    const testItem1 = CartItemModel(
      productId: 'prod_trouser',
      variantId: 'v_28',
      productName: 'DPS Trouser',
      unitPrice: 800.0,
      quantity: 2,
    );

    const testItem2 = CartItemModel(
      productId: 'prod_shirt',
      variantId: 'v_32',
      productName: 'DPS Shirt',
      unitPrice: 400.0,
      quantity: 1,
    );

    test('unauthenticated/guest: cartItemsStreamProvider emits empty list', () async {
      final fakeCart = FakeCartRepository([testItem1]);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState.unauthenticated(isGuest: true)),
          ),
          cartRepositoryProvider.overrideWithValue(fakeCart),
        ],
      );

      final items = await container.read(cartItemsStreamProvider.future);
      expect(items, isEmpty);

      final badgeCount = container.read(cartBadgeCountProvider);
      expect(badgeCount, equals(0));

      final total = container.read(cartTotalProvider);
      expect(total.subtotal, equals(0.0));
      expect(total.grandTotal, equals(0.0));

      container.dispose();
      fakeCart.dispose();
    });

    test('authenticated: cartItemsStreamProvider streams items and calculates badge & totals', () async {
      final fakeCart = FakeCartRepository([testItem1, testItem2]);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState.authenticated(testUser)),
          ),
          cartRepositoryProvider.overrideWithValue(fakeCart),
        ],
      );

      final items = await container.read(cartItemsStreamProvider.future);
      expect(items, hasLength(2));

      // Badge count is total quantity: 2 + 1 = 3
      final badgeCount = container.read(cartBadgeCountProvider);
      expect(badgeCount, equals(3));

      // Subtotal = 800 * 2 + 400 * 1 = 1600 + 400 = 2000 (> 999 => Free delivery)
      final total = container.read(cartTotalProvider);
      expect(total.subtotal, equals(2000.0));
      expect(total.deliveryCharge, equals(0.0));
      expect(total.isFreeDelivery, isTrue);
      expect(total.grandTotal, equals(2000.0));

      container.dispose();
      fakeCart.dispose();
    });

    test('CartController operations: addToCart, increment, decrement, remove, clear', () async {
      final fakeCart = FakeCartRepository();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState.authenticated(testUser)),
          ),
          cartRepositoryProvider.overrideWithValue(fakeCart),
        ],
      );

      final controller = container.read(cartControllerProvider);

      const product = ProductModel(
        productId: 'prod_shoes',
        name: 'School Shoes',
        description: 'Black shoes',
        categoryId: 'cat_shoes',
        basePrice: 900.0,
      );

      const variant = VariantModel(
        variantId: 'v_7',
        sku: 'SHOES-7',
        label: 'Size 7',
        price: 900.0,
        stock: 5,
      );

      // 1. addToCart
      final success = await controller.addToCart(product, variant: variant, quantity: 2);
      expect(success, isTrue);

      var items = await fakeCart.fetchCart(testUser.userId);
      expect(items, hasLength(1));
      expect(items.first.id, equals('prod_shoes_v_7'));
      expect(items.first.quantity, equals(2));

      // 2. incrementQuantity
      await container.read(cartItemsStreamProvider.future);
      await controller.incrementQuantity('prod_shoes_v_7');
      items = await fakeCart.fetchCart(testUser.userId);
      expect(items.first.quantity, equals(3));

      // 3. decrementQuantity
      await controller.decrementQuantity('prod_shoes_v_7');
      items = await fakeCart.fetchCart(testUser.userId);
      expect(items.first.quantity, equals(2));

      // 4. updateQuantity
      await controller.updateQuantity('prod_shoes_v_7', 4);
      items = await fakeCart.fetchCart(testUser.userId);
      expect(items.first.quantity, equals(4));

      // 5. removeFromCart
      await controller.removeFromCart('prod_shoes_v_7');
      items = await fakeCart.fetchCart(testUser.userId);
      expect(items, isEmpty);

      // 6. clearCart
      await fakeCart.addToCart(testUser.userId, testItem1);
      await controller.clearCart();
      items = await fakeCart.fetchCart(testUser.userId);
      expect(items, isEmpty);

      container.dispose();
      fakeCart.dispose();
    });

    test('CartController.addToCart returns false when unauthenticated', () async {
      final fakeCart = FakeCartRepository();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState.unauthenticated(isGuest: true)),
          ),
          cartRepositoryProvider.overrideWithValue(fakeCart),
        ],
      );

      final controller = container.read(cartControllerProvider);
      const product = ProductModel(
        productId: 'prod_tie',
        name: 'School Tie',
        description: 'Striped tie',
        categoryId: 'cat_acc',
        basePrice: 150.0,
      );

      final success = await controller.addToCart(product);
      expect(success, isFalse);

      container.dispose();
      fakeCart.dispose();
    });

    testWidgets('PDP reactive cart badge renders count dynamically', (tester) async {
      const product = ProductModel(
        productId: 'prod_bag',
        name: 'School Backpack',
        description: 'Navy backpack',
        categoryId: 'cat_bags',
        basePrice: 850.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartBadgeCountProvider.overrideWithValue(4),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(
              productId: 'prod_bag',
              initialProduct: product,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pdp_cart_badge')), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('PDP reactive cart badge is hidden when count is 0', (tester) async {
      const product = ProductModel(
        productId: 'prod_bag',
        name: 'School Backpack',
        description: 'Navy backpack',
        categoryId: 'cat_bags',
        basePrice: 850.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartBadgeCountProvider.overrideWithValue(0),
          ],
          child: const MaterialApp(
            home: ProductDetailScreen(
              productId: 'prod_bag',
              initialProduct: product,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pdp_cart_badge')), findsNothing);
    });
  });
}
