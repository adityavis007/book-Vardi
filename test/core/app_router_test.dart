import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:book_vardi/core/router/app_router.dart';
import 'package:book_vardi/core/theme/app_theme.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/auth/presentation/screens/profile_screen.dart';
import 'package:book_vardi/features/catalog/presentation/screens/all_products_screen.dart';
import 'package:book_vardi/features/catalog/presentation/screens/categories_screen.dart';
import 'package:book_vardi/features/orders/data/order_repository.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/features/orders/presentation/screens/order_history_screen.dart';

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

class _DummyOrdersRepo implements IOrdersRepository {
  @override
  Stream<List<OrderModel>> watchUserOrders(String userId) => Stream.value(const []);
  @override
  Stream<OrderModel?> watchOrderById(String orderId) => Stream.value(null);
  @override
  Future<OrderModel?> fetchOrderById(String orderId) async => null;
  @override
  Future<void> cancelOrder(String orderId, String reason) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildRouterApp(WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      theme: BookVardiTheme.lightTheme,
      routerConfig: router,
    );
  }

  group('AppRouter Navigation Tests', () {
    testWidgets('initial route renders Home Screen inside AppScaffoldShell',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersRepositoryProvider.overrideWithValue(_DummyOrdersRepo()),
          ],
          child: Consumer(
            builder: (context, ref, _) => buildRouterApp(ref),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byTooltip('Search catalog'), findsOneWidget);
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
    });

    testWidgets('navigates between shell branches maintaining tab state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersRepositoryProvider.overrideWithValue(_DummyOrdersRepo()),
            authControllerProvider.overrideWith(
              (ref) => FakeAuthController(const AuthState.unauthenticated(isGuest: true)),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) => buildRouterApp(ref),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Categories (tab index 1)
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoriesScreen), findsOneWidget);

      // Switch to Products (tab index 2)
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      expect(find.byType(AllProductsScreen), findsOneWidget);

      // Switch to Orders (tab index 3)
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderHistoryScreen), findsOneWidget);

      // Switch to Account (tab index 4)
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Switch back to Home (tab index 0)
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('pushes to subroutes like /product/:id',
        (WidgetTester tester) async {
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(
                theme: BookVardiTheme.lightTheme,
                routerConfig: router,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      router.push('/product/uniform-std-5');
      await tester.pumpAndSettle();

      expect(find.text('Product Detail: uniform-std-5'), findsOneWidget);
    });
  });
}
