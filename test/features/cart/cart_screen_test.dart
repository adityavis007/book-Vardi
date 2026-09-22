import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/cart/data/cart_repository.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/presentation/screens/cart_screen.dart';
import 'package:book_vardi/features/cart/presentation/widgets/price_breakup_card.dart';
import 'package:book_vardi/features/cart/presentation/widgets/quantity_stepper.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = UserModel(
    userId: 'user_123',
    name: 'Student User',
    email: 'student@example.com',
  );

  final item1 = CartItemModel(
    productId: 'prod_1',
    variantId: 'var_class6',
    productName: 'Oxford Mathematics Class 6',
    schoolName: 'Delhi Public School',
    variantLabel: 'Class 6',
    unitPrice: 450.0,
    quantity: 2,
    maxStock: 10,
  );

  final item2 = CartItemModel(
    productId: 'prod_2',
    variantId: 'var_size32',
    productName: 'School Navy Blazer',
    schoolName: 'Delhi Public School',
    variantLabel: 'Size 32',
    unitPrice: 1200.0,
    quantity: 1,
    maxStock: 5,
  );

  Widget buildTestableScreen({
    required FakeCartRepository cartRepo,
    VoidCallback? onCheckout,
    VoidCallback? onStartShopping,
  }) {
    return ProviderScope(
      overrides: [
        cartRepositoryProvider.overrideWithValue(cartRepo),
        authControllerProvider.overrideWith(
          (ref) => FakeAuthController(const AuthState.authenticated(testUser)),
        ),
      ],
      child: MaterialApp(
        home: CartScreen(
          onCheckout: onCheckout,
          onStartShopping: onStartShopping,
        ),
      ),
    );
  }

  group('CartScreen Full Layout & Integration Tests', () {
    testWidgets('renders empty cart state with title and start shopping button',
        (WidgetTester tester) async {
      final repo = FakeCartRepository([]);
      bool startShoppingTapped = false;

      await tester.pumpWidget(
        buildTestableScreen(
          cartRepo: repo,
          onStartShopping: () => startShoppingTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      // Header title
      expect(find.text('Your Cart Items'), findsOneWidget);

      // Empty Cart elements
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('cart_empty_start_shopping_button')), findsOneWidget);

      // Sticky Bottom Bar should NOT be visible when empty
      expect(find.byKey(const Key('cart_sticky_bottom_bar')), findsNothing);

      // Tap Start Shopping
      await tester.tap(find.byKey(const Key('cart_empty_start_shopping_button')));
      await tester.pumpAndSettle();
      expect(startShoppingTapped, isTrue);

      repo.dispose();
    });

    testWidgets('renders cart items list, free shipping banner, and summary footer',
        (WidgetTester tester) async {
      final repo = FakeCartRepository([item1, item2]);

      await tester.pumpWidget(buildTestableScreen(cartRepo: repo));
      await tester.pumpAndSettle();

      // Verify Header title & Free Shipping Banner
      expect(find.text('Your Cart Items'), findsOneWidget);
      expect(find.text('You\'ve unlocked FREE Shipping!'), findsOneWidget);

      // Verify Item 1 & Item 2
      expect(find.text('Oxford Mathematics Class 6'), findsOneWidget);
      expect(find.text('School Navy Blazer'), findsOneWidget);

      // Verify QuantitySteppers
      expect(find.byType(QuantityStepper), findsNWidgets(2));

      // Verify Sticky Bottom Bar & Checkout Button
      expect(find.byKey(const Key('cart_sticky_bottom_bar')), findsOneWidget);
      expect(find.byKey(const Key('cart_proceed_to_checkout_button')), findsOneWidget);

      // Subtotal = (450 * 2) + (1200 * 1) = 2100 (Free shipping since > 999)
      expect(find.byKey(const Key('cart_bottom_bar_total')), findsOneWidget);
      expect(find.text('₹2,100'), findsAtLeastNWidgets(1));

      repo.dispose();
    });

    testWidgets('recalculates price and updates quantity when stepper increment is tapped',
        (WidgetTester tester) async {
      final repo = FakeCartRepository([item1]); // 450 * 2 = 900

      await tester.pumpWidget(buildTestableScreen(cartRepo: repo));
      await tester.pumpAndSettle();

      // Initial subtotal: 900 + 50 (shipping since <= 999) = 950
      expect(find.text('₹900'), findsAtLeastNWidgets(1));
      expect(find.text('₹950'), findsOneWidget);

      // Tap increment on QuantityStepper
      await tester.tap(find.byKey(const Key('quantity_stepper_increment')));
      await tester.pumpAndSettle();

      // New quantity: 3. Subtotal: 450 * 3 = 1350 (qualifies for free shipping > 999!)
      // Grand total becomes 1350
      expect(find.text('₹1,350'), findsAtLeastNWidgets(1));
      expect(find.text('FREE'), findsOneWidget);

      repo.dispose();
    });

    testWidgets('deleting cart item opens dialog and removes item upon confirmation',
        (WidgetTester tester) async {
      final repo = FakeCartRepository([item1]);

      await tester.pumpWidget(buildTestableScreen(cartRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Oxford Mathematics Class 6'), findsOneWidget);

      // Tap delete icon button
      await tester.tap(find.byKey(Key('cart_item_delete_${item1.id}')));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Remove item from cart?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('quantity_stepper_dialog_confirm')));
      await tester.pumpAndSettle();

      // Empty state rendered
      expect(find.text('Your cart is empty'), findsOneWidget);

      repo.dispose();
    });

    testWidgets('tapping PROCEED TO CHECKOUT invokes onCheckout callback',
        (WidgetTester tester) async {
      final repo = FakeCartRepository([item1]);
      bool checkoutTapped = false;

      await tester.pumpWidget(
        buildTestableScreen(
          cartRepo: repo,
          onCheckout: () => checkoutTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cart_proceed_to_checkout_button')));
      await tester.pumpAndSettle();

      expect(checkoutTapped, isTrue);

      repo.dispose();
    });

    testWidgets('clear cart action in AppBar empties the cart upon confirmation',
        (WidgetTester tester) async {
      final repo = FakeCartRepository([item1, item2]);

      await tester.pumpWidget(buildTestableScreen(cartRepo: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cart_clear_button')), findsOneWidget);

      // Tap Clear
      await tester.tap(find.byKey(const Key('cart_clear_button')));
      await tester.pumpAndSettle();

      expect(find.text('Clear Shopping Cart?'), findsOneWidget);

      // Tap Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Transitions to empty state
      expect(find.text('Your cart is empty'), findsOneWidget);

      repo.dispose();
    });
  });
}
