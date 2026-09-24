import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/theme/app_theme.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/auth/presentation/widgets/auth_modal_sheet.dart';
import 'package:book_vardi/features/cart/data/cart_repository.dart';
import 'package:book_vardi/features/cart/data/wishlist_repository.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/wishlist_item_model.dart';
import 'package:book_vardi/features/catalog/data/catalog_repository.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/school_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';
import 'package:book_vardi/features/catalog/presentation/screens/all_products_screen.dart';

class _FakeAuthRepo implements IAuthRepository {
  @override
  Stream<UserModel?> watchAuthState() => const Stream.empty();
  @override
  Future<UserModel?> getCurrentUser() async => null;
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) =>
      throw UnimplementedError();
  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<UserModel> updateProfile(UserModel user) async => user;
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(AuthState initialState)
      : super(authRepository: _FakeAuthRepo()) {
    state = initialState;
  }
}

class _MockCatalogRepo implements ICatalogRepository {
  final List<ProductModel> products;

  _MockCatalogRepo(this.products);

  @override
  Future<List<CategoryModel>> fetchCategories() async => [];

  @override
  Stream<List<CategoryModel>> watchCategories() => Stream.value([]);

  @override
  Future<List<ProductModel>> fetchProducts({
    String? categoryId,
    String? school,
    String? schoolId,
    String? grade,
    String? searchQuery,
    SortOption? sort,
    bool? featuredOnly,
    int? limit,
  }) async {
    return products.where((p) {
      if (categoryId != null && categoryId.isNotEmpty && p.categoryId != categoryId) {
        return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final match = p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  Stream<List<ProductModel>> watchProducts({
    String? categoryId,
    String? school,
    String? schoolId,
    String? grade,
    String? searchQuery,
    SortOption? sort,
    bool? featuredOnly,
    int? limit,
  }) {
    return Stream.value(products);
  }

  @override
  Future<ProductModel?> fetchProductById(String id) async {
    return products.where((p) => p.productId == id).firstOrNull;
  }

  @override
  Stream<ProductModel?> watchProductById(String id) {
    return Stream.value(products.where((p) => p.productId == id).firstOrNull);
  }

  @override
  Future<List<SchoolModel>> fetchSchools() async => [];

  @override
  Stream<List<SchoolModel>> watchSchools() => Stream.value([]);
}

class _MockWishlistRepo implements IWishlistRepository {
  final List<WishlistItemModel> items = [];

  @override
  Stream<List<WishlistItemModel>> watchWishlist(String userId) =>
      Stream.value(items);

  @override
  Future<List<WishlistItemModel>> fetchWishlist(String userId) async => items;

  @override
  Future<void> addToWishlist(String userId, WishlistItemModel item) async {
    items.add(item);
  }

  @override
  Future<void> removeFromWishlist(String userId, String productId) async {
    items.removeWhere((i) => i.productId == productId);
  }

  @override
  Future<bool> toggleWishlist(String userId, WishlistItemModel item) async {
    final idx = items.indexWhere((i) => i.productId == item.productId);
    if (idx >= 0) {
      items.removeAt(idx);
      return false;
    } else {
      items.add(item);
      return true;
    }
  }

  @override
  Future<bool> isInWishlist(String userId, String productId) async {
    return items.any((i) => i.productId == productId);
  }

  @override
  Stream<bool> watchIsInWishlist(String userId, String productId) {
    return Stream.value(items.any((i) => i.productId == productId));
  }

  @override
  Future<void> clearWishlist(String userId) async {
    items.clear();
  }
}

class _MockCartRepo implements ICartRepository {
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
  Future<void> updateQuantity(String userId, String cartItemId, int qty) async {}

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    items.removeWhere((i) => i.id == cartItemId);
  }

  @override
  Future<void> clearCart(String userId) async {
    items.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyProducts = [
    const ProductModel(
      productId: 'prod_1',
      name: 'Out of Stock Product',
      description: 'Premium quality school uniform & educational product.',
      categoryId: 'uniforms',
      basePrice: 499.0,
      inStock: false,
      rating: 0.0,
      variants: [
        VariantModel(variantId: 'v_s', sku: 'SKU-S', label: 'S', price: 499.0),
        VariantModel(variantId: 'v_m', sku: 'SKU-M', label: 'M', price: 499.0),
        VariantModel(variantId: 'v_l', sku: 'SKU-L', label: 'L', price: 499.0),
        VariantModel(variantId: 'v_xl', sku: 'SKU-XL', label: 'XL', price: 499.0),
      ],
    ),
    const ProductModel(
      productId: 'prod_2',
      name: 'Test Uniform Tie',
      description: 'Premium quality school uniform & educational product.',
      categoryId: 'uniforms',
      basePrice: 199.0,
      inStock: true,
      rating: 4.5,
      variants: [
        VariantModel(variantId: 'v_s', sku: 'SKU-S', label: 'S', price: 199.0),
        VariantModel(variantId: 'v_m', sku: 'SKU-M', label: 'M', price: 199.0),
      ],
    ),
  ];

  Widget buildScreen({
    AuthState authState = const AuthState.unauthenticated(isGuest: true),
    List<ProductModel>? products,
  }) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => _FakeAuthController(authState)),
        catalogRepositoryProvider
            .overrideWithValue(_MockCatalogRepo(products ?? dummyProducts)),
        wishlistRepositoryProvider.overrideWithValue(_MockWishlistRepo()),
        cartRepositoryProvider.overrideWithValue(_MockCartRepo()),
      ],
      child: MaterialApp(
        theme: BookVardiTheme.lightTheme,
        home: const AllProductsScreen(),
      ),
    );
  }

  group('AllProductsScreen 1:1 Website Presentation Tests', () {
    testWidgets('renders dark green header banner with clean mobile title and counter pill',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // No web breadcrumbs
      expect(find.text('Home'), findsNothing);

      // Warm Amber badge
      expect(find.text('FULL STATIONERY CATALOG'), findsOneWidget);

      // Mobile Heading
      expect(find.text('All Products'), findsOneWidget);

      // Subtitle
      expect(
        find.text(
          'Browse our complete collection of premium uniforms, books & stationery.',
        ),
        findsOneWidget,
      );

      // Item counter capsule pill
      expect(find.textContaining('Showing 2 of 2 items'), findsOneWidget);
    });

    testWidgets('renders search box with new placeholder and filters button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('Search books, uniforms, stationery...'),
        findsOneWidget,
      );
      expect(find.text('Filters'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    testWidgets('renders horizontal quick category circular rail',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('All Items'), findsOneWidget);
      expect(find.text('Liked (0)'), findsOneWidget);
      expect(find.text('SCHOOL UNIFORMS'), findsOneWidget);
      expect(find.text('NCERT BOOKS'), findsOneWidget);
      expect(find.text('PRACTICE BOOKS'), findsOneWidget);
      expect(find.text('DRAWING FOR KIDS'), findsOneWidget);
      expect(find.text('STATIONERY'), findsOneWidget);
      expect(find.text('KITS & BUNDLES'), findsOneWidget);
    });

    testWidgets('renders product cards with 1:1 components and no overflow on compact mobile (360x640)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // No overflow errors should be thrown
      expect(tester.takeException(), isNull);

      // Product titles
      expect(find.text('Out of Stock Product'), findsOneWidget);
      expect(find.text('Test Uniform Tie'), findsOneWidget);

      // Prices
      expect(find.text('₹499'), findsOneWidget);
      expect(find.text('₹199'), findsOneWidget);

      // Variant chips
      expect(find.text('S'), findsWidgets);
      expect(find.text('M'), findsWidgets);

      // Add to Cart buttons
      expect(find.text('Out of Stock'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
    });

    testWidgets('prompts AuthModalBottomSheet when guest taps Add to Cart',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildScreen(authState: const AuthState.unauthenticated(isGuest: true)),
      );
      await tester.pumpAndSettle();

      // Tap on the available "Add to Cart" button
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // AuthModalBottomSheet should be presented
      expect(find.byType(AuthModalBottomSheet), findsOneWidget);
      expect(find.text('Welcome to Book Vardi'), findsOneWidget);
    });

    testWidgets('renders End of Catalog card with Back to Top smooth scroll',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('🎉'), findsOneWidget);
      expect(
        find.text("You've Reached The End of the Catalog!"),
        findsOneWidget,
      );
      expect(find.text('Back to Top'), findsOneWidget);

      // Tap Back to Top
      await tester.tap(find.text('Back to Top'));
      await tester.pumpAndSettle();

      // Verified at top
      expect(find.text('All Products'), findsOneWidget);
    });
  });
}
