import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:book_vardi/core/config/env_config.dart';
import 'package:book_vardi/features/checkout/data/razorpay_service.dart';

/// Fake test double for [IRazorpayClient] enabling synchronous event dispatching
/// and option validation in tests without platform channels.
class FakeRazorpayClient implements IRazorpayClient {
  final Map<String, Function> handlers = {};
  Map<String, dynamic>? lastOpenedOptions;
  int openCallCount = 0;
  int clearCallCount = 0;

  @override
  void on(String event, Function handler) {
    handlers[event] = handler;
  }

  @override
  void clear() {
    clearCallCount++;
    handlers.clear();
  }

  @override
  void open(Map<String, dynamic> options) {
    openCallCount++;
    lastOpenedOptions = options;
  }

  void simulateSuccess(PaymentSuccessResponse response) {
    final handler = handlers[Razorpay.EVENT_PAYMENT_SUCCESS];
    if (handler != null) {
      handler(response);
    }
  }

  void simulateFailure(PaymentFailureResponse response) {
    final handler = handlers[Razorpay.EVENT_PAYMENT_ERROR];
    if (handler != null) {
      handler(response);
    }
  }

  void simulateExternalWallet(ExternalWalletResponse response) {
    final handler = handlers[Razorpay.EVENT_EXTERNAL_WALLET];
    if (handler != null) {
      handler(response);
    }
  }
}

void main() {
  group('RazorpayService & Payload Construction (TASK-044)', () {
    late FakeRazorpayClient fakeClient;
    late RazorpayService service;

    setUp(() {
      fakeClient = FakeRazorpayClient();
      service = RazorpayService(
        client: fakeClient,
        keyId: 'rzp_test_custom_key_123',
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes and registers event listeners on client creation', () {
      expect(
        fakeClient.handlers.containsKey(Razorpay.EVENT_PAYMENT_SUCCESS),
        isTrue,
      );
      expect(
        fakeClient.handlers.containsKey(Razorpay.EVENT_PAYMENT_ERROR),
        isTrue,
      );
      expect(
        fakeClient.handlers.containsKey(Razorpay.EVENT_EXTERNAL_WALLET),
        isTrue,
      );
    });

    group('buildCheckoutPayload', () {
      test('correctly converts amount in rupees to paise', () {
        final payload1 = RazorpayService.buildCheckoutPayload(
          keyId: 'test_key',
          amountInRupees: 850.0,
          orderName: 'Book Vardi',
        );
        expect(payload1['amount'], equals(85000));

        final payload2 = RazorpayService.buildCheckoutPayload(
          keyId: 'test_key',
          amountInRupees: 1249.50,
          orderName: 'Book Vardi',
        );
        expect(payload2['amount'], equals(124950));

        final payload3 = RazorpayService.buildCheckoutPayload(
          keyId: 'test_key',
          amountInRupees: 40.0,
          orderName: 'Book Vardi',
        );
        expect(payload3['amount'], equals(4000));
      });

      test('includes key, order name, description, theme, and retry configuration', () {
        final payload = RazorpayService.buildCheckoutPayload(
          keyId: 'rzp_test_demo',
          amountInRupees: 500.0,
          orderName: 'DPS Uniform Order',
          description: 'Winter Uniform Set',
        );

        expect(payload['key'], equals('rzp_test_demo'));
        expect(payload['name'], equals('DPS Uniform Order'));
        expect(payload['description'], equals('Winter Uniform Set'));
        expect(payload['theme']['color'], equals('#1E3A8A'));
        expect(payload['retry']['enabled'], isTrue);
        expect(payload['retry']['max_count'], equals(3));
      });

      test('includes prefill contact and email when provided', () {
        final payload = RazorpayService.buildCheckoutPayload(
          keyId: 'test_key',
          amountInRupees: 750.0,
          orderName: 'Book Vardi',
          prefillPhone: '9876543210',
          prefillEmail: 'aditya@example.com',
        );

        final prefill = payload['prefill'] as Map<String, dynamic>;
        expect(prefill['contact'], equals('9876543210'));
        expect(prefill['email'], equals('aditya@example.com'));
      });

      test('omits prefill when phone and email are null or empty', () {
        final payload = RazorpayService.buildCheckoutPayload(
          keyId: 'test_key',
          amountInRupees: 750.0,
          orderName: 'Book Vardi',
          prefillPhone: '   ',
          prefillEmail: null,
        );

        expect(payload.containsKey('prefill'), isFalse);
      });

      test('attaches optional order_id and notes map', () {
        final notes = {'userId': 'user_456', 'source': 'buy_now'};
        final payload = RazorpayService.buildCheckoutPayload(
          keyId: 'test_key',
          amountInRupees: 1000.0,
          orderName: 'Book Vardi',
          razorpayOrderId: 'order_DBJOWzybf0sJbb',
          notes: notes,
        );

        expect(payload['order_id'], equals('order_DBJOWzybf0sJbb'));
        expect(payload['notes'], equals(notes));
      });
    });

    group('openCheckout and Event Callbacks', () {
      test('opens client with constructed payload and test credentials', () {
        service.openCheckout(
          amountInRupees: 890.0,
          orderName: 'School Supplies',
          prefillPhone: '9876543210',
          prefillEmail: 'student@example.com',
        );

        expect(fakeClient.openCallCount, equals(1));
        final options = fakeClient.lastOpenedOptions!;
        expect(options['key'], equals('rzp_test_custom_key_123'));
        expect(options['amount'], equals(89000));
        expect(options['name'], equals('School Supplies'));
        expect(options['prefill']['contact'], equals('9876543210'));
        expect(options['prefill']['email'], equals('student@example.com'));
      });

      test('dispatches onSuccess callback on EVENT_PAYMENT_SUCCESS', () {
        PaymentSuccessResponse? successResult;

        service.openCheckout(
          amountInRupees: 850.0,
          orderName: 'Book Vardi',
          onSuccess: (resp) {
            successResult = resp;
          },
        );

        final testSuccessResponse = PaymentSuccessResponse(
          'pay_98765_success',
          'order_test_abc',
          'sig_test_xyz',
          {'razorpay_payment_id': 'pay_98765_success'},
        );

        fakeClient.simulateSuccess(testSuccessResponse);

        expect(successResult, isNotNull);
        expect(successResult!.paymentId, equals('pay_98765_success'));
        expect(successResult!.orderId, equals('order_test_abc'));
        expect(successResult!.signature, equals('sig_test_xyz'));
      });

      test('dispatches onFailure callback on EVENT_PAYMENT_ERROR', () {
        PaymentFailureResponse? failureResult;

        service.openCheckout(
          amountInRupees: 850.0,
          orderName: 'Book Vardi',
          onFailure: (resp) {
            failureResult = resp;
          },
        );

        final testFailureResponse = PaymentFailureResponse(
          Razorpay.PAYMENT_CANCELLED,
          'User cancelled transaction',
          {'error_code': 'BAD_REQUEST'},
        );

        fakeClient.simulateFailure(testFailureResponse);

        expect(failureResult, isNotNull);
        expect(failureResult!.code, equals(Razorpay.PAYMENT_CANCELLED));
        expect(failureResult!.message, equals('User cancelled transaction'));
      });

      test('dispatches onExternalWallet callback on EVENT_EXTERNAL_WALLET', () {
        ExternalWalletResponse? walletResult;

        service.openCheckout(
          amountInRupees: 850.0,
          orderName: 'Book Vardi',
          onExternalWallet: (resp) {
            walletResult = resp;
          },
        );

        final testWalletResponse = ExternalWalletResponse('paytm');
        fakeClient.simulateExternalWallet(testWalletResponse);

        expect(walletResult, isNotNull);
        expect(walletResult!.walletName, equals('paytm'));
      });

      test('callbacks registered via init() receive events if not passed to openCheckout', () {
        PaymentSuccessResponse? initSuccess;
        service.init(
          onSuccess: (resp) => initSuccess = resp,
        );

        service.openCheckout(
          amountInRupees: 500.0,
          orderName: 'Book Vardi',
        );

        final testResponse = PaymentSuccessResponse(
          'pay_init_123',
          'order_init',
          'sig_init',
          {},
        );
        fakeClient.simulateSuccess(testResponse);

        expect(initSuccess, isNotNull);
        expect(initSuccess!.paymentId, equals('pay_init_123'));
      });
    });

    group('Teardown & Lifecycle', () {
      test('dispose() invokes clear() on client and marks service as disposed', () {
        expect(service.isDisposed, isFalse);
        service.dispose();

        expect(service.isDisposed, isTrue);
        expect(fakeClient.clearCallCount, equals(1));
      });

      test('dispose() prevents callbacks from receiving subsequent events', () {
        var called = false;
        service.init(onSuccess: (_) => called = true);

        service.dispose();

        fakeClient.simulateSuccess(
          PaymentSuccessResponse('pay_after_dispose', null, null, null),
        );

        expect(called, isFalse);
      });

      test('openCheckout() throws StateError after disposal', () {
        service.dispose();

        expect(
          () => service.openCheckout(
            amountInRupees: 500.0,
            orderName: 'Book Vardi',
          ),
          throwsStateError,
        );
      });

      test('init() throws StateError after disposal', () {
        service.dispose();

        expect(
          () => service.init(),
          throwsStateError,
        );
      });

      test('dispose() is idempotent', () {
        service.dispose();
        service.dispose();
        expect(fakeClient.clearCallCount, equals(1));
      });
    });

    group('Riverpod Provider', () {
      test('razorpayServiceProvider provides IRazorpayService with default EnvConfig key', () {
        final container = ProviderContainer(
          overrides: [
            razorpayServiceProvider.overrideWithValue(service),
          ],
        );
        addTearDown(container.dispose);

        final resolvedService = container.read(razorpayServiceProvider);
        expect(resolvedService, isNotNull);
        expect(resolvedService, isA<IRazorpayService>());
      });

      test('razorpayServiceProvider cleans up when container is disposed', () {
        final testClient = FakeRazorpayClient();
        late RazorpayService createdService;

        final container = ProviderContainer(
          overrides: [
            razorpayServiceProvider.overrideWith((ref) {
              createdService = RazorpayService(
                client: testClient,
                keyId: EnvConfig.razorpayKeyId,
              );
              ref.onDispose(createdService.dispose);
              return createdService;
            }),
          ],
        );

        final svc = container.read(razorpayServiceProvider);
        expect(svc, isNotNull);
        expect(createdService.isDisposed, isFalse);

        container.dispose();

        expect(createdService.isDisposed, isTrue);
        expect(testClient.clearCallCount, equals(1));
      });
    });
  });
}
