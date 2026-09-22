import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/config/env_config.dart';

/// Abstract client interface wrapping the underlying native Razorpay SDK instance.
/// Enables mockability and isolated unit testing without platform channel dependency.
abstract class IRazorpayClient {
  void on(String event, Function handler);
  void clear();
  void open(Map<String, dynamic> options);
}

/// Default production adapter wrapping the official `razorpay_flutter` SDK instance.
class RazorpayClientWrapper implements IRazorpayClient {
  final Razorpay _razorpay;

  RazorpayClientWrapper([Razorpay? razorpay])
      : _razorpay = razorpay ?? Razorpay();

  @override
  void on(String event, Function handler) => _razorpay.on(event, handler);

  @override
  void clear() => _razorpay.clear();

  @override
  void open(Map<String, dynamic> options) => _razorpay.open(options);
}

/// Abstract contract for Book Vardi Razorpay payment gateway integration service.
abstract class IRazorpayService {
  /// Initializes or updates listener callbacks for checkout events.
  void init({
    void Function(PaymentSuccessResponse response)? onSuccess,
    void Function(PaymentFailureResponse response)? onFailure,
    void Function(ExternalWalletResponse response)? onExternalWallet,
  });

  /// Opens the native Razorpay payment sheet with preconfigured options.
  void openCheckout({
    required double amountInRupees,
    required String orderName,
    String? description,
    String? prefillPhone,
    String? prefillEmail,
    String? razorpayOrderId,
    Map<String, dynamic>? notes,
    void Function(PaymentSuccessResponse response)? onSuccess,
    void Function(PaymentFailureResponse response)? onFailure,
    void Function(ExternalWalletResponse response)? onExternalWallet,
  });

  /// Cleans up event listeners and tears down the native Razorpay instance.
  void dispose();
}

/// Concrete implementation of [IRazorpayService] managing Razorpay SDK lifecycle,
/// event dispatching, payload construction, and error containment.
class RazorpayService implements IRazorpayService {
  final IRazorpayClient _client;
  final String keyId;

  void Function(PaymentSuccessResponse response)? _onSuccess;
  void Function(PaymentFailureResponse response)? _onFailure;
  void Function(ExternalWalletResponse response)? _onExternalWallet;

  bool _isDisposed = false;
  bool _isInitialized = false;

  RazorpayService({
    IRazorpayClient? client,
    String? keyId,
  })  : _client = client ?? RazorpayClientWrapper(),
        keyId = keyId ?? EnvConfig.razorpayKeyId {
    _registerEventListeners();
  }

  void _registerEventListeners() {
    if (_isInitialized || _isDisposed) return;

    _client.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _client.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _client.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _isInitialized = true;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_isDisposed) return;
    debugPrint('[RazorpayService] Payment Success: ${response.paymentId}');
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_isDisposed) return;
    debugPrint('[RazorpayService] Payment Error: ${response.code} - ${response.message}');
    _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_isDisposed) return;
    debugPrint('[RazorpayService] External Wallet Selected: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  @override
  void init({
    void Function(PaymentSuccessResponse response)? onSuccess,
    void Function(PaymentFailureResponse response)? onFailure,
    void Function(ExternalWalletResponse response)? onExternalWallet,
  }) {
    if (_isDisposed) {
      throw StateError('Cannot call init() on a disposed RazorpayService.');
    }
    if (onSuccess != null) _onSuccess = onSuccess;
    if (onFailure != null) _onFailure = onFailure;
    if (onExternalWallet != null) _onExternalWallet = onExternalWallet;
  }

  /// Builds a validated Razorpay checkout options map from provided parameters.
  ///
  /// Converts rupees to paise (e.g. ₹850.00 -> 85000), sets brand theme,
  /// attaches optional Razorpay order id and customer prefill details.
  static Map<String, dynamic> buildCheckoutPayload({
    required String keyId,
    required double amountInRupees,
    required String orderName,
    String? description,
    String? prefillPhone,
    String? prefillEmail,
    String? razorpayOrderId,
    Map<String, dynamic>? notes,
    String? themeColorHex,
  }) {
    final amountInPaise = (amountInRupees * 100).round();

    final payload = <String, dynamic>{
      'key': keyId,
      'amount': amountInPaise,
      'name': orderName,
      'description': description ?? 'Order Payment',
      'theme': {
        'color': themeColorHex ?? '#1E3A8A', // AppColors.primaryNavy
      },
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
    };

    if (razorpayOrderId != null && razorpayOrderId.isNotEmpty) {
      payload['order_id'] = razorpayOrderId;
    }

    final prefill = <String, dynamic>{};
    if (prefillPhone != null && prefillPhone.trim().isNotEmpty) {
      prefill['contact'] = prefillPhone.trim();
    }
    if (prefillEmail != null && prefillEmail.trim().isNotEmpty) {
      prefill['email'] = prefillEmail.trim();
    }
    if (prefill.isNotEmpty) {
      payload['prefill'] = prefill;
    }

    if (notes != null && notes.isNotEmpty) {
      payload['notes'] = notes;
    }

    return payload;
  }

  @override
  void openCheckout({
    required double amountInRupees,
    required String orderName,
    String? description,
    String? prefillPhone,
    String? prefillEmail,
    String? razorpayOrderId,
    Map<String, dynamic>? notes,
    void Function(PaymentSuccessResponse response)? onSuccess,
    void Function(PaymentFailureResponse response)? onFailure,
    void Function(ExternalWalletResponse response)? onExternalWallet,
  }) {
    if (_isDisposed) {
      throw StateError('Cannot call openCheckout() on a disposed RazorpayService.');
    }

    if (onSuccess != null) _onSuccess = onSuccess;
    if (onFailure != null) _onFailure = onFailure;
    if (onExternalWallet != null) _onExternalWallet = onExternalWallet;

    final payload = buildCheckoutPayload(
      keyId: keyId,
      amountInRupees: amountInRupees,
      orderName: orderName,
      description: description,
      prefillPhone: prefillPhone,
      prefillEmail: prefillEmail,
      razorpayOrderId: razorpayOrderId,
      notes: notes,
    );

    _client.open(payload);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _onSuccess = null;
    _onFailure = null;
    _onExternalWallet = null;
    _client.clear();
  }

  @visibleForTesting
  bool get isDisposed => _isDisposed;
}

/// Riverpod provider delivering the application's [IRazorpayService] instance.
final razorpayServiceProvider = Provider<IRazorpayService>((ref) {
  final service = RazorpayService(
    keyId: EnvConfig.razorpayKeyId,
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
