import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';
import '../../domain/user_model.dart';

/// StateNotifier managing global Authentication state and session lifecycle.
class AuthController extends StateNotifier<AuthState> {
  final IAuthRepository authRepository;
  StreamSubscription<UserModel?>? _authStateSubscription;

  AuthController({required this.authRepository})
      : super(const AuthState.initial()) {
    _initSession();
  }

  void _initSession() {
    state = const AuthState.loading();
    _authStateSubscription = authRepository.watchAuthState().listen(
      (user) {
        if (user != null) {
          state = AuthState.authenticated(user);
        } else {
          // Default unauthenticated mode is Guest (browse-only without barrier)
          state = const AuthState.unauthenticated(isGuest: true);
        }
      },
      onError: (error) {
        state = AuthState.error(error.toString());
      },
    );
  }

  /// Send OTP to user's phone number via Firebase Phone Auth
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    void Function(UserModel user)? onAutoVerified,
    int? forceResendingToken,
  }) async {
    try {
      state = const AuthState.loading();
      await authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        verificationCompleted: (credential) async {
          try {
            if (credential.smsCode != null && credential.verificationId != null) {
              final user = await authRepository.signInWithOtp(
                verificationId: credential.verificationId!,
                smsCode: credential.smsCode!,
              );
              state = AuthState.authenticated(user);
              onAutoVerified?.call(user);
            }
          } catch (_) {}
        },
        verificationFailed: (e) {
          final errorMsg = e.message ?? 'Phone verification failed';
          state = AuthState.error(errorMsg);
          onError(errorMsg);
        },
        codeSent: (verificationId, resendToken) {
          state = const AuthState.unauthenticated(isGuest: true);
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      final errorMsg = e.toString();
      state = AuthState.error(errorMsg);
      onError(errorMsg);
    }
  }

  /// Verify 6-digit OTP code and authenticate user
  Future<bool> verifyOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    try {
      state = const AuthState.loading();
      final user = await authRepository.signInWithOtp(
        verificationId: verificationId,
        smsCode: smsCode,
        name: name,
      );
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Sign out current user and revert to Guest browsing state
  Future<void> logout() async {
    try {
      await authRepository.signOut();
      state = const AuthState.unauthenticated(isGuest: true);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Explicitly continue session as guest
  void continueAsGuest() {
    state = const AuthState.unauthenticated(isGuest: true);
  }

  /// Update user profile details and sync to Firestore
  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      state = const AuthState.loading();
      final user = await authRepository.updateProfile(updatedUser);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

/// Global provider for AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: repository);
});

/// Convenience provider for current user model
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).user;
});

/// Convenience provider checking if session is Guest
final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isGuest;
});

/// Convenience provider checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});
