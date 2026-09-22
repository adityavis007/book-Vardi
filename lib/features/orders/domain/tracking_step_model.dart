import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Fulfillment and logistics lifecycle status for customer orders.
enum OrderStatus {
  pending,
  confirmed,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled;

  /// Parses raw Firestore status string to [OrderStatus].
  static OrderStatus fromString(String? value) {
    if (value == null) return OrderStatus.pending;
    switch (value.trim().toUpperCase()) {
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PACKED':
        return OrderStatus.packed;
      case 'SHIPPED':
        return OrderStatus.shipped;
      case 'OUT_FOR_DELIVERY':
      case 'OUT FOR DELIVERY':
        return OrderStatus.outForDelivery;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'PENDING':
      default:
        return OrderStatus.pending;
    }
  }

  /// Serializes [OrderStatus] to Firestore string representation.
  String toFirestoreValue() {
    switch (this) {
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.packed:
        return 'PACKED';
      case OrderStatus.shipped:
        return 'SHIPPED';
      case OrderStatus.outForDelivery:
        return 'OUT_FOR_DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      case OrderStatus.pending:
        return 'PENDING';
    }
  }

  /// Human-readable customer-facing display name.
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Payment Pending';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.packed:
        return 'Packed & Ready';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Progression step index (0 to 4) for milestone timeline calculation.
  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:
        return -1;
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.packed:
        return 1;
      case OrderStatus.shipped:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -2;
    }
  }

  /// Text color for status badge chips.
  Color get badgeTextColor {
    switch (this) {
      case OrderStatus.delivered:
        return const Color(0xFF0F5132); // Deep Green
      case OrderStatus.cancelled:
        return AppColors.destructiveRed;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return const Color(0xFF055160); // Cyan / Teal
      case OrderStatus.confirmed:
      case OrderStatus.packed:
        return AppColors.primaryNavy;
      case OrderStatus.pending:
        return const Color(0xFF664D03); // Amber
    }
  }

  /// Background color for status badge chips.
  Color get badgeBgColor {
    switch (this) {
      case OrderStatus.delivered:
        return const Color(0xFFD1E7DD);
      case OrderStatus.cancelled:
        return const Color(0xFFF8D7DA);
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return const Color(0xFFCFF4FC);
      case OrderStatus.confirmed:
      case OrderStatus.packed:
        return AppColors.mintPillBg;
      case OrderStatus.pending:
        return const Color(0xFFFFF3CD);
    }
  }
}

/// Metadata holding courier partner and live tracking credentials.
@immutable
class TrackingMetadata {
  final String? carrierName;
  final String? trackingNumber;
  final String? trackingUrl;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  const TrackingMetadata({
    this.carrierName,
    this.trackingNumber,
    this.trackingUrl,
    this.shippedAt,
    this.deliveredAt,
  });

  factory TrackingMetadata.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TrackingMetadata();
    return TrackingMetadata(
      carrierName: map['carrierName'] as String?,
      trackingNumber: map['trackingNumber'] as String?,
      trackingUrl: map['trackingUrl'] as String?,
      shippedAt: map['shippedAt'] != null
          ? DateTime.tryParse(map['shippedAt'].toString())
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.tryParse(map['deliveredAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carrierName': carrierName,
      'trackingNumber': trackingNumber,
      'trackingUrl': trackingUrl,
      'shippedAt': shippedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }
}

/// A milestone step along the vertical order tracking timeline.
@immutable
class TrackingStepModel {
  final OrderStatus status;
  final String title;
  final String description;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;

  const TrackingStepModel({
    required this.status,
    required this.title,
    required this.description,
    this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
  });
}
