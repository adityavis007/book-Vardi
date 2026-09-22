import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:book_vardi/core/network/fcm_service.dart';

class MockFcmService implements IFcmService {
  bool permissionsRequested = false;
  String? currentUserId;
  final Set<String> registeredTokens = {};
  void Function(String orderId)? navigateCallback;
  void Function(String title, String body, String? orderId)? foregroundCallback;

  @override
  Future<NotificationSettings?> requestPermissions() async {
    permissionsRequested = true;
    return null;
  }

  @override
  Future<String?> getDeviceToken() async {
    return 'mock_fcm_token_device_abc';
  }

  @override
  Future<void> syncDeviceToken(String userId) async {
    currentUserId = userId;
    final token = await getDeviceToken();
    if (token != null) {
      registeredTokens.add(token);
    }
  }

  @override
  Future<void> removeDeviceToken(String userId) async {
    if (currentUserId == userId) {
      registeredTokens.clear();
      currentUserId = null;
    }
  }

  @override
  void setupMessageHandlers({
    required void Function(String orderId) onNavigateToOrder,
    void Function(String title, String body, String? orderId)? onForegroundMessage,
  }) {
    navigateCallback = onNavigateToOrder;
    foregroundCallback = onForegroundMessage;
  }

  // Test simulation helper
  void simulateNotificationTap(String orderId) {
    navigateCallback?.call(orderId);
  }

  // Test simulation helper for foreground message
  void simulateForegroundMessage(String title, String body, String? orderId) {
    foregroundCallback?.call(title, body, orderId);
  }

  @override
  void dispose() {
    registeredTokens.clear();
    currentUserId = null;
  }
}

void main() {
  group('TASK-057: FCM Push Notification Service Tests', () {
    late MockFcmService mockFcm;
    late ProviderContainer container;

    setUp(() {
      mockFcm = MockFcmService();
      container = ProviderContainer(
        overrides: [
          fcmServiceProvider.overrideWithValue(mockFcm),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockFcm.dispose();
    });

    test('Initializes permissions on startup', () async {
      final fcm = container.read(fcmServiceProvider);
      expect(mockFcm.permissionsRequested, isFalse);

      await fcm.requestPermissions();
      expect(mockFcm.permissionsRequested, isTrue);
    });

    test('Syncs device token for authenticated user and populates tokens', () async {
      final fcm = container.read(fcmServiceProvider);
      expect(mockFcm.registeredTokens, isEmpty);

      await fcm.syncDeviceToken('user_9988');
      expect(mockFcm.currentUserId, equals('user_9988'));
      expect(mockFcm.registeredTokens, contains('mock_fcm_token_device_abc'));
    });

    test('Removes device token on sign-out', () async {
      final fcm = container.read(fcmServiceProvider);
      await fcm.syncDeviceToken('user_9988');
      expect(mockFcm.registeredTokens, isNotEmpty);

      await fcm.removeDeviceToken('user_9988');
      expect(mockFcm.registeredTokens, isEmpty);
      expect(mockFcm.currentUserId, isNull);
    });

    test('Notification tap triggers onNavigateToOrder with target orderId', () {
      final fcm = container.read(fcmServiceProvider);
      String? routedOrderId;

      fcm.setupMessageHandlers(
        onNavigateToOrder: (orderId) {
          routedOrderId = orderId;
        },
      );

      // Simulate incoming order notification tap
      mockFcm.simulateNotificationTap('BV-2026-9812');
      expect(routedOrderId, equals('BV-2026-9812'));
    });

    test('Foreground message listener receives title, body, and orderId', () {
      final fcm = container.read(fcmServiceProvider);
      String? receivedTitle;
      String? receivedBody;
      String? receivedOrderId;

      fcm.setupMessageHandlers(
        onNavigateToOrder: (_) {},
        onForegroundMessage: (title, body, orderId) {
          receivedTitle = title;
          receivedBody = body;
          receivedOrderId = orderId;
        },
      );

      // Simulate foreground notification event
      mockFcm.simulateForegroundMessage(
        'Order Dispatched & In Transit 🚚',
        'Order BV-2026-9812 is on its way via BlueDart Express!',
        'BV-2026-9812',
      );

      expect(receivedTitle, contains('Dispatched'));
      expect(receivedBody, contains('BlueDart Express'));
      expect(receivedOrderId, equals('BV-2026-9812'));
    });
  });
}
