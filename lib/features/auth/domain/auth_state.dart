import 'user_model.dart';

/// Sealed hierarchy representing all possible authentication states for Book Vardi.
sealed class AuthState {
  const AuthState();

  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.unauthenticated({bool isGuest}) = AuthUnauthenticated;
  const factory AuthState.authenticated(UserModel user) = AuthAuthenticated;
  const factory AuthState.error(String message) = AuthError;

  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isGuest =>
      this is AuthUnauthenticated && (this as AuthUnauthenticated).isGuest;
  UserModel? get user =>
      this is AuthAuthenticated ? (this as AuthAuthenticated).user : null;
  String? get errorMessage =>
      this is AuthError ? (this as AuthError).message : null;
  String? get error => errorMessage;
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  @override
  final bool isGuest;
  const AuthUnauthenticated({this.isGuest = true});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUnauthenticated &&
          runtimeType == other.runtimeType &&
          isGuest == other.isGuest;

  @override
  int get hashCode => isGuest.hashCode;
}

class AuthAuthenticated extends AuthState {
  @override
  final UserModel user;
  const AuthAuthenticated(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
