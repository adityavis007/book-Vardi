import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/guards/guest_guard.dart';
import 'package:book_vardi/core/guards/pending_action.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';

class MockAuthRepoForGuard implements IAuthRepository {
  final UserModel? initialUser;

  MockAuthRepoForGuard({this.initialUser});

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
    codeSent('mock_guard_vid', 123456);
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

class TestCatalogWidget extends ConsumerWidget {
  final PendingAction action;
  final VoidCallback onActionExecuted;

  const TestCatalogWidget({
    super.key,
    required this.action,
    required this.onActionExecuted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('add_to_cart_button'),
          onPressed: () {
            executeWithAuthGuard(
              context,
              ref,
              action: action,
              onAuthenticated: onActionExecuted,
            );
          },
          child: const Text('Add to Cart'),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('executeWithAuthGuard Interceptor Tests', () {
    testWidgets(
        'executes immediately without modal when user is already authenticated',
        (WidgetTester tester) async {
      bool actionExecuted = false;
      const authenticatedUser = UserModel(
        userId: 'user_123',
        name: 'Logged-in Parent',
        email: 'parent@school.com',
        role: UserRole.customer,
      );

      final mockRepo = MockAuthRepoForGuard(initialUser: authenticatedUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: TestCatalogWidget(
              action: const PendingAction(
                type: PendingActionType.addToCart,
                productId: 'uniform_shirt_101',
                variantId: 'size_36_boys',
                quantity: 2,
              ),
              onActionExecuted: () => actionExecuted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(actionExecuted, isFalse);

      // Tap Add to Cart
      await tester.tap(find.byKey(const Key('add_to_cart_button')));
      await tester.pumpAndSettle();

      // Callback fired immediately
      expect(actionExecuted, isTrue);

      // AuthModalBottomSheet was NOT shown
      expect(find.text('Welcome to Book Vardi'), findsNothing);
    });

    testWidgets(
        'simulates guest tap -> modal pops -> user logs in -> onAuthenticated callback fires with identical parameters',
        (WidgetTester tester) async {
      String? executedProduct;
      String? executedVariant;
      int? executedQuantity;

      const action = PendingAction(
        type: PendingActionType.addToCart,
        productId: 'uniform_shirt_101',
        variantId: 'size_36_boys',
        quantity: 2,
      );

      final mockRepo = MockAuthRepoForGuard(initialUser: null);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: TestCatalogWidget(
              action: action,
              onActionExecuted: () {
                executedProduct = action.productId;
                executedVariant = action.variantId;
                executedQuantity = action.quantity;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(executedProduct, isNull);

      // 1. Guest taps "Add to Cart"
      await tester.tap(find.byKey(const Key('add_to_cart_button')));
      await tester.pumpAndSettle();

      // 2. Auth Modal pops up
      expect(find.text('Welcome to Book Vardi'), findsOneWidget);

      // Verify action is preserved in pendingActionProvider
      final pendingInQueue = container.read(pendingActionProvider);
      expect(pendingInQueue, isNotNull);
      expect(pendingInQueue?.productId, equals('uniform_shirt_101'));
      expect(pendingInQueue?.variantId, equals('size_36_boys'));
      expect(pendingInQueue?.quantity, equals(2));

      // 3. User enters phone number
      await tester.enterText(
        find.byKey(const Key('auth_modal_phone_field')),
        '9876543210',
      );
      await tester.tap(find.byKey(const Key('auth_modal_get_otp_button')));
      await tester.pumpAndSettle();

      // 4. User enters 6-digit OTP
      await tester.enterText(
        find.byKey(const Key('auth_modal_otp_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('auth_modal_verify_button')));
      await tester.pumpAndSettle();

      // 5. onAuthenticated callback fired automatically with exact parameters
      expect(executedProduct, equals('uniform_shirt_101'));
      expect(executedVariant, equals('size_36_boys'));
      expect(executedQuantity, equals(2));

      // 6. Modal is dismissed and pending action is cleared
      expect(find.text('Welcome to Book Vardi'), findsNothing);
      expect(container.read(pendingActionProvider), isNull);
    });

    testWidgets(
        'guest dismisses modal sheet -> callback is NOT executed and queue is cleared',
        (WidgetTester tester) async {
      bool actionExecuted = false;

      final mockRepo = MockAuthRepoForGuard(initialUser: null);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: TestCatalogWidget(
              action: const PendingAction(
                type: PendingActionType.buyNow,
                productId: 'book_bundle_class_6',
              ),
              onActionExecuted: () => actionExecuted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button as guest
      await tester.tap(find.byKey(const Key('add_to_cart_button')));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Book Vardi'), findsOneWidget);

      // Dismiss modal by tapping "Continue Browsing as Guest"
      final guestDismissBtn =
          find.byKey(const Key('auth_modal_guest_dismiss_button'));
      await tester.ensureVisible(guestDismissBtn);
      await tester.tap(guestDismissBtn);
      await tester.pumpAndSettle();

      // Modal is gone
      expect(find.text('Welcome to Book Vardi'), findsNothing);

      // Action did NOT execute
      expect(actionExecuted, isFalse);

      // Queue is cleared
      expect(container.read(pendingActionProvider), isNull);
    });

    testWidgets(
        'WidgetRef.withAuthGuard extension executes successfully',
        (WidgetTester tester) async {
      bool extensionExecuted = false;
      final mockRepo = MockAuthRepoForGuard(
        initialUser: const UserModel(
          userId: 'ext_user',
          name: 'Extension User',
          email: 'ext@test.com',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    key: const Key('ext_test_btn'),
                    onPressed: () {
                      ref.withAuthGuard(
                        context,
                        action: const PendingAction(
                          type: PendingActionType.openProfile,
                        ),
                        onAuthenticated: () => extensionExecuted = true,
                      );
                    },
                    child: const Text('Test Ext'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ext_test_btn')));
      await tester.pumpAndSettle();

      expect(extensionExecuted, isTrue);
    });
  });
}
