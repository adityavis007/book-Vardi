/// Application environment configuration reading variables passed via `--dart-define`.
enum Environment {
  development,
  production,
}

class EnvConfig {
  const EnvConfig._();

  static const String _envString = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Razorpay Public Key ID used on client checkout
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_bookvardi_mock',
  );

  /// Toggle for Firebase App Check device attestation
  static const bool enableAppCheck = bool.fromEnvironment(
    'ENABLE_APP_CHECK',
    defaultValue: false,
  );

  /// Base API URL for serverless webhook or backend communication
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.bookvardi.com',
  );

  /// Current active environment
  static Environment get environment {
    return _envString.trim().toLowerCase() == 'production'
        ? Environment.production
        : Environment.development;
  }

  static bool get isProduction => environment == Environment.production;
  static bool get isDevelopment => environment == Environment.development;
}
