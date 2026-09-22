import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
}
