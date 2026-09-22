import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/constants/app_colors.dart';
import 'package:book_vardi/core/guards/pending_action.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/widgets/auth_modal_sheet.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/presentation/widgets/product_card.dart';

class MockAuthRepoForProductCard implements IAuthRepository {
  final UserModel? initialUser;

  MockAuthRepoForProductCard({this.initialUser});

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
    codeSent('mock_card_vid', 123456);
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    return UserModel(
      userId: 'authenticated_uid',
      name: name ?? 'Aditya Parent',
      phone: '+919876543210',
      role: UserRole.customer,
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel> updateProfile(UserModel user) async => user;
}

void main() {
  const discountedProduct = ProductModel(
    productId: 'prod_uniform_set',
    name: 'Complete Uniform Set (Boys)',
    description: 'High quality cotton-blend school uniform set.',
    categoryId: 'cat_uniforms',
    schoolName: "St. Xavier's High School",
    targetGrade: '5th - 8th Std',
    basePrice: 1599.0,
    discountPrice: 1299.0,
    inStock: true,
  );

  const regularProduct = ProductModel(
    productId: 'prod_math_book',
    name: 'NCERT Mathematics Textbook',
    description: 'Grade 6 CBSE standard textbook.',
    categoryId: 'cat_books',
    schoolName: 'Delhi Public School',
    targetGrade: 'Class 6',
    basePrice: 850.0,
    discountPrice: null,
    inStock: true,
  );

  const outOfStockProduct = ProductModel(
    productId: 'prod_shoes_32',
    name: 'School Black Leather Shoes',
    description: 'Size 32 standard uniform footwear.',
    categoryId: 'cat_footwear',
    schoolName: 'St. Mary School',
    targetGrade: 'Class 4',
    basePrice: 999.0,
    inStock: false,
  );

  const testMember = UserModel(
    userId: 'parent_123',
    email: 'parent@example.com',
    name: 'Aditya Sharma',
    role: UserRole.customer,
  );

  group('ProductCard Visual Elements & Discount Calculation Tests', () {
    testWidgets('renders discounted product with Amber discount pill, effective price and strikethrough MRP',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  width: 220,
                  product: discountedProduct,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify School Name micro text
      expect(find.text("St. Xavier's High School"), findsOneWidget);

      // Verify Title
      expect(find.text('Complete Uniform Set (Boys)'), findsOneWidget);

      // Verify Target Grade
      expect(find.text('Class: 5th - 8th Std'), findsOneWidget);

      // Discount Calculation: (1599 - 1299) / 1599 * 100 = 18.76% -> 19%
      expect(find.text('19% OFF'), findsOneWidget);

      // Effective Price
      expect(find.text('₹1,299'), findsOneWidget);

      // Base Price with strikethrough
      final mrpFinder = find.text('₹1,599');
      expect(mrpFinder, findsOneWidget);
      final mrpText = tester.widget<Text>(mrpFinder);
      expect(mrpText.style?.decoration, TextDecoration.lineThrough);

      // Add to cart button
      expect(find.text('ADD TO CART +'), findsOneWidget);

      // Wishlist unselected heart icon
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('renders regular product without discount pill or strikethrough price',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  width: 220,
                  product: regularProduct,
                ),
              ),
            ),
          ),
        ),
      );

      // No discount pill
      expect(find.textContaining('% OFF'), findsNothing);

      // Only one price displayed (₹850)
      expect(find.text('₹850'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('renders filled heart in red when isWishlisted is true',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  width: 220,
                  product: regularProduct,
                  isWishlisted: true,
                ),
              ),
            ),
          ),
        ),
      );

      final heartFinder = find.byIcon(Icons.favorite);
      expect(heartFinder, findsOneWidget);
      final heartIcon = tester.widget<Icon>(heartFinder);
      expect(heartIcon.color, AppColors.destructiveRed);
    });

    testWidgets('renders disabled OUT OF STOCK button when inStock is false',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  width: 220,
                  product: outOfStockProduct,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('OUT OF STOCK'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);

      final buttonFinder = find.byType(OutlinedButton);
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<OutlinedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });
  });

  group('ProductCard Interactions & Guest Guard Tests', () {
    testWidgets('authenticated user: tapping ADD TO CART immediately calls onAddToCart',
        (tester) async {
      bool addedToCart = false;
      ProductModel? addedProduct;

      final mockRepo = MockAuthRepoForProductCard(initialUser: testMember);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  width: 220,
                  product: discountedProduct,
                  onAddToCart: (prod) {
                    addedToCart = true;
                    addedProduct = prod;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('ADD TO CART +'));
      await tester.pump();

      expect(addedToCart, isTrue);
      expect(addedProduct?.productId, 'prod_uniform_set');
    });

    testWidgets('guest user: tapping ADD TO CART prompts AuthModalBottomSheet and queues intent',
        (tester) async {
      final mockRepo = MockAuthRepoForProductCard(initialUser: null);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  width: 220,
                  product: discountedProduct,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Add to Cart as guest
      await tester.tap(find.text('ADD TO CART +'));
      await tester.pumpAndSettle();

      // Verify AuthModalBottomSheet is prompted
      expect(find.byType(AuthModalBottomSheet), findsOneWidget);

      // Verify pending action in queue
      final pendingAction = container.read(pendingActionProvider);
      expect(pendingAction, isNotNull);
      expect(pendingAction!.type, PendingActionType.addToCart);
      expect(pendingAction.productId, 'prod_uniform_set');
    });

    testWidgets('authenticated user: tapping wishlist button immediately calls onToggleWishlist',
        (tester) async {
      bool wishlistToggled = false;
      final mockRepo = MockAuthRepoForProductCard(initialUser: testMember);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  width: 220,
                  product: regularProduct,
                  onToggleWishlist: (_) => wishlistToggled = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();

      expect(wishlistToggled, isTrue);
    });

    testWidgets('tapping card body calls onTap callback', (tester) async {
      bool cardTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProductCard(
                  width: 220,
                  product: regularProduct,
                  onTap: (_) => cardTapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('NCERT Mathematics Textbook'));
      await tester.pump();

      expect(cardTapped, isTrue);
    });
  });
}
