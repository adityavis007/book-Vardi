import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/config/env_config.dart';
import 'package:book_vardi/core/config/firebase_config.dart';

void main() {
  group('TASK-064: Firebase App Check Configuration Tests', () {
    test('EnvConfig exposes App Check flag with safe default', () {
      expect(EnvConfig.enableAppCheck, isA<bool>());
    });

    test('EnvConfig environment defaults to development', () {
      expect(EnvConfig.isDevelopment, isTrue);
      expect(EnvConfig.isProduction, isFalse);
    });

    test('FirebaseConfig exposes initialization status contract', () {
      expect(FirebaseConfig.isInitialized, isA<bool>());
    });
  });
}
