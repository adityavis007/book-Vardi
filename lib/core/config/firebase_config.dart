import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'env_config.dart';

/// Central Firebase configuration and initialization service.
class FirebaseConfig {
  const FirebaseConfig._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initializes the Firebase suite with error boundaries, offline Firestore caching, and App Check.
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isInitialized = true;

      // Configure Firestore offline cache (100MB cache limit per PRD Section 6 NFRs)
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 104857600, // 100MB
        );
      } catch (e) {
        debugPrint('[FirebaseConfig] Firestore settings notice: $e');
      }

      // Configure App Check if enabled in environment
      if (EnvConfig.enableAppCheck && !kIsWeb) {
        try {
          await FirebaseAppCheck.instance.activate(
            androidProvider: kDebugMode
                ? AndroidProvider.debug
                : AndroidProvider.playIntegrity,
            appleProvider: kDebugMode
                ? AppleProvider.debug
                : AppleProvider.deviceCheck,
          );
        } catch (e) {
          debugPrint('[FirebaseConfig] App Check activation notice: $e');
        }
      }

      // Hook up Crashlytics fatal error catching for mobile platforms
      if (!kIsWeb) {
        try {
          FlutterError.onError = (errorDetails) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
          };
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };
        } catch (e) {
          debugPrint('[FirebaseConfig] Crashlytics hook notice: $e');
        }
      }
    } catch (e, stack) {
      _isInitialized = false;
      debugPrint(
        '[FirebaseConfig] Firebase initialization bypassed or running in fallback mode: $e\n$stack',
      );
    }
  }
}
