import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/cart/data/cart_repository.dart';
import 'package:book_vardi/features/cart/data/wishlist_repository.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/wishlist_item_model.dart';
import 'package:book_vardi/features/cart/presentation/screens/wishlist_screen.dart';

class FakeAuthController extends StateNotifier<AuthState>
    implements AuthController {
  FakeAuthController(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCartRepository implements ICartRepository {
  final List<CartItemModel> items = [];

  @override
  Stream<List<CartItemModel>> watchCart(String userId) => Stream.value(items);

  @override
  Future<List<CartItemModel>> fetchCart(String userId) async => items;

  @override
  Future<void> addToCart(String userId, CartItemModel item) async {
    items.add(item);
  }

  @override
  Future<void> updateQuantity(String userId, String cartItemId, int quantity) async {}

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {}

  @override
  Future<void> clearCart(String userId) async {
    items.clear();
  }
}

class FakeWishlistRepository implements IWishlistRepository {
  final List<WishlistItemModel> _items = [];
  final StreamController<List<WishlistItemModel>> _controller =
      StreamController<List<WishlistItemModel>>.broadcast();

  FakeWishlistRepository([List<WishlistItemModel>? initialItems]) {
    if (initialItems != null) {
      _items.addAll(initialItems);
    }
  }

  void _notify() {
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Stream<List<WishlistItemModel>> watchWishlist(String userId) async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }

  @override
  Future<List<WishlistItemModel>> fetchWishlist(String userId) async {
    return List.unmodifiable(_items);
  }

  @override
  Future<bool> isInWishlist(String userId, String productId) async {
    return _items.any((i) => i.productId == productId);
  }

  @override
  Stream<bool> watchIsInWishlist(String userId, String productId) {
    return _controller.stream.map((list) => list.any((i) => i.productId == productId));
  }

  @override
  Future<bool> toggleWishlist(String userId, WishlistItemModel item) async {
    final index = _items.indexWhere((i) => i.productId == item.productId);
    if (index != -1) {
      _items.removeAt(index);
      _notify();
      return false;
    } else {
      _items.add(item);
      _notify();
      return true;
    }
  }

  @override
  Future<void> addToWishlist(String userId, WishlistItemModel item) async {
    _items.add(item);
    _notify();
  }

  @override
  Future<void> removeFromWishlist(String userId, String productId) async {
    _items.removeWhere((i) => i.productId == productId);
    _notify();
  }

  @override
  Future<void> clearWishlist(String userId) async {
    _items.clear();
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = UserModel(
    userId: 'user_456',
    name: 'Ananya Sharma',
    email: 'ananya@example.com',
  );

  final wishItem1 = WishlistItemModel(
    productId: 'prod_math_6',
    productName: 'Mathematics Class 6 NCERT',
    schoolName: 'Delhi Public School',
    price: 320.0,
    mrp: 400.0, // 20% OFF
    inStock: true,
    addedAt: DateTime(2026, 1, 10),
  );

  final wishItem2 = WishlistItemModel(
    productId: 'prod_blazer_34',
    productName: 'Navy Winter School Blazer',
    schoolName: 'Delhi Public School',
    price: 1450.0,
    mrp: null,
    inStock: false, // Out of stock
    addedAt: DateTime(2026, 1, 12),
  );

  Widget buildTestableWidget({
    required AuthState authState,
    required FakeWishlistRepository wishlistRepo,
    required FakeCartRepository cartRepo,
    VoidCallback? onGuestIntercept,
    VoidCallback? onExplore,
  }) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => FakeAuthController(authState)),
        wishlistRepositoryProvider.overrideWithValue(wishlistRepo),
        cartRepositoryProvider.overrideWithValue(cartRepo),
      ],
      child: MaterialApp(
        home: WishlistScreen(
          onGuestIntercept: onGuestIntercept,
          onExplore: onExplore,
        ),
      ),
    );
  }

  group('WishlistScreen Integration & Guest Guard Tests', () {
    testWidgets('unauthenticated guest is intercepted on navigation and shown guest prompt',
        (WidgetTester tester) async {
      final wishlistRepo = FakeWishlistRepository([]);
      final cartRepo = FakeCartRepository();
      bool guestInterceptTriggered = false;

      await tester.pumpWidget(
        buildTestableWidget(
          authState: const AuthState.unauthenticated(isGuest: true),
          wishlistRepo: wishlistRepo,
          cartRepo: cartRepo,
          onGuestIntercept: () => guestInterceptTriggered = true,
        ),
      );
      await tester.pumpAndSettle();

      // Intercept automatically fires
      expect(guestInterceptTriggered, isTrue);

      // Guest UI placeholder rendered
      expect(find.text('Sign In to View Wishlist'), findsOneWidget);
      expect(find.byKey(const Key('wishlist_guest_signin_button')), findsOneWidget);

      // Tap Sign In button triggers intercept again
      guestInterceptTriggered = false;
      await tester.tap(find.byKey(const Key('wishlist_guest_signin_button')));
      await tester.pumpAndSettle();

      expect(guestInterceptTriggered, isTrue);

      wishlistRepo.dispose();
    });

    testWidgets('authenticated user with empty wishlist views empty state and explore action',
        (WidgetTester tester) async {
      final wishlistRepo = FakeWishlistRepository([]);
      final cartRepo = FakeCartRepository();
      bool exploreTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          authState: const AuthState.authenticated(testUser),
          wishlistRepo: wishlistRepo,
          cartRepo: cartRepo,
          onExplore: () => exploreTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Wishlist'), findsOneWidget);
      expect(find.text('Your Wishlist is Empty'), findsOneWidget);
      expect(find.byKey(const Key('wishlist_empty_explore_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('wishlist_empty_explore_button')));
      await tester.pumpAndSettle();

      expect(exploreTapped, isTrue);

      wishlistRepo.dispose();
    });

    testWidgets('authenticated user views populated 2-column grid with discount and stock badges',
        (WidgetTester tester) async {
      final wishlistRepo = FakeWishlistRepository([wishItem1, wishItem2]);
      final cartRepo = FakeCartRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          authState: const AuthState.authenticated(testUser),
          wishlistRepo: wishlistRepo,
          cartRepo: cartRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Header shows count (2)
      expect(find.text('My Wishlist (2)'), findsOneWidget);

      // Item 1
      expect(find.text('Mathematics Class 6 NCERT'), findsOneWidget);
      expect(find.text('20% OFF'), findsOneWidget);
      expect(find.text('In Stock'), findsOneWidget);
      expect(find.byKey(Key('wishlist_move_to_cart_${wishItem1.productId}')), findsOneWidget);

      // Item 2
      expect(find.text('Navy Winter School Blazer'), findsOneWidget);
      expect(find.text('Out of Stock'), findsOneWidget);
      expect(find.byKey(Key('wishlist_move_to_cart_${wishItem2.productId}')), findsOneWidget);

      wishlistRepo.dispose();
    });

    testWidgets('tapping MOVE TO CART transfers item to cart and removes from wishlist',
        (WidgetTester tester) async {
      final wishlistRepo = FakeWishlistRepository([wishItem1]);
      final cartRepo = FakeCartRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          authState: const AuthState.authenticated(testUser),
          wishlistRepo: wishlistRepo,
          cartRepo: cartRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mathematics Class 6 NCERT'), findsOneWidget);
      expect(cartRepo.items, isEmpty);

      // Scroll to button and tap Move to Cart
      final moveBtn = find.byKey(Key('wishlist_move_to_cart_${wishItem1.productId}'));
      await tester.ensureVisible(moveBtn);
      await tester.pumpAndSettle();
      await tester.tap(moveBtn);
      await tester.pumpAndSettle();

      // Transferred to cart
      expect(cartRepo.items.length, equals(1));
      expect(cartRepo.items.first.productId, equals(wishItem1.productId));

      // Removed from wishlist -> transitions to empty state
      expect(find.text('Your Wishlist is Empty'), findsOneWidget);

      wishlistRepo.dispose();
    });

    testWidgets('tapping remove heart button removes item from wishlist',
        (WidgetTester tester) async {
      final wishlistRepo = FakeWishlistRepository([wishItem1]);
      final cartRepo = FakeCartRepository();

      await tester.pumpWidget(
        buildTestableWidget(
          authState: const AuthState.authenticated(testUser),
          wishlistRepo: wishlistRepo,
          cartRepo: cartRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mathematics Class 6 NCERT'), findsOneWidget);

      // Tap Remove Heart icon
      await tester.tap(find.byKey(Key('wishlist_remove_${wishItem1.productId}')));
      await tester.pumpAndSettle();

      // Empty state
      expect(find.text('Your Wishlist is Empty'), findsOneWidget);

      wishlistRepo.dispose();
    });
  });
}
