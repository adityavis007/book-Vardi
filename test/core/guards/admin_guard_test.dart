import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:book_vardi/core/guards/admin_guard.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';

class _DummyAuthRepo implements IAuthRepository {
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

class FakeAuthController extends AuthController {
  FakeAuthController(AuthState initialState) : super(authRepository: _DummyAuthRepo()) {
    state = initialState;
  }
}

void main() {
  const customerUser = UserModel(
    userId: 'user_cust_1',
    name: 'Customer User',
    email: 'cust@example.com',
    role: UserRole.customer,
  );

  const adminUser = UserModel(
    userId: 'user_admin_1',
    name: 'Admin User',
    email: 'admin@example.com',
    role: UserRole.admin,
  );

  group('TASK-058: Admin Role Guard Unit Tests', () {
    test('isAdminProvider returns true for admin user', () {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState.authenticated(adminUser)),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isAdminProvider), isTrue);
    });

    test('isAdminProvider returns false for customer user', () {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState.authenticated(customerUser)),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isAdminProvider), isFalse);
    });

    test('isAdminProvider returns false for guest user', () {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState.unauthenticated(isGuest: true)),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isAdminProvider), isFalse);
    });
  });

  group('AdminAccessDeniedScreen Widget Tests', () {
    testWidgets('renders security warning and returns home when tapped', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState.authenticated(customerUser)),
          ),
        ],
      );

      final router = GoRouter(
        initialLocation: '/admin/access-denied',
        routes: [
          GoRoute(
            path: '/admin/access-denied',
            builder: (context, state) => const AdminAccessDeniedScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Home Screen Mock')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Administrator Access Required'), findsOneWidget);
      expect(find.textContaining('Your current account role is: "customer"'), findsOneWidget);

      final homeBtn = find.byKey(const Key('admin_return_home_btn'));
      expect(homeBtn, findsOneWidget);

      await tester.tap(homeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Home Screen Mock'), findsOneWidget);
    });
  });
}
