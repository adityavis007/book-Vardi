import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_config.dart';
import 'core/config/performance_budget.dart';
import 'core/network/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/user_model.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure bounded image cache memory limits to guarantee 60fps & prevent OOM
  PerformanceBudget.configureImageCache();

  // Initialize Firebase Core, Firestore offline cache, and App Check
  await FirebaseConfig.initialize();

  // Set top-level background messaging handler for FCM
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[FCM] Background handler setup notice: $e');
  }

  runApp(
    const ProviderScope(
      child: BookVardiApp(),
    ),
  );
}

/// Root Book Vardi Application
class BookVardiApp extends ConsumerStatefulWidget {
  const BookVardiApp({super.key});

  @override
  ConsumerState<BookVardiApp> createState() => _BookVardiAppState();
}

class _BookVardiAppState extends ConsumerState<BookVardiApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFcm();
    });
  }

  Future<void> _initializeFcm() async {
    final fcm = ref.read(fcmServiceProvider);
    await fcm.requestPermissions();

    fcm.setupMessageHandlers(
      onNavigateToOrder: (orderId) {
        ref.read(routerProvider).push('/order/${Uri.encodeComponent(orderId)}');
      },
      onForegroundMessage: (title, body, orderId) {
        debugPrint('[FCM Foreground] $title - $body (order: $orderId)');
      },
    );

    // Initial check for authenticated user
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await fcm.syncDeviceToken(currentUser.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Automatically sync / prune device token as authentication state changes
    ref.listen<UserModel?>(currentUserProvider, (previous, current) {
      if (current != null) {
        ref.read(fcmServiceProvider).syncDeviceToken(current.userId);
      } else if (previous != null) {
        ref.read(fcmServiceProvider).removeDeviceToken(previous.userId);
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Book Vardi',
      debugShowCheckedModeBanner: false,
      theme: BookVardiTheme.lightTheme,
      routerConfig: router,
    );
  }
}

