import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/data/cart_repository.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';

class MockCartRepository implements ICartRepository {
  static const int maxUnitsPerSku = 5;
  final Map<String, Map<String, CartItemModel>> _carts = {};
  final Map<String, StreamController<List<CartItemModel>>> _controllers = {};

  StreamController<List<CartItemModel>> _getController(String userId) {
    return _controllers.putIfAbsent(
      userId,
      () => StreamController<List<CartItemModel>>.broadcast(),
    );
  }

  void _notify(String userId) {
    final items = (_carts[userId]?.values.toList() ?? []);
    _getController(userId).add(List.unmodifiable(items));
  }

  @override
  Stream<List<CartItemModel>> watchCart(String userId) {
    final controller = _getController(userId);
    // Schedule initial emission
    Timer.run(() {
      final items = (_carts[userId]?.values.toList() ?? []);
      controller.add(List.unmodifiable(items));
    });
    return controller.stream;
  }

  @override
  Future<List<CartItemModel>> fetchCart(String userId) async {
    return List.unmodifiable(_carts[userId]?.values.toList() ?? []);
  }

  @override
  Future<void> addToCart(String userId, CartItemModel item) async {
    final userCart = _carts.putIfAbsent(userId, () => {});
    final allowedMax = item.maxStock > 0
        ? (item.maxStock < maxUnitsPerSku ? item.maxStock : maxUnitsPerSku)
        : maxUnitsPerSku;

    if (userCart.containsKey(item.id)) {
      final existing = userCart[item.id]!;
      final newQuantity = (existing.quantity + item.quantity).clamp(1, allowedMax);
      userCart[item.id] = existing.copyWith(quantity: newQuantity);
    } else {
      final initialQuantity = item.quantity.clamp(1, allowedMax);
      userCart[item.id] = item.copyWith(quantity: initialQuantity);
    }
    _notify(userId);
  }

  @override
  Future<void> updateQuantity(String userId, String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(userId, cartItemId);
      return;
    }

    final userCart = _carts[userId];
    if (userCart == null || !userCart.containsKey(cartItemId)) return;

    final existing = userCart[cartItemId]!;
    final allowedMax = existing.maxStock > 0
        ? (existing.maxStock < maxUnitsPerSku ? existing.maxStock : maxUnitsPerSku)
        : maxUnitsPerSku;

    final clampedQty = quantity.clamp(1, allowedMax);
    userCart[cartItemId] = existing.copyWith(quantity: clampedQty);
    _notify(userId);
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    final userCart = _carts[userId];
    if (userCart != null) {
      userCart.remove(cartItemId);
      _notify(userId);
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    final userCart = _carts[userId];
    if (userCart != null) {
      userCart.clear();
      _notify(userId);
    }
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}

void main() {
  group('CartRepository Tests', () {
    late MockCartRepository repo;
    const userId = 'test_user_aditya';

    const sampleItem1 = CartItemModel(
      productId: 'prod_trouser',
      variantId: 'v_28',
      productName: 'DPS Navy Trouser',
      schoolName: 'Delhi Public School',
      variantLabel: 'Size: 28',
      unitPrice: 800.0,
      quantity: 1,
      maxStock: 10,
    );

    const sampleItem2 = CartItemModel(
      productId: 'prod_shirt',
      variantId: 'v_32',
      productName: 'DPS White Shirt',
      schoolName: 'Delhi Public School',
      variantLabel: 'Size: 32',
      unitPrice: 450.0,
      quantity: 2,
      maxStock: 4, // lower than 5 maxUnitsPerSku
    );

    setUp(() {
      repo = MockCartRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('initial fetchCart returns empty list', () async {
      final items = await repo.fetchCart(userId);
      expect(items, isEmpty);
    });

    test('addToCart adds item with composite doc id and notifies stream in real-time', () async {
      final emitted = <List<CartItemModel>>[];
      final sub = repo.watchCart(userId).listen((items) {
        emitted.add(items);
      });

      await repo.addToCart(userId, sampleItem1);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final items = await repo.fetchCart(userId);
      expect(items, hasLength(1));
      expect(items.first.id, equals('prod_trouser_v_28'));
      expect(items.first.productName, equals('DPS Navy Trouser'));
      expect(items.first.quantity, equals(1));

      expect(emitted, isNotEmpty);
      expect(emitted.last, hasLength(1));
      expect(emitted.last.first.id, equals('prod_trouser_v_28'));

      await sub.cancel();
    });

    test('addToCart merges existing item and clamps to maxUnitsPerSku (5)', () async {
      await repo.addToCart(userId, sampleItem1); // qty 1
      await repo.addToCart(userId, sampleItem1.copyWith(quantity: 2)); // qty 1 + 2 = 3

      var items = await repo.fetchCart(userId);
      expect(items, hasLength(1));
      expect(items.first.quantity, equals(3));

      // Adding 4 more units -> 3 + 4 = 7 -> clamped to 5
      await repo.addToCart(userId, sampleItem1.copyWith(quantity: 4));
      items = await repo.fetchCart(userId);
      expect(items.first.quantity, equals(5));
    });

    test('addToCart respects maxStock if smaller than maxUnitsPerSku', () async {
      // sampleItem2 has maxStock = 4
      await repo.addToCart(userId, sampleItem2); // qty 2
      await repo.addToCart(userId, sampleItem2.copyWith(quantity: 3)); // 2 + 3 = 5 -> clamped to maxStock 4

      final items = await repo.fetchCart(userId);
      expect(items.first.quantity, equals(4));
    });

    test('updateQuantity modifies quantity within constraints', () async {
      await repo.addToCart(userId, sampleItem1); // qty 1
      await repo.updateQuantity(userId, sampleItem1.id, 4);

      var items = await repo.fetchCart(userId);
      expect(items.first.quantity, equals(4));

      // Attempt exceeding max limit
      await repo.updateQuantity(userId, sampleItem1.id, 10);
      items = await repo.fetchCart(userId);
      expect(items.first.quantity, equals(5));
    });

    test('updateQuantity with 0 or negative removes item from cart', () async {
      await repo.addToCart(userId, sampleItem1);
      await repo.addToCart(userId, sampleItem2);

      var items = await repo.fetchCart(userId);
      expect(items, hasLength(2));

      await repo.updateQuantity(userId, sampleItem1.id, 0);
      items = await repo.fetchCart(userId);
      expect(items, hasLength(1));
      expect(items.first.id, equals(sampleItem2.id));

      await repo.updateQuantity(userId, sampleItem2.id, -1);
      items = await repo.fetchCart(userId);
      expect(items, isEmpty);
    });

    test('removeFromCart deletes specified line item', () async {
      await repo.addToCart(userId, sampleItem1);
      await repo.addToCart(userId, sampleItem2);

      await repo.removeFromCart(userId, sampleItem1.id);
      final items = await repo.fetchCart(userId);
      expect(items, hasLength(1));
      expect(items.first.id, equals(sampleItem2.id));
    });

    test('clearCart removes all items for the user', () async {
      await repo.addToCart(userId, sampleItem1);
      await repo.addToCart(userId, sampleItem2);

      var items = await repo.fetchCart(userId);
      expect(items, hasLength(2));

      await repo.clearCart(userId);
      items = await repo.fetchCart(userId);
      expect(items, isEmpty);
    });

    test('cartRepositoryProvider provides ICartRepository in Riverpod container', () {
      final container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final instance = container.read(cartRepositoryProvider);
      expect(instance, isA<ICartRepository>());
      container.dispose();
    });

    test('FirestoreCartRepository constant maxUnitsPerSku equals 5', () {
      expect(FirestoreCartRepository.maxUnitsPerSku, equals(5));
    });
  });
}
