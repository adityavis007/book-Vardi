import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/shared/widgets/app_scaffold_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableShell({
    int currentIndex = 0,
    ValueChanged<int>? onTabSelected,
    VoidCallback? onSearchPressed,
    VoidCallback? onCartPressed,
    VoidCallback? onWishlistPressed,
    int cartBadgeCount = 0,
  }) {
    return MaterialApp(
      home: AppScaffoldShell(
        currentIndex: currentIndex,
        onTabSelected: onTabSelected ?? (_) {},
        onSearchPressed: onSearchPressed,
        onCartPressed: onCartPressed,
        onWishlistPressed: onWishlistPressed,
        cartBadgeCount: cartBadgeCount,
        child: const Text('Viewport Content'),
      ),
    );
  }

  group('AppScaffoldShell Component Tests', () {
    testWidgets('renders all 5 bottom navigation tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableShell());

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Viewport Content'), findsOneWidget);
    });

    testWidgets('triggers onTabSelected with correct index when tab tapped',
        (WidgetTester tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        buildTestableShell(
          currentIndex: 0,
          onTabSelected: (idx) => selectedTab = idx,
        ),
      );

      // Tap Categories tab (index 1)
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals(1));

      // Tap Orders tab (index 3)
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(selectedTab, equals(3));
    });

    testWidgets('displays cart badge indicator when cartBadgeCount > 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableShell(cartBadgeCount: 3),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('triggers onSearchPressed callback when search icon tapped',
        (WidgetTester tester) async {
      bool searchTapped = false;

      await tester.pumpWidget(
        buildTestableShell(
          onSearchPressed: () => searchTapped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(searchTapped, isTrue);
    });

    testWidgets('triggers onWishlistPressed callback when wishlist icon tapped',
        (WidgetTester tester) async {
      bool wishlistTapped = false;

      await tester.pumpWidget(
        buildTestableShell(
          onWishlistPressed: () => wishlistTapped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      expect(wishlistTapped, isTrue);
    });

    testWidgets('renders top header ONLY on Home tab (currentIndex == 0) with announcement bar location',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableShell(currentIndex: 0));

      // Header elements present on Home tab
      final freeShippingFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Free Shipping Over'),
      );
      expect(freeShippingFinder, findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsWidgets);

      // Top green announcement bar retains Kamta, Lucknow location
      expect(find.text('Kamta, Lucknow'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('completely hides top header on all non-home tabs (Categories, Products, Orders, Account)',
        (WidgetTester tester) async {
      for (final tabIndex in [1, 2, 3, 4]) {
        await tester.pumpWidget(buildTestableShell(currentIndex: tabIndex));

        // Top header announcement bar and actions must NOT be rendered
        final freeShippingFinder = find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Free Shipping Over'),
        );
        expect(freeShippingFinder, findsNothing,
            reason: 'Announcement bar should be hidden on tab $tabIndex');
        expect(find.byIcon(Icons.search_rounded), findsNothing,
            reason: 'Header search icon should be hidden on tab $tabIndex');
        expect(find.text('Kamta, Lucknow'), findsNothing);
      }
    });

    testWidgets('zero overflow across narrow mobile viewports (320px, 360px, 375px)',
        (WidgetTester tester) async {
      final viewports = [
        const Size(320, 568), // iPhone SE 1st gen
        const Size(360, 640), // Standard Android compact
        const Size(375, 667), // iPhone 8 / SE 2nd gen
        const Size(390, 844), // iPhone 12/13/14
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestableShell(cartBadgeCount: 5));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Should render with 0 overflow on ${size.width}x${size.height}');
      }
    });
  });
}
