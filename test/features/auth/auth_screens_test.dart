import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/auth/presentation/screens/login_screen.dart';
import 'package:book_vardi/features/auth/presentation/screens/register_screen.dart';

class MockAuthRepoForScreens implements IAuthRepository {
  String? lastSentPhoneNumber;
  String? lastVerifiedOtp;
  String? lastVerifiedName;

  @override
  Stream<UserModel?> watchAuthState() => Stream.value(null);

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
  }) async {
    lastSentPhoneNumber = phoneNumber;
    codeSent('screen_vid_123', 777777);
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    lastVerifiedOtp = smsCode;
    lastVerifiedName = name;
    return UserModel(
      userId: 'test_uid',
      name: name ?? 'Aditya Test',
      phone: lastSentPhoneNumber ?? '+919876543210',
      role: UserRole.customer,
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel> updateProfile(UserModel user) async => user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableApp({
    required MockAuthRepoForScreens mockRepo,
    required String initialLocation,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Home Catalog View'))),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('LoginScreen Tests', () {
    testWidgets('renders all initial Phone + OTP login elements and guest CTAs',
        (WidgetTester tester) async {
      final mockRepo = MockAuthRepoForScreens();
      await tester.pumpWidget(
        buildTestableApp(mockRepo: mockRepo, initialLocation: '/login'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book Vardi'), findsOneWidget);
      expect(
        find.text('Sign in to access school uniforms, book bundles, and orders'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('login_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('login_name_field')), findsOneWidget);
      expect(find.byKey(const Key('login_get_otp_button')), findsOneWidget);
      expect(find.byKey(const Key('login_skip_button')), findsOneWidget);
      expect(
        find.byKey(const Key('login_continue_as_guest_button')),
        findsOneWidget,
      );

      // Verify email/password/google are absent
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.text('Password'), findsNothing);
    });

    testWidgets('tapping Skip transitions to / with guest state',
        (WidgetTester tester) async {
      final mockRepo = MockAuthRepoForScreens();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Home Catalog View'))),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap top-right Skip
      final skipButton = find.byKey(const Key('login_skip_button'));
      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      expect(find.text('Home Catalog View'), findsOneWidget);
      final authState = container.read(authControllerProvider);
      expect(authState, isA<AuthUnauthenticated>());
      expect((authState as AuthUnauthenticated).isGuest, isTrue);
    });

    testWidgets('submits phone number and OTP then navigates home',
        (WidgetTester tester) async {
      final mockRepo = MockAuthRepoForScreens();
      await tester.pumpWidget(
        buildTestableApp(mockRepo: mockRepo, initialLocation: '/login'),
      );
      await tester.pumpAndSettle();

      // Enter phone
      await tester.enterText(
        find.byKey(const Key('login_phone_field')),
        '9876543210',
      );
      await tester.pump();

      // Tap Get OTP
      final getOtpBtn = find.byKey(const Key('login_get_otp_button'));
      await tester.ensureVisible(getOtpBtn);
      await tester.tap(getOtpBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.lastSentPhoneNumber, equals('+919876543210'));
      expect(find.byKey(const Key('login_otp_field')), findsOneWidget);

      // Enter OTP
      await tester.enterText(
        find.byKey(const Key('login_otp_field')),
        '123456',
      );
      await tester.pump();

      // Tap Verify & Continue
      final verifyBtn = find.byKey(const Key('login_verify_button'));
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Dismiss location dialog if displayed
      final locationCloseBtn = find.byKey(const Key('location_modal_close_button'));
      if (locationCloseBtn.evaluate().isNotEmpty) {
        await tester.tap(locationCloseBtn);
        await tester.pumpAndSettle();
      }

      expect(mockRepo.lastVerifiedOtp, equals('123456'));
      expect(find.text('Home Catalog View'), findsOneWidget);
    });
  });

  group('RegisterScreen Tests', () {
    testWidgets('renders registration phone form and guest skip actions',
        (WidgetTester tester) async {
      final mockRepo = MockAuthRepoForScreens();
      await tester.pumpWidget(
        buildTestableApp(mockRepo: mockRepo, initialLocation: '/register'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(
        find.text('Join Book Vardi for school uniforms and book bundles'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('register_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('register_get_otp_button')), findsOneWidget);
      expect(find.byKey(const Key('register_skip_button')), findsOneWidget);
      expect(
        find.byKey(const Key('register_continue_as_guest_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Continue as Guest from Register navigates to /',
        (WidgetTester tester) async {
      final mockRepo = MockAuthRepoForScreens();
      await tester.pumpWidget(
        buildTestableApp(mockRepo: mockRepo, initialLocation: '/register'),
      );
      await tester.pumpAndSettle();

      final guestBtn =
          find.byKey(const Key('register_continue_as_guest_button'));
      await tester.ensureVisible(guestBtn);
      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      expect(find.text('Home Catalog View'), findsOneWidget);
    });

    testWidgets('submits registration successfully with Name and OTP',
        (WidgetTester tester) async {
      final mockRepo = MockAuthRepoForScreens();
      await tester.pumpWidget(
        buildTestableApp(mockRepo: mockRepo, initialLocation: '/register'),
      );
      await tester.pumpAndSettle();

      // Enter Name & Phone
      await tester.enterText(
        find.byKey(const Key('register_name_field')),
        'Rohan Verma',
      );
      await tester.enterText(
        find.byKey(const Key('register_phone_field')),
        '9876543210',
      );
      await tester.pump();

      final getOtpBtn = find.byKey(const Key('register_get_otp_button'));
      await tester.ensureVisible(getOtpBtn);
      await tester.tap(getOtpBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_otp_field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('register_otp_field')),
        '654321',
      );
      await tester.pump();

      final verifyBtn = find.byKey(const Key('register_verify_button'));
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Dismiss location dialog if displayed
      final locationCloseBtn = find.byKey(const Key('location_modal_close_button'));
      if (locationCloseBtn.evaluate().isNotEmpty) {
        await tester.tap(locationCloseBtn);
        await tester.pumpAndSettle();
      }

      expect(mockRepo.lastVerifiedName, equals('Rohan Verma'));
      expect(mockRepo.lastVerifiedOtp, equals('654321'));
      expect(find.text('Home Catalog View'), findsOneWidget);
    });
  });
}
