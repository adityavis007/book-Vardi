import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/widgets/auth_modal_sheet.dart';

class MockAuthRepoForSheet implements IAuthRepository {
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
    codeSent('mock_vid_sheet', 111111);
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    return UserModel(
      userId: 'logged_in_uid',
      name: name ?? 'Aditya Test',
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
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableModal({
    VoidCallback? onSuccess,
    VoidCallback? onDismiss,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepoForSheet()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => AuthModalBottomSheet(
                      onSuccess: onSuccess,
                      onDismiss: onDismiss,
                    ),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('AuthModalBottomSheet Pure Phone + OTP Tests', () {
    testWidgets('renders Step 1 phone input and guest dismiss button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableModal());

      // Open bottom sheet
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Book Vardi'), findsOneWidget);
      expect(
        find.text('Enter your 10-digit mobile number to receive an OTP'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('auth_modal_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_modal_get_otp_button')), findsOneWidget);
      expect(
        find.byKey(const Key('auth_modal_guest_dismiss_button')),
        findsOneWidget,
      );

      // Verify Google and Email/Password fields are completely absent
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.text('Password'), findsNothing);
      expect(find.text('Email or Phone Number'), findsNothing);
    });

    testWidgets('dismisses sheet on Continue Browsing as Guest tap',
        (WidgetTester tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        buildTestableModal(
          onDismiss: () => dismissed = true,
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      final guestButton =
          find.byKey(const Key('auth_modal_guest_dismiss_button'));
      await tester.ensureVisible(guestButton);
      await tester.tap(guestButton);
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Book Vardi'), findsNothing);
      expect(dismissed, isTrue);
    });

    testWidgets('entering 10 digits and tapping GET OTP moves to Step 2 OTP',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableModal());

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Enter 10-digit mobile number
      await tester.enterText(
        find.byKey(const Key('auth_modal_phone_field')),
        '9876543210',
      );
      await tester.pump();

      // Tap Get OTP
      final getOtpBtn = find.byKey(const Key('auth_modal_get_otp_button'));
      await tester.ensureVisible(getOtpBtn);
      await tester.tap(getOtpBtn);
      await tester.pumpAndSettle();

      // Step 2 elements are rendered
      expect(find.text('Verify Phone Number'), findsOneWidget);
      expect(find.text('OTP sent to +91 9876543210'), findsOneWidget);
      expect(find.byKey(const Key('auth_modal_edit_phone_button')), findsOneWidget);
      expect(find.byKey(const Key('auth_modal_otp_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_modal_verify_button')), findsOneWidget);
    });

    testWidgets('editing number returns from Step 2 back to Step 1',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableModal());

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Go to Step 2
      await tester.enterText(
        find.byKey(const Key('auth_modal_phone_field')),
        '9876543210',
      );
      final getOtpBtn = find.byKey(const Key('auth_modal_get_otp_button'));
      await tester.ensureVisible(getOtpBtn);
      await tester.tap(getOtpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Verify Phone Number'), findsOneWidget);

      // Tap Edit
      final editBtn = find.byKey(const Key('auth_modal_edit_phone_button'));
      await tester.ensureVisible(editBtn);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Back to Step 1
      expect(find.text('Welcome to Book Vardi'), findsOneWidget);
      expect(find.byKey(const Key('auth_modal_phone_field')), findsOneWidget);
    });

    testWidgets('submits 6-digit OTP and triggers onSuccess callback',
        (WidgetTester tester) async {
      bool succeeded = false;

      await tester.pumpWidget(
        buildTestableModal(
          onSuccess: () => succeeded = true,
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Step 1: Send OTP
      await tester.enterText(
        find.byKey(const Key('auth_modal_phone_field')),
        '9876543210',
      );
      final getOtpBtn = find.byKey(const Key('auth_modal_get_otp_button'));
      await tester.ensureVisible(getOtpBtn);
      await tester.tap(getOtpBtn);
      await tester.pumpAndSettle();

      // Step 2: Enter 6-digit OTP
      final otpField = find.byKey(const Key('auth_modal_otp_field'));
      await tester.ensureVisible(otpField);
      await tester.enterText(otpField, '123456');
      await tester.pump();

      // Tap Verify & Continue
      final verifyBtn = find.byKey(const Key('auth_modal_verify_button'));
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      expect(succeeded, isTrue);
      expect(find.text('Welcome to Book Vardi'), findsNothing);
      expect(find.text('Verify Phone Number'), findsNothing);
    });

    testWidgets('AuthModalBottomSheet.show presents bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepoForSheet()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => AuthModalBottomSheet.show(context),
                    child: const Text('Trigger Static Show'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Static Show'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Book Vardi'), findsOneWidget);
    });
  });
}
