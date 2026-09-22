import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../catalog/domain/product_model.dart';
import '../../orders/domain/order_model.dart';
import '../../orders/domain/tracking_step_model.dart';

/// Aggregated key performance metrics for the administrative dashboard.
@immutable
class AdminDashboardStats {
  final double totalGmv;
  final int totalOrdersCount;
  final int unfulfilledOrdersCount;
  final int totalProductsCount;
  final int lowStockProductsCount;

  const AdminDashboardStats({
    this.totalGmv = 0.0,
    this.totalOrdersCount = 0,
    this.unfulfilledOrdersCount = 0,
    this.totalProductsCount = 0,
    this.lowStockProductsCount = 0,
  });

  AdminDashboardStats copyWith({
    double? totalGmv,
    int? totalOrdersCount,
    int? unfulfilledOrdersCount,
    int? totalProductsCount,
    int? lowStockProductsCount,
  }) {
    return AdminDashboardStats(
      totalGmv: totalGmv ?? this.totalGmv,
      totalOrdersCount: totalOrdersCount ?? this.totalOrdersCount,
      unfulfilledOrdersCount: unfulfilledOrdersCount ?? this.unfulfilledOrdersCount,
      totalProductsCount: totalProductsCount ?? this.totalProductsCount,
      lowStockProductsCount: lowStockProductsCount ?? this.lowStockProductsCount,
    );
  }
}

/// Abstract contract for Book Vardi administrative operations.
abstract class IAdminRepository {
  Stream<AdminDashboardStats> watchDashboardStats();
  Stream<List<ProductModel>> watchLowStockProducts({int threshold = 5});
  Stream<List<ProductModel>> watchAllProducts({String? searchQuery});
  Stream<List<OrderModel>> watchAllOrders({OrderStatus? statusFilter});
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? carrierName,
    String? trackingNumber,
  });
  Future<String> saveProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
}

/// Firestore implementation for administrator portal operations.
class FirestoreAdminRepository implements IAdminRepository {
  final FirebaseFirestore _firestore;

  FirestoreAdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _firestore.collection('products');

  @override
  Stream<AdminDashboardStats> watchDashboardStats() {
    // Stream orders to calculate GMV and status counts
    return _ordersCol.snapshots().asyncMap((orderSnap) async {
      double gmv = 0.0;
      int unfulfilled = 0;

      for (final doc in orderSnap.docs) {
        final data = doc.data();
        final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
        final grandTotal = (pricing['grandTotal'] as num?)?.toDouble() ?? 0.0;
        gmv += grandTotal;

        final statusStr = data['orderStatus'] as String?;
        final status = OrderStatus.fromString(statusStr);
        if (status == OrderStatus.pending ||
            status == OrderStatus.confirmed ||
            status == OrderStatus.packed) {
          unfulfilled++;
        }
      }

      // Fetch products count and low stock count
      final productsSnap = await _productsCol.get();
      int lowStockCount = 0;

      for (final doc in productsSnap.docs) {
        final data = doc.data();
        final inStock = data['inStock'] as bool? ?? true;
        final totalStock = (data['totalStock'] as num?)?.toInt() ?? 0;

        if (!inStock || totalStock < 5) {
          lowStockCount++;
        }
      }

      return AdminDashboardStats(
        totalGmv: gmv,
        totalOrdersCount: orderSnap.docs.length,
        unfulfilledOrdersCount: unfulfilled,
        totalProductsCount: productsSnap.docs.length,
        lowStockProductsCount: lowStockCount,
      );
    });
  }

  @override
  Stream<List<ProductModel>> watchLowStockProducts({int threshold = 5}) {
    return _productsCol.snapshots().map((snap) {
      final products = <ProductModel>[];
      for (final doc in snap.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['productId'] = doc.id;
          final p = ProductModel.fromJson(data);
          final hasLowVariant = p.variants.any((v) => v.stock < threshold);
          if (!p.inStock || p.totalStock < threshold || hasLowVariant) {
            products.add(p);
          }
        } catch (e) {
          debugPrint('[AdminRepo] Parse error for low stock product ${doc.id}: $e');
        }
      }
      return products;
    });
  }

  @override
  Stream<List<ProductModel>> watchAllProducts({String? searchQuery}) {
    return _productsCol.snapshots().map((snap) {
      var list = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['productId'] = doc.id;
        return ProductModel.fromJson(data);
      }).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        list = list.where((p) {
          return p.name.toLowerCase().contains(q) ||
              (p.schoolName != null && p.schoolName!.toLowerCase().contains(q)) ||
              p.categoryId.toLowerCase().contains(q);
        }).toList();
      }
      return list;
    });
  }

  @override
  Stream<List<OrderModel>> watchAllOrders({OrderStatus? statusFilter}) {
    Query<Map<String, dynamic>> query = _ordersCol.orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('orderStatus', isEqualTo: statusFilter.toFirestoreValue());
    }

    return query.snapshots().map((snap) {
      return snap.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? carrierName,
    String? trackingNumber,
  }) async {
    final updates = <String, dynamic>{
      'orderStatus': newStatus.toFirestoreValue(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (carrierName != null || trackingNumber != null) {
      final meta = <String, dynamic>{
        if (carrierName != null) 'carrierName': carrierName,
        if (trackingNumber != null) 'trackingNumber': trackingNumber,
        'shippedAt': FieldValue.serverTimestamp(),
      };
      updates['trackingMetadata'] = meta;
    }

    await _ordersCol.doc(orderId).update(updates);
  }

  @override
  Future<String> saveProduct(ProductModel product) async {
    final docRef = product.productId.isEmpty
        ? _productsCol.doc()
        : _productsCol.doc(product.productId);

    final generatedId = docRef.id;

    // Recalculate totalStock from variants if present
    int computedTotalStock = product.totalStock;
    if (product.variants.isNotEmpty) {
      computedTotalStock = product.variants.fold(0, (acc, v) => acc + v.stock);
    }

    final data = product
        .copyWith(
          productId: generatedId,
          totalStock: computedTotalStock,
          inStock: computedTotalStock > 0,
        )
        .toJson();

    data['updatedAt'] = FieldValue.serverTimestamp();
    if (product.productId.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
    return generatedId;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _productsCol.doc(productId).delete();
  }
}
