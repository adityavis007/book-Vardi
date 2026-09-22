import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/config/env_config.dart';
import 'package:book_vardi/core/config/firebase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnvConfig Tests', () {
    test('default environment resolves to development', () {
      expect(EnvConfig.environment, Environment.development);
      expect(EnvConfig.isDevelopment, isTrue);
      expect(EnvConfig.isProduction, isFalse);
    });

    test('default keys and endpoints are configured', () {
      expect(EnvConfig.razorpayKeyId, isNotEmpty);
      expect(EnvConfig.apiBaseUrl, equals('https://api.bookvardi.com'));
      expect(EnvConfig.enableAppCheck, isFalse);
    });
  });

  group('FirebaseConfig Tests', () {
    test('initialize runs without throwing unhandled exceptions', () async {
      // In local unit test without native mocks, should gracefully catch and handle
      await expectLater(FirebaseConfig.initialize(), completes);
    });
  });
}
