import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';

void main() {
  group('UserModel Domain Tests', () {
    test('serializes toMap and fromMap with round-trip fidelity', () {
      final now = DateTime.now();
      final user = UserModel(
        userId: 'usr_1024',
        name: 'Aditya Sharma',
        email: 'parent@school.com',
        phone: '+919876543210',
        role: UserRole.customer,
        createdAt: now,
        updatedAt: now,
      );

      final map = user.toMap();
      expect(map['userId'], 'usr_1024');
      expect(map['role'], 'customer');

      final deserialized = UserModel.fromMap(map);
      expect(deserialized.userId, user.userId);
      expect(deserialized.name, user.name);
      expect(deserialized.email, user.email);
      expect(deserialized.phone, user.phone);
      expect(deserialized.role, user.role);
      expect(deserialized.isAdmin, isFalse);
    });

    test('correctly identifies admin role', () {
      const adminUser = UserModel(
        userId: 'adm_01',
        name: 'Store Manager',
        email: 'admin@bookvardi.com',
        role: UserRole.admin,
      );

      expect(adminUser.isAdmin, isTrue);

      final map = adminUser.toMap();
      final fromMapUser = UserModel.fromMap(map);
      expect(fromMapUser.isAdmin, isTrue);
      expect(fromMapUser.role, UserRole.admin);
    });

    test('copyWith creates modified clone while preserving original', () {
      const original = UserModel(
        userId: 'u1',
        name: 'Original',
        email: 'orig@test.com',
      );

      final updated = original.copyWith(name: 'Updated Name');
      expect(updated.name, 'Updated Name');
      expect(updated.email, 'orig@test.com');
      expect(original.name, 'Original');
    });
  });

  group('AuthState Tests', () {
    test('unauthenticated state defaults to guest user', () {
      const state = AuthState.unauthenticated();
      expect(state.isGuest, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
    });

    test('authenticated state holds user and reports true', () {
      const user = UserModel(
        userId: 'u1',
        name: 'User One',
        email: 'u1@test.com',
      );

      const state = AuthState.authenticated(user);
      expect(state.isAuthenticated, isTrue);
      expect(state.isGuest, isFalse);
      expect(state.user, equals(user));
    });

    test('error and loading states reflect accurately', () {
      const loading = AuthState.loading();
      expect(loading, isA<AuthLoading>());
      expect(loading.isAuthenticated, isFalse);

      const error = AuthState.error('Invalid credentials');
      expect(error, isA<AuthError>());
      expect((error as AuthError).message, 'Invalid credentials');
    });
  });
}
