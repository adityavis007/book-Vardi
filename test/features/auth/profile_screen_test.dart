import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/auth/presentation/screens/profile_screen.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/checkout/presentation/screens/address_step_screen.dart';

class _MockAuthRepo implements IAuthRepository {
  bool signOutCalled = false;

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
  Future<void> signOut() async {
    signOutCalled = true;
  }
  @override
  Future<UserModel> updateProfile(UserModel user) async => user;
}

class _TestAuthController extends AuthController {
  final _MockAuthRepo mockRepo;

  _TestAuthController(AuthState initialState, this.mockRepo)
      : super(authRepository: mockRepo) {
    state = initialState;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required AuthState authState,
    required _MockAuthRepo repo,
    List<Override> extraOverrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const Scaffold(body: Text('Edit Profile Mock Screen')),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const Scaffold(body: Text('Cart Mock Screen')),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (context, state) => const Scaffold(body: Text('Wishlist Mock Screen')),
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const Scaffold(body: Text('Orders Mock Screen')),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const Scaffold(body: Text('Admin Mock Screen')),
        ),
        GoRoute(
          path: '/help-support',
          builder: (context, state) => const Scaffold(body: Text('Help & Support Mock Screen')),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const Scaffold(body: Text('Terms & Conditions Mock Screen')),
        ),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const Scaffold(body: Text('Privacy Policy Mock Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        authControllerProvider.overrideWith(
          (ref) => _TestAuthController(authState, repo),
        ),
        ...extraOverrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders guest welcome card and login CTA when not authenticated', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.unauthenticated(isGuest: true),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Welcome to Book Vardi'), findsOneWidget);
      expect(find.byKey(const Key('profile_login_cta_button')), findsOneWidget);
      expect(find.text('Login / Create Account'), findsOneWidget);

      // Support & Legal tiles are still accessible for guests
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      // Logout button and authenticated user profile card should not be present
      expect(find.byKey(const Key('profile_logout_button')), findsNothing);
      expect(find.byKey(const Key('profile_my_orders_tile')), findsNothing);
    });

    testWidgets('renders user profile details and activity links when authenticated', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const testUser = UserModel(
        userId: 'usr_123',
        name: 'Rahul Sharma',
        email: 'rahul.sharma@example.com',
        phone: '9876543210',
        role: UserRole.customer,
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(testUser),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Verify User Details Card in collapsed state
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('R'), findsOneWidget); // Initial in avatar
      expect(find.text('rahul.sharma@example.com'), findsNothing); // Hidden when collapsed

      // Tap expand arrow to show extra details (Email & Phone)
      expect(find.byKey(const Key('profile_expand_toggle_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('profile_expand_toggle_btn')));
      await tester.pumpAndSettle();

      expect(find.text('rahul.sharma@example.com'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);

      // Activity tiles
      expect(find.byKey(const Key('profile_my_orders_tile')), findsOneWidget);
      expect(find.byKey(const Key('profile_saved_addresses_tile')), findsOneWidget);
      expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);

      // Admin tile should not be present for standard customer
      expect(find.byKey(const Key('profile_admin_portal_tile')), findsNothing);
    });

    testWidgets('renders Admin portal tile when user has admin role', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const adminUser = UserModel(
        userId: 'admin_123',
        name: 'Admin Boss',
        email: 'admin@bookvardi.com',
        phone: '9998887776',
        role: UserRole.admin,
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(adminUser),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADMIN'), findsWidgets);
      expect(find.byKey(const Key('profile_admin_portal_tile')), findsOneWidget);

      // Tap admin portal tile and verify navigation
      await tester.tap(find.byKey(const Key('profile_admin_portal_tile')));
      await tester.pumpAndSettle();
      expect(find.text('Admin Mock Screen'), findsOneWidget);
    });

    testWidgets('tapping My Orders tile navigates to /orders', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const testUser = UserModel(
        userId: 'usr_123',
        name: 'Ananya Verma',
        email: 'ananya@example.com',
        role: UserRole.customer,
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(testUser),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_my_orders_tile')));
      await tester.pumpAndSettle();

      expect(find.text('Orders Mock Screen'), findsOneWidget);
    });

    testWidgets('tapping Log Out opens confirmation dialog, and cancel dismisses it', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const testUser = UserModel(
        userId: 'usr_123',
        name: 'Test Customer',
        email: 'test@example.com',
        role: UserRole.customer,
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(testUser),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('profile_logout_button')));
      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out of your Book Vardi account?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog closed and signOut was not called
      expect(find.text('Are you sure you want to log out of your Book Vardi account?'), findsNothing);
      expect(repo.signOutCalled, isFalse);
    });

    testWidgets('confirming Log Out in dialog calls signOut', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const testUser = UserModel(
        userId: 'usr_123',
        name: 'Test Customer',
        email: 'test@example.com',
        role: UserRole.customer,
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(testUser),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('profile_logout_button')));
      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_confirm_logout_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('profile_confirm_logout_button')));
      await tester.pumpAndSettle();

      expect(repo.signOutCalled, isTrue);
    });

    testWidgets('tapping Help & Support tile navigates to /help-support', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.unauthenticated(isGuest: true),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('profile_help_support_tile')));
      await tester.tap(find.byKey(const Key('profile_help_support_tile')));
      await tester.pumpAndSettle();

      expect(find.text('Help & Support Mock Screen'), findsOneWidget);
    });

    testWidgets('tapping edit avatar badge navigates to /edit-profile', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const testUser = UserModel(
        userId: 'usr_edit_test',
        name: 'Rahul Student',
        email: 'rahul@example.com',
        role: UserRole.customer,
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(testUser),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_edit_avatar_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('profile_edit_avatar_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile Mock Screen'), findsOneWidget);
    });

    testWidgets('renders all 3 grouped sections, seller panel, and stat capsules', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const testUser = UserModel(
        userId: 'usr_wireframe_test',
        name: 'Rahul',
        schoolName: "Children's College Azamgarh",
        grade: 'Class 9',
        studentId: 'SC-5425',
        rewardPoints: 480,
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(testUser),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Top Banner User Info (Collapsed state by default)
      expect(find.text('Rahul'), findsOneWidget);
      expect(find.text("Children's College Azamgarh • Class 9"), findsOneWidget);
      expect(find.text('ID: SC-5425'), findsOneWidget);
      expect(find.text('STUDENT'), findsOneWidget);

      // Verify toggle button exists and expand the card
      expect(find.byKey(const Key('profile_expand_toggle_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('profile_expand_toggle_btn')));
      await tester.pumpAndSettle();

      // 4 Stat Capsules appear when card is expanded
      expect(find.text('ORDERS'), findsOneWidget);
      expect(find.text('LIKED ♥'), findsOneWidget);
      expect(find.text('IN CART 🛒'), findsOneWidget);
      expect(find.text('POINTS'), findsOneWidget);
      expect(find.text('480'), findsOneWidget);

      // 3 Grouped Sections (Image 1 Wireframe)
      expect(find.text('Your Information'), findsOneWidget);
      expect(find.text('Address book'), findsOneWidget);
      expect(find.text('Your Wishlist'), findsOneWidget);
      expect(find.text('Your Order'), findsOneWidget);
      expect(find.text('Your Cart'), findsOneWidget);

      expect(find.text('Payment And coupons'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Payment settings'), findsOneWidget);
      expect(find.text('Claim Gift card'), findsOneWidget);
      expect(find.text('Coupons & Offers'), findsOneWidget);

      expect(find.text('Other Information'), findsOneWidget);
      expect(find.text('About us'), findsOneWidget);
      expect(find.text('Share the app'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      // Seller Panel Login Card (Image 2 Website)
      expect(find.text('Seller Panel Login'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
    });

    testWidgets('tapping Address book opens Saved Delivery Addresses sheet with Edit button and launches Edit mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const testUser = UserModel(
        userId: 'usr_7830',
        name: 'Aditya Vishwakarma',
        phone: '9876543210',
      );

      const savedAddress = AddressModel(
        addressId: 'addr_101',
        fullName: 'Aditya Vishwakarma',
        phone: '9876543210',
        pincode: '333221',
        addressLine1: 'h23/3, Hostel',
        landmark: 'Near Renukoot',
        city: 'Renukoot',
        state: 'Uttar Pradesh',
        addressType: 'Home',
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(testUser),
          repo: repo,
          extraOverrides: [
            savedAddressesStreamProvider.overrideWith(
              (ref) => Stream.value([savedAddress]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Address book tile
      await tester.tap(find.text('Address book'));
      await tester.pumpAndSettle();

      // Bottom sheet header and saved address details rendered
      expect(find.text('Saved Delivery Addresses'), findsOneWidget);
      expect(find.text('Aditya Vishwakarma'), findsWidgets);
      expect(find.text('HOME'), findsWidgets);
      expect(find.byKey(const Key('edit_address_btn_addr_101')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('edit_address_btn_addr_101')),
          matching: find.text('Edit'),
        ),
        findsOneWidget,
      );

      // Tap Edit button
      await tester.tap(find.byKey(const Key('edit_address_btn_addr_101')));
      await tester.pumpAndSettle();

      // Navigated to Edit Delivery Address screen with prefilled details
      expect(find.text('Edit Delivery Address'), findsOneWidget);
      expect(find.byKey(const Key('save_address_button')), findsOneWidget);
    });
  });
}
