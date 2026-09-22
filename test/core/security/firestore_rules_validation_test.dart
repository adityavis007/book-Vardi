import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TASK-063: Firestore Security Rules Validation Tests', () {
    late String rulesContent;

    setUpAll(() {
      final file = File('firestore.rules');
      expect(file.existsSync(), isTrue, reason: 'firestore.rules must exist at the project root');
      rulesContent = file.readAsStringSync();
    });

    test('rules syntax specifies version 2 and cloud.firestore service', () {
      expect(rulesContent.contains("rules_version = '2';"), isTrue);
      expect(rulesContent.contains('service cloud.firestore'), isTrue);
    });

    test('helper functions isAuthenticated, isOwner, and isAdmin are defined', () {
      expect(rulesContent.contains('function isAuthenticated()'), isTrue);
      expect(rulesContent.contains('function isOwner(userId)'), isTrue);
      expect(rulesContent.contains('function isAdmin()'), isTrue);
      expect(rulesContent.contains("request.auth.token.role == 'admin'"), isTrue);
    });

    test('public catalog collections allow public read and admin write only', () {
      // Products
      expect(rulesContent.contains('match /products/{productId}'), isTrue);
      expect(rulesContent.contains('allow read: if true;'), isTrue);
      expect(rulesContent.contains('allow write: if isAdmin();'), isTrue);

      // Categories
      expect(rulesContent.contains('match /categories/{categoryId}'), isTrue);

      // Schools
      expect(rulesContent.contains('match /schools/{schoolId}'), isTrue);
    });

    test('private user subcollections are protected with isOwner', () {
      expect(rulesContent.contains('match /users/{userId}'), isTrue);
      expect(rulesContent.contains('match /addresses/{addressId}'), isTrue);
      expect(rulesContent.contains('match /cart/{cartItemId}'), isTrue);
      expect(rulesContent.contains('match /wishlist/{productId}'), isTrue);
      expect(rulesContent.contains('match /fcmTokens/{token}'), isTrue);

      expect(rulesContent.contains('allow read, write: if isOwner(userId);'), isTrue);
    });

    test('orders collection enforces strict creation ownership and admin status progression', () {
      expect(rulesContent.contains('match /orders/{orderId}'), isTrue);
      // Order create only if authenticated and matching auth uid
      expect(rulesContent.contains('request.resource.data.userId == request.auth.uid'), isTrue);
      // Order read only by owner or admin
      expect(rulesContent.contains('resource.data.userId == request.auth.uid ||'), isTrue);
      // Hard delete blocked
      expect(rulesContent.contains('allow delete: if false;'), isTrue);
    });

    test('fallback catch-all blocks any undefined document path', () {
      expect(rulesContent.contains('match /{document=**}'), isTrue);
      expect(rulesContent.contains('allow read, write: if false;'), isTrue);
    });
  });
}
