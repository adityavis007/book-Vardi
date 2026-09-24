import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';

class MockAuthRepository implements IAuthRepository {
  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();
  bool shouldThrowOnSignIn = false;
  bool shouldThrowOnVerification = false;

  @override
  Stream<UserModel?> watchAuthState() => _authStateController.stream;

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    if (shouldThrowOnVerification) {
      verificationFailed(
        FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'The provided phone number is not valid.',
        ),
      );
      return;
    }
    codeSent('mock_verification_id_123', 654321);
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    if (shouldThrowOnSignIn) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'The SMS verification code is invalid.',
      );
    }
    final user = UserModel(
      userId: 'mock_uid_1',
      name: name ?? 'Aditya Parent',
      email: '',
      phone: '+919876543210',
      role: UserRole.customer,
    );
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    _currentUser = user;
    _authStateController.add(user);
    return user;
  }

  void dispose() {
    _authStateController.close();
  }
}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  group('AuthRepository Contract & Phone + OTP Tests', () {
    test('verifyPhoneNumber triggers codeSent with verificationId and resendToken',
        () async {
      String? sentVerificationId;
      int? sentResendToken;

      await repository.verifyPhoneNumber(
        phoneNumber: '9876543210',
        verificationCompleted: (_) {},
        verificationFailed: (_) {},
        codeSent: (id, token) {
          sentVerificationId = id;
          sentResendToken = token;
        },
        codeAutoRetrievalTimeout: (_) {},
      );

      expect(sentVerificationId, equals('mock_verification_id_123'));
      expect(sentResendToken, equals(654321));
    });

    test('verifyPhoneNumber propagates PhoneVerificationFailed on invalid phone',
        () async {
      repository.shouldThrowOnVerification = true;
      FirebaseAuthException? caughtError;

      await repository.verifyPhoneNumber(
        phoneNumber: '123',
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          caughtError = e;
        },
        codeSent: (_, __) {},
        codeAutoRetrievalTimeout: (_) {},
      );

      expect(caughtError, isNotNull);
      expect(caughtError!.code, equals('invalid-phone-number'));
    });

    test('signInWithOtp validates code and maps to UserModel with customer role',
        () async {
      final user = await repository.signInWithOtp(
        verificationId: 'mock_verification_id_123',
        smsCode: '123456',
        name: 'Rohan Sharma',
      );

      expect(user.userId, equals('mock_uid_1'));
      expect(user.name, equals('Rohan Sharma'));
      expect(user.phone, equals('+919876543210'));
      expect(user.role, equals(UserRole.customer));
      expect(user.isAdmin, isFalse);
    });

    test('signInWithOtp throws FirebaseAuthException when OTP is invalid',
        () async {
      repository.shouldThrowOnSignIn = true;

      expect(
        () => repository.signInWithOtp(
          verificationId: 'mock_verification_id_123',
          smsCode: '000000',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    test('watchAuthState emits updated UserModel on OTP login and null on signOut',
        () async {
      final emittedUsers = <UserModel?>[];
      final subscription = repository.watchAuthState().listen((u) {
        emittedUsers.add(u);
      });

      await repository.signInWithOtp(
        verificationId: 'mock_verification_id_123',
        smsCode: '123456',
      );

      await repository.signOut();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(emittedUsers.length, equals(2));
      expect(emittedUsers[0]?.phone, equals('+919876543210'));
      expect(emittedUsers[1], isNull);

      await subscription.cancel();
    });
  });

  group('FirebaseAuthRepository Local Session Persistence Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('saves authenticated user session locally upon signInWithOtp', () async {
      final repo = FirebaseAuthRepository(prefs: prefs);

      final user = await repo.signInWithOtp(
        verificationId: 'test_vid_9876543210',
        smsCode: '123456',
        name: 'Aditya Student',
      );

      expect(user.phone, equals('+919876543210'));
      expect(user.name, equals('Aditya Student'));

      // Check SharedPreferences directly
      final cachedRaw = prefs.getString('bv_auth_session_user_v1');
      expect(cachedRaw, isNotNull);
      expect(cachedRaw, contains('9876543210'));
      expect(cachedRaw, contains('Aditya Student'));
    });

    test('simulates app restart: new repository instance automatically restores session', () async {
      // 1. Initial app run: user logs in
      final firstRunRepo = FirebaseAuthRepository(prefs: prefs);
      await firstRunRepo.signInWithOtp(
        verificationId: 'test_vid_9876543210',
        smsCode: '123456',
        name: 'Aditya Student',
      );

      // 2. Simulate app close & reopen: new repository instance with same SharedPreferences
      final restartRepo = FirebaseAuthRepository(prefs: prefs);

      // getCurrentUser immediately returns cached user without network or login screen
      final restoredUser = await restartRepo.getCurrentUser();
      expect(restoredUser, isNotNull);
      expect(restoredUser!.phone, equals('+919876543210'));
      expect(restoredUser.name, equals('Aditya Student'));

      // watchAuthState immediately emits cached user on first tick
      final streamUser = await restartRepo.watchAuthState().first;
      expect(streamUser, isNotNull);
      expect(streamUser!.phone, equals('+919876543210'));
    });

    test('signOut clears local storage so next app launch starts as unauthenticated', () async {
      final repo = FirebaseAuthRepository(prefs: prefs);
      await repo.signInWithOtp(
        verificationId: 'test_vid_9876543210',
        smsCode: '123456',
        name: 'Aditya Student',
      );

      expect(await repo.getCurrentUser(), isNotNull);

      // Log out
      await repo.signOut();

      // Ensure SharedPreferences is cleared
      expect(prefs.getString('bv_auth_session_user_v1'), isNull);

      // Simulate app restart
      final restartRepo = FirebaseAuthRepository(prefs: prefs);
      final userAfterRestart = await restartRepo.getCurrentUser();
      expect(userAfterRestart, isNull);

      final streamUser = await restartRepo.watchAuthState().first;
      expect(streamUser, isNull);
    });

    test('updateProfile updates stored session in SharedPreferences', () async {
      final repo = FirebaseAuthRepository(prefs: prefs);
      final initial = await repo.signInWithOtp(
        verificationId: 'test_vid_9876543210',
        smsCode: '123456',
        name: 'Initial Name',
      );

      final updated = await repo.updateProfile(initial.copyWith(name: 'Updated Name'));
      expect(updated.name, equals('Updated Name'));

      // Restart app and verify updated name was persisted
      final restartRepo = FirebaseAuthRepository(prefs: prefs);
      final restored = await restartRepo.getCurrentUser();
      expect(restored?.name, equals('Updated Name'));
    });
  });
}
