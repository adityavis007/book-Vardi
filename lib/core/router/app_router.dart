import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/edit_profile_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/catalog/presentation/screens/all_products_screen.dart';
import '../../features/catalog/presentation/screens/categories_screen.dart';
import '../../features/catalog/presentation/screens/home_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/catalog/presentation/screens/search_screen.dart';
import '../../features/cart/presentation/controllers/cart_controller.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/cart/presentation/screens/wishlist_screen.dart';
import '../../features/checkout/domain/order_model.dart' as checkout;
import '../../features/checkout/presentation/screens/order_confirmation_screen.dart';
import '../../features/orders/presentation/screens/order_history_screen.dart';
import '../../features/orders/presentation/screens/order_tracking_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_product_form.dart';
import '../../features/admin/presentation/screens/admin_products_screen.dart';
import '../../features/location/presentation/controllers/location_controller.dart';
import '../../features/location/presentation/widgets/location_modal_bottom_sheet.dart';
import '../../features/coupons/presentation/screens/coupons_screen.dart';
import '../guards/admin_guard.dart';
import '../../shared/widgets/app_scaffold_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeNav');
final categoryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'catNav');
final productsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'productsNav');
final ordersNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'ordersNav');
final profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profileNav');

/// Central GoRouter configuration providing stateful shell navigation for tabs.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) => adminRouteRedirect(context, state, ref),
    routes: [
      // Stateful Shell with IndexedStack preserving tab state
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Consumer(
            builder: (context, ref, _) {
              final cartBadgeCount = ref.watch(cartBadgeCountProvider);
              final selectedLocation = ref.watch(selectedLocationProvider);
              return AppScaffoldShell(
                currentIndex: navigationShell.currentIndex,
                cartBadgeCount: cartBadgeCount,
                selectedLocationName: selectedLocation.name,
                onLocationPressed: () {
                  LocationModalBottomSheet.show(context);
                },
                onTabSelected: (index) {
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
                onSearchPressed: () => context.push('/search'),
                onCartPressed: () => context.push('/cart'),
                onWishlistPressed: () => context.push('/wishlist'),
                child: navigationShell,
              );
            },
          );
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Categories
          StatefulShellBranch(
            navigatorKey: categoryNavigatorKey,
            routes: [
              GoRoute(
                path: '/category',
                name: 'category',
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),
          // Branch 2: Products
          StatefulShellBranch(
            navigatorKey: productsNavigatorKey,
            routes: [
              GoRoute(
                path: '/products',
                name: 'products',
                builder: (context, state) => const AllProductsScreen(),
              ),
            ],
          ),
          // Branch 3: Orders
          StatefulShellBranch(
            navigatorKey: ordersNavigatorKey,
            routes: [
              GoRoute(
                path: '/orders',
                name: 'orders',
                builder: (context, state) => const OrderHistoryScreen(),
              ),
            ],
          ),
          // Branch 4: Profile / Account
          StatefulShellBranch(
            navigatorKey: profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Detail and Transactional Full-Screen Routes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/product/:id',
        name: 'productDetail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Checkout Stepper'))),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/order/:id',
        name: 'orderTracking',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderTrackingScreen(orderId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/order-confirmation/:id',
        name: 'orderConfirmation',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final order = state.extra as checkout.OrderModel?;
          return OrderConfirmationScreen(
            orderId: id,
            order: order,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/wishlist',
        name: 'wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/coupons',
        name: 'coupons',
        builder: (context, state) => const CouponsScreen(),
      ),

      // Administrative Operations Portal Routes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin/products',
        name: 'adminProducts',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin/products/new',
        name: 'adminProductCreate',
        builder: (context, state) => const AdminProductFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin/products/edit/:id',
        name: 'adminProductEdit',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return AdminProductFormScreen(productId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin/orders',
        name: 'adminOrders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin/access-denied',
        name: 'adminAccessDenied',
        builder: (context, state) => const AdminAccessDeniedScreen(),
      ),
    ],
  );
});
