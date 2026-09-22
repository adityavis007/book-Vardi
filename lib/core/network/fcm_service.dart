import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level background message handler required by Firebase Messaging for Android/iOS.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint('[FCM Background] Received message: ${message.messageId}, data: ${message.data}');
}

/// Abstract contract for FCM Push Notification operations.
abstract class IFcmService {
  Future<NotificationSettings?> requestPermissions();
  Future<String?> getDeviceToken();
  Future<void> syncDeviceToken(String userId);
  Future<void> removeDeviceToken(String userId);
  void setupMessageHandlers({
    required void Function(String orderId) onNavigateToOrder,
    void Function(String title, String body, String? orderId)? onForegroundMessage,
  });
  void dispose();
}

/// Real FCM Push Notification implementation coordinating tokens, permissions,
/// foreground banner notifications, and background deep-link navigation.
class FcmService implements IFcmService {
  final FirebaseMessaging? customMessaging;
  final FirebaseFirestore? customFirestore;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;

  String? _cachedToken;
  String? _activeUserId;

  FcmService({
    this.customMessaging,
    this.customFirestore,
  });

  FirebaseMessaging get messaging =>
      customMessaging ?? FirebaseMessaging.instance;

  FirebaseFirestore get firestore =>
      customFirestore ?? FirebaseFirestore.instance;

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Request notification permissions across iOS and Android 13+ (POST_NOTIFICATIONS)
  @override
  Future<NotificationSettings?> requestPermissions() async {
    if (!_isFirebaseAvailable) return null;

    try {
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // On iOS, enable foreground presentation for heads-up banners
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
      return settings;
    } catch (e) {
      debugPrint('[FCM] Error requesting permissions: $e');
      return null;
    }
  }

  /// Retrieves the active FCM registration token for this device
  @override
  Future<String?> getDeviceToken() async {
    if (!_isFirebaseAvailable) return null;

    try {
      _cachedToken = await messaging.getToken();
      return _cachedToken;
    } catch (e) {
      debugPrint('[FCM] Error fetching device token: $e');
      return null;
    }
  }

  /// Registers and stores device token under `users/{userId}` for targeted push notifications
  @override
  Future<void> syncDeviceToken(String userId) async {
    if (!_isFirebaseAvailable || userId.trim().isEmpty) return;

    _activeUserId = userId;

    try {
      final token = await getDeviceToken();
      if (token == null || token.isEmpty) return;

      final userDocRef = firestore.collection('users').doc(userId);

      // 1. Store in user document array
      await userDocRef.set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Also register in subcollection for device metadata tracking
      await userDocRef.collection('fcmTokens').doc(token).set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Listen to token rotations and re-sync
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) async {
        _cachedToken = newToken;
        if (_activeUserId != null) {
          await userDocRef.set({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });

      debugPrint('[FCM] Device token synced successfully for user $userId');
    } catch (e) {
      debugPrint('[FCM] Error syncing device token: $e');
    }
  }

  /// Removes current device token on user logout to prevent unauthenticated notification routing
  @override
  Future<void> removeDeviceToken(String userId) async {
    if (!_isFirebaseAvailable || userId.trim().isEmpty) return;

    try {
      final token = _cachedToken ?? await messaging.getToken();
      if (token == null || token.isEmpty) return;

      final userDocRef = firestore.collection('users').doc(userId);

      await userDocRef.update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });

      await userDocRef.collection('fcmTokens').doc(token).delete();
      _activeUserId = null;
      debugPrint('[FCM] Device token removed for user $userId');
    } catch (e) {
      debugPrint('[FCM] Error removing device token: $e');
    }
  }

  /// Configures foreground listeners, background resume taps, and terminated app launches
  @override
  void setupMessageHandlers({
    required void Function(String orderId) onNavigateToOrder,
    void Function(String title, String body, String? orderId)? onForegroundMessage,
  }) {
    if (!_isFirebaseAvailable) return;

    // 1. Foreground message handler
    _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final orderId = _extractOrderId(message);

      final title = notification?.title ?? message.data['title'] ?? 'Order Update';
      final body = notification?.body ?? message.data['body'] ?? 'Your order status has changed.';

      debugPrint('[FCM Foreground] $title: $body (orderId: $orderId)');
      onForegroundMessage?.call(title, body, orderId);
    });

    // 2. Background tap handler (app in background, user taps notification banner)
    _messageOpenedAppSubscription?.cancel();
    _messageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final orderId = _extractOrderId(message);
      debugPrint('[FCM onMessageOpenedApp] Notification tapped: orderId=$orderId');
      if (orderId != null && orderId.isNotEmpty) {
        onNavigateToOrder(orderId);
      }
    });

    // 3. Terminated launch handler (app was completely terminated, opened via notification)
    messaging.getInitialMessage().then((RemoteMessage? initialMessage) {
      if (initialMessage != null) {
        final orderId = _extractOrderId(initialMessage);
        debugPrint('[FCM getInitialMessage] Cold-start via notification: orderId=$orderId');
        if (orderId != null && orderId.isNotEmpty) {
          onNavigateToOrder(orderId);
        }
      }
    }).catchError((e) {
      debugPrint('[FCM] Error resolving initial message: $e');
    });
  }

  /// Helper to safely extract orderId from various payload conventions
  String? _extractOrderId(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('orderId') && data['orderId'] != null) {
      return data['orderId'].toString();
    }
    if (data.containsKey('order_id') && data['order_id'] != null) {
      return data['order_id'].toString();
    }
    if (data.containsKey('id') && data['id'] != null) {
      return data['id'].toString();
    }
    return null;
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
  }
}

/// Global provider for FCM Push Notification Service.
final fcmServiceProvider = Provider<IFcmService>((ref) {
  final service = FcmService();
  ref.onDispose(() => service.dispose());
  return service;
});
