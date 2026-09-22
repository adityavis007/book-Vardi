import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../catalog/domain/product_model.dart';
import '../../../orders/domain/order_model.dart';
import '../../../orders/domain/tracking_step_model.dart';
import '../../data/admin_repository.dart';

/// Provider for [IAdminRepository].
final adminRepositoryProvider = Provider<IAdminRepository>((ref) {
  return FirestoreAdminRepository();
});

/// Stream provider for admin dashboard metrics and KPI calculations.
final adminDashboardStatsProvider =
    StreamProvider.autoDispose<AdminDashboardStats>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.watchDashboardStats();
});

/// Stream provider for critical low stock inventory alerts.
final adminLowStockAlertsProvider =
    StreamProvider.autoDispose<List<ProductModel>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.watchLowStockProducts(threshold: 5);
});

/// Active status filter for admin fulfillment queue.
final adminOrdersFilterProvider = StateProvider<OrderStatus?>((ref) => null);

/// Stream provider for all customer orders in the fulfillment pipeline.
final adminOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(adminOrdersFilterProvider);
  return repo.watchAllOrders(statusFilter: filter);
});

/// Search query provider for Product Studio.
final adminProductSearchQueryProvider = StateProvider<String>((ref) => '');

/// Stream provider for all catalog products with optional search query.
final adminProductsProvider =
    StreamProvider.autoDispose<List<ProductModel>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  final query = ref.watch(adminProductSearchQueryProvider);
  return repo.watchAllProducts(searchQuery: query);
});
