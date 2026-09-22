import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/config/performance_budget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-065: Performance Budget & Cache Tests', () {
    test('constants define 50MB and 100 image cache limits', () {
      expect(PerformanceBudget.maxImageCacheSizeBytes, equals(50 * 1024 * 1024));
      expect(PerformanceBudget.maxImageCacheCount, equals(100));
      expect(PerformanceBudget.targetFrameBudget.inMicroseconds, equals(16666));
    });

    test('configureImageCache sets bounds on global imageCache', () {
      PerformanceBudget.configureImageCache();
      final cache = PaintingBinding.instance.imageCache;

      expect(cache.maximumSizeBytes, equals(PerformanceBudget.maxImageCacheSizeBytes));
      expect(cache.maximumSize, equals(PerformanceBudget.maxImageCacheCount));
    });
  });
}
