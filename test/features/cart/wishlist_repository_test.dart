import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/data/wishlist_repository.dart';
import 'package:book_vardi/features/cart/domain/wishlist_item_model.dart';

class MockWishlistRepository implements IWishlistRepository {
  final Map<String, Map<String, WishlistItemModel>> _wishlists = {};
  final Map<String, StreamController<List<WishlistItemModel>>> _controllers = {};
  final Map<String, StreamController<bool>> _itemControllers = {};

  StreamController<List<WishlistItemModel>> _getController(String userId) {
    return _controllers.putIfAbsent(
      userId,
      () => StreamController<List<WishlistItemModel>>.broadcast(),
    );
  }

  StreamController<bool> _getItemController(String userId, String productId) {
    final key = '${userId}_$productId';
    return _itemControllers.putIfAbsent(
      key,
      () => StreamController<bool>.broadcast(),
    );
  }

  void _notify(String userId, [String? productId]) {
    final items = (_wishlists[userId]?.values.toList() ?? []);
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    _getController(userId).add(List.unmodifiable(items));

    if (productId != null) {
      final exists = _wishlists[userId]?.containsKey(productId) ?? false;
      _getItemController(userId, productId).add(exists);
    }
  }

  @override
  Stream<List<WishlistItemModel>> watchWishlist(String userId) {
    final controller = _getController(userId);
    Timer.run(() {
      final items = (_wishlists[userId]?.values.toList() ?? []);
      items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      controller.add(List.unmodifiable(items));
    });
    return controller.stream;
  }

  @override
  Future<List<WishlistItemModel>> fetchWishlist(String userId) async {
    final items = (_wishlists[userId]?.values.toList() ?? []);
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return List.unmodifiable(items);
  }

  @override
  Future<bool> isInWishlist(String userId, String productId) async {
    return _wishlists[userId]?.containsKey(productId) ?? false;
  }

  @override
  Stream<bool> watchIsInWishlist(String userId, String productId) {
    final controller = _getItemController(userId, productId);
    Timer.run(() {
      final exists = _wishlists[userId]?.containsKey(productId) ?? false;
      controller.add(exists);
    });
    return controller.stream;
  }

  @override
  Future<bool> toggleWishlist(String userId, WishlistItemModel item) async {
    final userWishlist = _wishlists.putIfAbsent(userId, () => {});
    final bool willAdd = !userWishlist.containsKey(item.productId);

    if (willAdd) {
      userWishlist[item.productId] = item;
    } else {
      userWishlist.remove(item.productId);
    }

    _notify(userId, item.productId);
    return willAdd;
  }

  @override
  Future<void> addToWishlist(String userId, WishlistItemModel item) async {
    final userWishlist = _wishlists.putIfAbsent(userId, () => {});
    userWishlist[item.productId] = item;
    _notify(userId, item.productId);
  }

  @override
  Future<void> removeFromWishlist(String userId, String productId) async {
    final userWishlist = _wishlists[userId];
    if (userWishlist != null) {
      userWishlist.remove(productId);
      _notify(userId, productId);
    }
  }

  @override
  Future<void> clearWishlist(String userId) async {
    final userWishlist = _wishlists[userId];
    if (userWishlist != null) {
      final productIds = userWishlist.keys.toList();
      userWishlist.clear();
      _notify(userId);
      for (final pid in productIds) {
        _getItemController(userId, pid).add(false);
      }
    }
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    for (final controller in _itemControllers.values) {
      controller.close();
    }
  }
}

void main() {
  group('WishlistRepository Tests', () {
    late MockWishlistRepository repo;
    const userId = 'user_aditya_123';

    final sampleWishItem1 = WishlistItemModel(
      productId: 'prod_blazer_01',
      productName: 'DPS Winter Blazer',
      schoolName: 'Delhi Public School',
      imageUrl: 'https://cdn.bookvardi.com/blazer.png',
      price: 1800.0,
      mrp: 2200.0,
      inStock: true,
      addedAt: DateTime(2026, 9, 18, 10, 0),
    );

    final sampleWishItem2 = WishlistItemModel(
      productId: 'prod_shoes_02',
      productName: 'Bata School Shoes',
      schoolName: 'Delhi Public School',
      imageUrl: 'https://cdn.bookvardi.com/shoes.png',
      price: 650.0,
      mrp: 800.0,
      inStock: true,
      addedAt: DateTime(2026, 9, 18, 11, 0),
    );

    setUp(() {
      repo = MockWishlistRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('initial fetchWishlist returns empty list', () async {
      final items = await repo.fetchWishlist(userId);
      expect(items, isEmpty);
    });

    test('addToWishlist stores item and notifies watchWishlist stream', () async {
      final emitted = <List<WishlistItemModel>>[];
      final sub = repo.watchWishlist(userId).listen((items) {
        emitted.add(items);
      });

      await repo.addToWishlist(userId, sampleWishItem1);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final items = await repo.fetchWishlist(userId);
      expect(items, hasLength(1));
      expect(items.first.productId, equals('prod_blazer_01'));
      expect(items.first.productName, equals('DPS Winter Blazer'));

      expect(emitted, isNotEmpty);
      expect(emitted.last, hasLength(1));

      await sub.cancel();
    });

    test('toggleWishlist adds item when absent and returns true', () async {
      final added = await repo.toggleWishlist(userId, sampleWishItem1);
      expect(added, isTrue);

      final inList = await repo.isInWishlist(userId, sampleWishItem1.productId);
      expect(inList, isTrue);

      final items = await repo.fetchWishlist(userId);
      expect(items, hasLength(1));
    });

    test('toggleWishlist removes item when present and returns false', () async {
      await repo.addToWishlist(userId, sampleWishItem1);
      expect(await repo.isInWishlist(userId, sampleWishItem1.productId), isTrue);

      final removed = await repo.toggleWishlist(userId, sampleWishItem1);
      expect(removed, isFalse);

      final inList = await repo.isInWishlist(userId, sampleWishItem1.productId);
      expect(inList, isFalse);

      final items = await repo.fetchWishlist(userId);
      expect(items, isEmpty);
    });

    test('watchIsInWishlist emits true when added and false when removed', () async {
      final emitted = <bool>[];
      final sub = repo
          .watchIsInWishlist(userId, sampleWishItem1.productId)
          .listen((val) => emitted.add(val));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emitted.last, isFalse);

      await repo.addToWishlist(userId, sampleWishItem1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emitted.last, isTrue);

      await repo.removeFromWishlist(userId, sampleWishItem1.productId);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emitted.last, isFalse);

      await sub.cancel();
    });

    test('removeFromWishlist removes specific product', () async {
      await repo.addToWishlist(userId, sampleWishItem1);
      await repo.addToWishlist(userId, sampleWishItem2);

      var items = await repo.fetchWishlist(userId);
      expect(items, hasLength(2));

      await repo.removeFromWishlist(userId, sampleWishItem1.productId);
      items = await repo.fetchWishlist(userId);
      expect(items, hasLength(1));
      expect(items.first.productId, equals(sampleWishItem2.productId));
    });

    test('clearWishlist empties the entire wishlist', () async {
      await repo.addToWishlist(userId, sampleWishItem1);
      await repo.addToWishlist(userId, sampleWishItem2);

      await repo.clearWishlist(userId);
      final items = await repo.fetchWishlist(userId);
      expect(items, isEmpty);
    });

    test('wishlistRepositoryProvider provides IWishlistRepository instance', () {
      final container = ProviderContainer(
        overrides: [
          wishlistRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final instance = container.read(wishlistRepositoryProvider);
      expect(instance, isA<IWishlistRepository>());
      container.dispose();
    });
  });
}
