import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/shared/widgets/shimmer_loading.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('ShimmerLoading Component Tests', () {
    testWidgets('renders ShimmerLoading with Shimmer component',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ShimmerLoading(
            child: ShimmerBox(width: 100, height: 20),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('ShimmerProductCard renders in grid column without overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SizedBox(
            width: 180,
            child: ShimmerProductCard(),
          ),
        ),
      );

      expect(find.byType(ShimmerProductCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ShimmerBanner renders without overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SizedBox(
            width: 360,
            child: ShimmerBanner(),
          ),
        ),
      );

      expect(find.byType(ShimmerBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ShimmerTile renders horizontal row without overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SizedBox(
            width: 320,
            child: ShimmerTile(),
          ),
        ),
      );

      expect(find.byType(ShimmerTile), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ShimmerCategoryItem renders circle without overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SizedBox(
            width: 80,
            child: ShimmerCategoryItem(),
          ),
        ),
      );

      expect(find.byType(ShimmerCategoryItem), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
