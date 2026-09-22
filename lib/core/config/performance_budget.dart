import 'package:flutter/painting.dart';

/// Manages runtime performance constraints, image caching budgets, and 60fps frame standards.
class PerformanceBudget {
  const PerformanceBudget._();

  /// Maximum in-memory image cache size in bytes (50 Megabytes)
  static const int maxImageCacheSizeBytes = 50 * 1024 * 1024;

  /// Maximum number of cached decoded images
  static const int maxImageCacheCount = 100;

  /// Target frame rendering budget: ~16.6 milliseconds for steady 60 FPS
  static const Duration targetFrameBudget = Duration(microseconds: 16666);

  /// Configures Flutter's global image cache with bounded limits to prevent OOM
  /// on memory-constrained devices during heavy school catalog browsing.
  static void configureImageCache() {
    try {
      final cache = PaintingBinding.instance.imageCache;
      cache.maximumSizeBytes = maxImageCacheSizeBytes;
      cache.maximumSize = maxImageCacheCount;
    } catch (_) {
      // Graceful fallback if invoked outside an active PaintingBinding
    }
  }
}
