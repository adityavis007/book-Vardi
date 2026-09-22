import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/widgets/auth_modal_sheet.dart';
import 'package:book_vardi/features/catalog/data/catalog_repository.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/school_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';
import 'package:book_vardi/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:book_vardi/shared/widgets/custom_button.dart';

class MockCatalogRepoForPDP implements ICatalogRepository {
  final Map<String, ProductModel?> products;
  bool shouldThrow;

  MockCatalogRepoForPDP({
    Map<String, ProductModel?>? products,
    this.shouldThrow = false,
  }) : products = products ?? {};

  @override
  Future<ProductModel?> fetchProductById(String id) async {
    if (shouldThrow) {
      throw Exception('Network connection failed');
    }
    return products[id];
  }

  @override
  Stream<ProductModel?> watchProductById(String id) {
    if (shouldThrow) {
      return Stream.error(Exception('Network connection failed'));
    }
    return Stream.value(products[id]);
  }

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
  }) async =>
      [];

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
  }) =>
      Stream.value([]);

  @override
  Future<List<SchoolModel>> fetchSchools() async => [];

  @override
  Stream<List<SchoolModel>> watchSchools() => Stream.value([]);
}

class MockAuthRepoForPDP implements IAuthRepository {
  final UserModel? initialUser;

  MockAuthRepoForPDP({this.initialUser});

  @override
  Stream<UserModel?> watchAuthState() => Stream.value(initialUser);

  @override
  Future<UserModel?> getCurrentUser() async => initialUser;

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    codeSent('mock_pdp_vid', 123456);
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async =>
      UserModel(
        userId: 'auth_parent_1',
        phone: '+919876543210',
        name: name ?? 'Parent User',
        role: UserRole.customer,
      );

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel> updateProfile(UserModel user) async => user;
}

void main() {
  const multiImageProduct = ProductModel(
    productId: 'prod_multi',
    name: 'DPS Boys Premium Uniform Set',
    description:
        'Complete uniform kit including high quality shirt, trousers, and customized school tie.',
    categoryId: 'cat_uniforms',
    schoolName: 'Delhi Public School',
    targetGrade: 'Class 5',
    basePrice: 1200.0,
    discountPrice: 960.0,
    inStock: true,
    isFeatured: true,
    rating: 4.6,
    reviewCount: 38,
    images: [
      'https://example.com/img1.jpg',
      'https://example.com/img2.jpg',
      'https://example.com/img3.jpg',
    ],
  );

  const singleImageProduct = ProductModel(
    productId: 'prod_single',
    name: 'Standard Notebook Pack',
    description: 'Pack of 6 single lined 180 page notebooks.',
    categoryId: 'cat_stationery',
    basePrice: 300.0,
    discountPrice: null,
    inStock: false,
    rating: 4.0,
    reviewCount: 0,
    images: ['https://example.com/book.jpg'],
  );

  Widget createSubject({
    required String productId,
    ProductModel? initialProduct,
    VariantModel? initialVariant,
    VoidCallback? onBackTap,
    VoidCallback? onSearchTap,
    VoidCallback? onCartTap,
    void Function(ProductModel, VariantModel?)? onAddToCart,
    void Function(ProductModel, VariantModel?)? onBuyNow,
    ICatalogRepository? repo,
    IAuthRepository? authRepo,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        if (repo != null) catalogRepositoryProvider.overrideWithValue(repo),
        if (authRepo != null)
          authRepositoryProvider.overrideWithValue(authRepo),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        home: ProductDetailScreen(
          productId: productId,
          initialProduct: initialProduct,
          initialVariant: initialVariant,
          onBackTap: onBackTap,
          onSearchTap: onSearchTap,
          onCartTap: onCartTap,
          onAddToCart: onAddToCart,
          onBuyNow: onBuyNow,
        ),
      ),
    );
  }

  group('ProductDetailScreen Layout & Content Tests', () {
    testWidgets('renders all product header elements accurately',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          initialProduct: multiImageProduct,
        ),
      );
      await tester.pumpAndSettle();

      // Product Title
      expect(find.text('DPS Boys Premium Uniform Set'), findsWidgets);

      // School Identity Tag Badge
      expect(find.text('Delhi Public School'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsWidgets);

      // Rating & Reviews
      expect(find.text('4.6'), findsOneWidget);
      expect(find.text('(38)'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      // Stock status
      expect(find.text('In Stock'), findsOneWidget);

      // Price Row: Effective price (960), MRP (1200), and 20% OFF pill
      expect(find.text('₹960'), findsNWidgets(2)); // in price row & sticky bar
      expect(find.text('₹1,200'), findsOneWidget);
      expect(find.text('20% OFF'), findsOneWidget);
      expect(find.text('(Inclusive of all taxes)'), findsOneWidget);

      // Description section
      expect(find.text('About Product'), findsOneWidget);
      expect(
        find.text(
            'Complete uniform kit including high quality shirt, trousers, and customized school tie.'),
        findsOneWidget,
      );
    });

    testWidgets('omits school badge when schoolName is empty or null',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          productId: 'prod_single',
          initialProduct: singleImageProduct,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Standard Notebook Pack'), findsWidgets);
      // No school badge row
      expect(find.text('Delhi Public School'), findsNothing);
      expect(find.text('Out of Stock'), findsOneWidget);

      // No discount pill or MRP strikethrough
      expect(find.text('₹300'), findsNWidgets(2)); // in price row & sticky bar
      expect(find.textContaining('OFF'), findsNothing);
    });

    testWidgets('renders fallback description when empty', (tester) async {
      const productWithoutDesc = ProductModel(
        productId: 'prod_nodesc',
        name: 'Empty Desc Product',
        description: '',
        categoryId: 'cat_other',
        basePrice: 100.0,
      );

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_nodesc',
          initialProduct: productWithoutDesc,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No detailed description available.'),
        findsOneWidget,
      );
    });
  });

  group('Top App Bar Actions', () {
    testWidgets('triggers onBackTap, onSearchTap, and onCartTap callbacks',
        (tester) async {
      var backTapped = false;
      var searchTapped = false;
      var cartTapped = false;

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          initialProduct: multiImageProduct,
          onBackTap: () => backTapped = true,
          onSearchTap: () => searchTapped = true,
          onCartTap: () => cartTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pdp_back_button')));
      expect(backTapped, isTrue);

      await tester.tap(find.byKey(const Key('pdp_search_button')));
      expect(searchTapped, isTrue);

      await tester.tap(find.byKey(const Key('pdp_cart_button')));
      expect(cartTapped, isTrue);
    });
  });

  group('1:1 Gallery Carousel & Thumbnail Strip Interaction', () {
    testWidgets('renders 1:1 carousel and updates active index on swipe',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          initialProduct: multiImageProduct,
        ),
      );
      await tester.pumpAndSettle();

      // Check initial active counter pill
      expect(find.text('1 / 3'), findsOneWidget);

      // Fling carousel left to show image 2
      await tester.fling(
        find.byKey(const Key('pdp_image_carousel')),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Counter pill updates to 2 / 3
      expect(find.text('2 / 3'), findsOneWidget);

      // Fling left again to show image 3
      await tester.fling(
        find.byKey(const Key('pdp_image_carousel')),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('thumbnail strip tapping navigates carousel', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          initialProduct: multiImageProduct,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pdp_thumbnail_strip')), findsOneWidget);
      expect(find.byKey(const Key('pdp_thumbnail_0')), findsOneWidget);
      expect(find.byKey(const Key('pdp_thumbnail_1')), findsOneWidget);
      expect(find.byKey(const Key('pdp_thumbnail_2')), findsOneWidget);

      expect(find.text('1 / 3'), findsOneWidget);

      // Tap thumbnail 2
      await tester.tap(find.byKey(const Key('pdp_thumbnail_2')));
      await tester.pumpAndSettle();

      // Carousel index is now 3 / 3
      expect(find.text('3 / 3'), findsOneWidget);

      // Tap thumbnail 0
      await tester.tap(find.byKey(const Key('pdp_thumbnail_0')));
      await tester.pumpAndSettle();

      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('single image product does not show thumbnail strip or pill',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          productId: 'prod_single',
          initialProduct: singleImageProduct,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pdp_thumbnail_strip')), findsNothing);
      expect(find.text('1 / 1'), findsNothing);
    });
  });

  group('Provider Loading, Error & Not Found States', () {
    testWidgets('loads product via productDetailProvider and displays content',
        (tester) async {
      final mockRepo = MockCatalogRepoForPDP(
        products: {'prod_multi': multiImageProduct},
      );

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          repo: mockRepo,
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete async fetch
      await tester.pumpAndSettle();

      expect(find.text('DPS Boys Premium Uniform Set'), findsWidgets);
      expect(find.text('Delhi Public School'), findsOneWidget);
    });

    testWidgets('displays not found scaffold when product does not exist',
        (tester) async {
      final mockRepo = MockCatalogRepoForPDP(
        products: {},
      );

      await tester.pumpWidget(
        createSubject(
          productId: 'unknown_id',
          repo: mockRepo,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Product not found'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('displays error scaffold on repository exception and retries',
        (tester) async {
      final mockRepo = MockCatalogRepoForPDP(
        products: {'prod_multi': multiImageProduct},
        shouldThrow: true,
      );

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          repo: mockRepo,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load product'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Fix repository error and tap Retry
      mockRepo.shouldThrow = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('DPS Boys Premium Uniform Set'), findsWidgets);
    });
  });

  group('PDP Variant Matrix Integration Tests', () {
    const productWithVariants = ProductModel(
      productId: 'prod_variants',
      name: 'DPS Boys Uniform Trousers',
      description: 'Navy blue school trousers with pleated front.',
      categoryId: 'cat_uniforms',
      schoolName: 'Delhi Public School',
      basePrice: 1000.0,
      discountPrice: 800.0,
      images: ['https://example.com/trouser.jpg'],
      variants: [
        VariantModel(
          variantId: 'v_28',
          sku: 'TROUSER-28',
          label: '28',
          price: 800.0,
          stock: 10,
        ),
        VariantModel(
          variantId: 'v_30',
          sku: 'TROUSER-30',
          label: '30',
          price: 850.0,
          stock: 5,
        ),
        VariantModel(
          variantId: 'v_32',
          sku: 'TROUSER-32',
          label: '32',
          price: 900.0,
          stock: 0,
        ),
      ],
    );

    testWidgets(
        'renders VariantSelector and updates price when size pill is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_variants',
          initialProduct: productWithVariants,
        ),
      );
      await tester.pumpAndSettle();

      // Initial variant is v_28 (price: 800)
      expect(find.text('Select Size'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
      expect(find.text('₹800'), findsNWidgets(2)); // in price row & sticky bar

      // Scroll to and tap variant 30 (price: 850)
      await tester.ensureVisible(find.byKey(const Key('variant_pill_v_30')));
      await tester.tap(find.byKey(const Key('variant_pill_v_30')));
      await tester.pumpAndSettle();

      // Displayed price updates dynamically to ₹850
      expect(find.text('₹850'), findsNWidgets(2)); // in price row & sticky bar
      expect(find.text('SKU: TROUSER-30'), findsOneWidget);
      expect(find.text('Only 5 left in stock!'), findsOneWidget);

      // Scroll to and tap out of stock variant 32 (stock: 0) -> should not select
      await tester.ensureVisible(find.byKey(const Key('variant_pill_v_32')));
      await tester.tap(find.byKey(const Key('variant_pill_v_32')));
      await tester.pumpAndSettle();

      // Still ₹850, not updated to ₹900
      expect(find.text('₹850'), findsNWidgets(2)); // in price row & sticky bar
      expect(find.text('SKU: TROUSER-30'), findsOneWidget);
    });
  });

  group('PDP Specifications & Sticky Purchase Bar Tests', () {
    const customSpecsProduct = ProductModel(
      productId: 'prod_custom_specs',
      name: 'Custom Blazer',
      description: 'Formal school winter blazer.',
      categoryId: 'cat_uniforms',
      basePrice: 1500.0,
      inStock: true,
      specifications: {
        'Fabric GSM': '280 GSM',
        'Lining': '100% Satin',
        'Button Type': 'Brass Embossed',
      },
    );

    const testParent = UserModel(
      userId: 'user_parent_123',
      email: 'parent@bookvardi.com',
      name: 'Aditya Parent',
      role: UserRole.customer,
    );

    testWidgets(
        'renders specifications table with standard and custom attributes',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          productId: 'prod_custom_specs',
          initialProduct: customSpecsProduct,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pdp_specifications_section')),
          findsOneWidget);
      expect(find.text('Product Specifications'), findsOneWidget);

      // Custom attributes
      expect(find.text('Fabric GSM'), findsOneWidget);
      expect(find.text('280 GSM'), findsOneWidget);
      expect(find.text('Lining'), findsOneWidget);
      expect(find.text('100% Satin'), findsOneWidget);
      expect(find.text('Button Type'), findsOneWidget);
      expect(find.text('Brass Embossed'), findsOneWidget);

      // Standard fallback attributes
      expect(find.text('Material'), findsOneWidget);
      expect(find.text('School Board'), findsOneWidget);
      expect(find.text('Fit Type'), findsOneWidget);
      expect(find.text('Return Policy'), findsOneWidget);
      expect(find.text('7-day exchange for sizing issues'), findsOneWidget);
    });

    testWidgets(
        'renders sticky bottom purchase bar with live price, Add to Cart and Buy Now',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          initialProduct: multiImageProduct,
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('pdp_sticky_purchase_bar')), findsOneWidget);
      expect(find.byKey(const Key('pdp_add_to_cart_button')), findsOneWidget);
      expect(find.byKey(const Key('pdp_buy_now_button')), findsOneWidget);

      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);
      expect(find.text('(Inclusive tax)'), findsOneWidget);
    });

    testWidgets('sticky purchase bar buttons disabled when product out of stock',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          productId: 'prod_single',
          initialProduct: singleImageProduct, // inStock: false
        ),
      );
      await tester.pumpAndSettle();

      final addToCartBtn = tester.widget<CustomButton>(
        find.byKey(const Key('pdp_add_to_cart_button')),
      );
      expect(addToCartBtn.onPressed, isNull);

      final buyNowBtn = tester.widget<CustomButton>(
        find.byKey(const Key('pdp_buy_now_button')),
      );
      expect(buyNowBtn.onPressed, isNull);
    });

    testWidgets(
        'unauthenticated guest: tapping Add to Cart triggers AuthModalBottomSheet',
        (tester) async {
      final mockAuth = MockAuthRepoForPDP(initialUser: null);

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          initialProduct: multiImageProduct,
          authRepo: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pdp_add_to_cart_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AuthModalBottomSheet), findsOneWidget);
    });

    testWidgets(
        'unauthenticated guest: tapping Buy Now triggers AuthModalBottomSheet',
        (tester) async {
      final mockAuth = MockAuthRepoForPDP(initialUser: null);

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          initialProduct: multiImageProduct,
          authRepo: mockAuth,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pdp_buy_now_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AuthModalBottomSheet), findsOneWidget);
    });

    testWidgets(
        'authenticated user: tapping Add to Cart invokes onAddToCart callback',
        (tester) async {
      ProductModel? cartProduct;
      final mockAuth = MockAuthRepoForPDP(initialUser: testParent);

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          initialProduct: multiImageProduct,
          authRepo: mockAuth,
          onAddToCart: (p, _) => cartProduct = p,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pdp_add_to_cart_button')));
      await tester.pumpAndSettle();

      expect(cartProduct, isNotNull);
      expect(cartProduct?.productId, equals('prod_multi'));
      expect(find.byType(AuthModalBottomSheet), findsNothing);
    });

    testWidgets(
        'authenticated user: tapping Buy Now invokes onBuyNow callback',
        (tester) async {
      ProductModel? buyProduct;
      final mockAuth = MockAuthRepoForPDP(initialUser: testParent);

      await tester.pumpWidget(
        createSubject(
          productId: 'prod_multi',
          initialProduct: multiImageProduct,
          authRepo: mockAuth,
          onBuyNow: (p, _) => buyProduct = p,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pdp_buy_now_button')));
      await tester.pumpAndSettle();

      expect(buyProduct, isNotNull);
      expect(buyProduct?.productId, equals('prod_multi'));
      expect(find.byType(AuthModalBottomSheet), findsNothing);
    });
  });

  group('Responsive Viewport Tests (Zero Overflows)', () {
    const viewports = [
      Size(360, 640), // Small Android
      Size(375, 667), // iPhone SE
      Size(390, 844), // iPhone 14
      Size(412, 915), // Pixel 7
      Size(428, 926), // Large iPhone
    ];

    for (final size in viewports) {
      testWidgets('zero overflow on ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createSubject(
            productId: 'prod_multi',
            initialProduct: multiImageProduct,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DPS Boys Premium Uniform Set'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
