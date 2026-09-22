import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:book_vardi/features/auth/data/auth_repository.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';

class FakeAuthRepository implements IAuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _user;
  bool failNextOperation = false;

  @override
  Stream<UserModel?> watchAuthState() => _controller.stream;

  @override
  Future<UserModel?> getCurrentUser() async => _user;

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    if (failNextOperation) {
      verificationFailed(
        FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'Invalid phone number provided',
        ),
      );
      return;
    }
    codeSent('test_vid_123', 999999);
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    if (failNextOperation) {
      throw Exception('Invalid OTP code');
    }
    final user = UserModel(
      userId: 'test_uid',
      name: name ?? 'Aditya User',
      email: '',
      phone: '+919876543210',
      role: UserRole.customer,
    );
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    _user = user;
    _controller.add(user);
    return user;
  }

  void emitAuthState(UserModel? user) {
    _controller.add(user);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthController(authRepository: repository);
  });

  tearDown(() {
    controller.dispose();
    repository.dispose();
  });

  group('AuthController State Transition Tests', () {
    test('initializes and defaults to Guest mode on null auth stream',
        () async {
      repository.emitAuthState(null);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.state, isA<AuthUnauthenticated>());
      expect(controller.state.isGuest, isTrue);
      expect(controller.state.isAuthenticated, isFalse);
    });

    test('sendOtp fires onCodeSent and sets unauthenticated guest state',
        () async {
      String? sentVerificationId;
      int? sentToken;

      await controller.sendOtp(
        phoneNumber: '+919876543210',
        onCodeSent: (id, token) {
          sentVerificationId = id;
          sentToken = token;
        },
        onError: (_) {},
      );

      expect(sentVerificationId, equals('test_vid_123'));
      expect(sentToken, equals(999999));
      expect(controller.state, isA<AuthUnauthenticated>());
      expect(controller.state.isGuest, isTrue);
    });

    test('sendOtp triggers onError and sets AuthError on failure', () async {
      repository.failNextOperation = true;
      String? caughtError;

      await controller.sendOtp(
        phoneNumber: '000',
        onCodeSent: (_, __) {},
        onError: (err) {
          caughtError = err;
        },
      );

      expect(caughtError, isNotNull);
      expect(controller.state, isA<AuthError>());
    });

    test('verifyOtp sets authenticated state with user profile upon valid OTP',
        () async {
      final success = await controller.verifyOtp(
        verificationId: 'test_vid_123',
        smsCode: '123456',
        name: 'Rohan Sharma',
      );

      expect(success, isTrue);
      expect(controller.state, isA<AuthAuthenticated>());
      expect(controller.state.isAuthenticated, isTrue);
      expect(controller.state.user?.phone, equals('+919876543210'));
      expect(controller.state.user?.name, equals('Rohan Sharma'));
    });

    test('verifyOtp sets error state on invalid code failure', () async {
      repository.failNextOperation = true;

      final success = await controller.verifyOtp(
        verificationId: 'test_vid_123',
        smsCode: '000000',
      );

      expect(success, isFalse);
      expect(controller.state, isA<AuthError>());
    });

    test('logout transitions back to Guest unauthenticated state', () async {
      await controller.verifyOtp(
        verificationId: 'test_vid_123',
        smsCode: '123456',
      );
      expect(controller.state.isAuthenticated, isTrue);

      await controller.logout();
      expect(controller.state, isA<AuthUnauthenticated>());
      expect(controller.state.isGuest, isTrue);
    });
  });
}
