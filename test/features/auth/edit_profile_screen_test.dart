import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/auth/presentation/screens/edit_profile_screen.dart';

class _MockAuthRepo implements IAuthRepository {
  UserModel? updatedUser;

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
  Future<UserModel> updateProfile(UserModel user) async {
    updatedUser = user;
    return user;
  }
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
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        authControllerProvider.overrideWith(
          (ref) => _TestAuthController(authState, repo),
        ),
      ],
      child: const MaterialApp(
        home: EditProfileScreen(),
      ),
    );
  }

  group('EditProfileScreen Widget Tests', () {
    testWidgets('renders all personal and delivery address form fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const testUser = UserModel(
        userId: 'usr_edit_test',
        name: 'Rahul Sharma',
        email: 'rahul@example.com',
        phone: '9876543210',
        schoolName: "Children's College Azamgarh",
        grade: 'Class 9',
        studentId: 'SC-5425',
        rollNo: '24',
        addressLine: 'House 42, Civil Lines',
        city: 'Azamgarh',
        stateName: 'Uttar Pradesh',
        pincode: '276001',
        landmark: 'Near Clock Tower',
        addressLabel: 'Home',
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(testUser),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Top banner
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsWidgets);
      expect(find.text('STUDENT'), findsOneWidget);
      expect(find.text('Verified Student'), findsOneWidget);

      // Section titles
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.textContaining('Delivery Address'), findsOneWidget);

      // Fields
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.textContaining('MOBILE PHONE NUMBER'), findsOneWidget);
      expect(find.text('STUDENT ROLL NO.'), findsOneWidget);
      expect(find.text('SCHOOL / INSTITUTION'), findsOneWidget);
      expect(find.text('CLASS / STANDARD'), findsOneWidget);

      expect(find.text('HOUSE / FLAT NO, BUILDING, STREET ADDRESS'), findsOneWidget);
      expect(find.text('CITY / DISTRICT'), findsOneWidget);
      expect(find.text('STATE'), findsOneWidget);
      expect(find.text('PIN CODE'), findsOneWidget);
      expect(find.textContaining('LANDMARK'), findsOneWidget);
      expect(find.text('ADDRESS TAG / LABEL'), findsOneWidget);

      // Save button
      expect(find.byKey(const Key('edit_profile_save_button')), findsOneWidget);
    });

    testWidgets('tapping save button calls updateProfile with modified data', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockAuthRepo();
      const testUser = UserModel(
        userId: 'usr_edit_test',
        name: 'Old Name',
        email: 'old@example.com',
        phone: '9876543210',
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: const AuthState.authenticated(testUser),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Enter new name
      await tester.enterText(find.byKey(const Key('edit_profile_name_field')), 'New Rahul');
      await tester.pumpAndSettle();

      // Scroll to save button and tap
      await tester.ensureVisible(find.byKey(const Key('edit_profile_save_button')));
      await tester.tap(find.byKey(const Key('edit_profile_save_button')));
      await tester.pumpAndSettle();

      expect(repo.updatedUser, isNotNull);
      expect(repo.updatedUser?.name, 'New Rahul');
      expect(find.textContaining('Profile details updated successfully!'), findsOneWidget);
    });
  });
}
