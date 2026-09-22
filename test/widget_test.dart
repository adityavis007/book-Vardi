import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/network/fcm_service.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/orders/data/order_repository.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/main.dart';

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

class FakeFcmService implements IFcmService {
  @override
  Future<NotificationSettings?> requestPermissions() async => null;
  @override
  Future<String?> getDeviceToken() async => 'mock_token';
  @override
  Future<void> syncDeviceToken(String userId) async {}
  @override
  Future<void> removeDeviceToken(String userId) async {}
  @override
  void setupMessageHandlers({
    required void Function(String orderId) onNavigateToOrder,
    void Function(String title, String body, String? orderId)? onForegroundMessage,
  }) {}
  @override
  void dispose() {}
}

void main() {
  testWidgets('BookVardiApp bootstraps and renders core shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fcmServiceProvider.overrideWithValue(FakeFcmService()),
          ordersRepositoryProvider.overrideWithValue(_DummyOrdersRepo()),
          authControllerProvider.overrideWith(
            (ref) => FakeAuthController(const AuthState.unauthenticated(isGuest: true)),
          ),
        ],
        child: const BookVardiApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify brand header and initial Home Screen
    expect(find.byTooltip('Search catalog'), findsOneWidget);
    expect(find.text('Home Screen'), findsOneWidget);
  });
}
