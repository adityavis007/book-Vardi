import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/catalog/data/catalog_repository.dart';
import 'package:book_vardi/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:book_vardi/features/catalog/presentation/widgets/filter_modal.dart';

Widget createFilterTestApp({
  required ProviderContainer container,
  CatalogFilterState? initialState,
  ValueChanged<CatalogFilterState>? onApply,
  VoidCallback? onReset,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => FilterModal.show(
                context,
                initialState: initialState,
                onApply: onApply,
                onReset: onReset,
              ),
              child: const Text('Open Filters'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('FilterModal 1:1 Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('renders all 5 website sections and default action bar',
        (tester) async {
      await tester.pumpWidget(
        createFilterTestApp(container: container),
      );

      // Open modal
      await tester.tap(find.text('Open Filters'));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Filters & Sorting'), findsOneWidget);
      expect(find.byKey(const Key('filter_close_icon_btn')), findsOneWidget);

      // 1. SORT BY
      expect(find.text('SORT BY'), findsOneWidget);
      expect(find.byKey(const Key('sort_chip_featured')), findsOneWidget);
      expect(find.byKey(const Key('sort_chip_priceLowToHigh')), findsOneWidget);
      expect(find.byKey(const Key('sort_chip_priceHighToLow')), findsOneWidget);
      expect(find.byKey(const Key('sort_chip_topRated')), findsOneWidget);
      expect(find.byKey(const Key('sort_chip_biggestDiscount')), findsOneWidget);

      // 2. PRICE RANGE
      expect(find.text('PRICE RANGE'), findsOneWidget);
      expect(find.byKey(const Key('price_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('price_chip_under250')), findsOneWidget);
      expect(find.byKey(const Key('price_chip_250to500')), findsOneWidget);
      expect(find.byKey(const Key('price_chip_above500')), findsOneWidget);

      // 3. RATING
      expect(find.text('RATING'), findsOneWidget);
      expect(find.byKey(const Key('rating_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('rating_chip_4plus')), findsOneWidget);
      expect(find.byKey(const Key('rating_chip_3plus')), findsOneWidget);

      // 4. AVAILABILITY
      expect(find.text('AVAILABILITY'), findsOneWidget);
      expect(find.byKey(const Key('availability_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('availability_chip_inStock')), findsOneWidget);
      expect(find.byKey(const Key('availability_chip_outOfStock')), findsOneWidget);

      // 5. SPECIAL OFFERS
      expect(find.text('SPECIAL OFFERS'), findsOneWidget);
      expect(find.byKey(const Key('special_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('special_chip_sale')), findsOneWidget);

      // Bottom Action Bar
      expect(find.byKey(const Key('filter_clear_all_btn')), findsOneWidget);
      expect(find.byKey(const Key('filter_apply_btn')), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget); // 0 active filters initially
    });

    testWidgets('dynamically updates Apply count when non-default options are selected',
        (tester) async {
      await tester.pumpWidget(
        createFilterTestApp(container: container),
      );

      await tester.tap(find.text('Open Filters'));
      await tester.pumpAndSettle();

      // Initial: 0 active filters
      expect(find.text('Apply'), findsOneWidget);

      // 1. Select Under ₹250 -> 1 active filter
      await tester.tap(find.byKey(const Key('price_chip_under250')));
      await tester.pumpAndSettle();
      expect(find.text('Apply (1)'), findsOneWidget);

      // 2. Select 4+ Stars -> 2 active filters
      await tester.tap(find.byKey(const Key('rating_chip_4plus')));
      await tester.pumpAndSettle();
      expect(find.text('Apply (2)'), findsOneWidget);

      // 3. Select Sale Items -> 3 active filters (matching website screenshot!)
      await tester.ensureVisible(find.byKey(const Key('special_chip_sale')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('special_chip_sale')));
      await tester.pumpAndSettle();
      expect(find.text('Apply (3)'), findsOneWidget);

      // Tapping Clear All resets counter back to 'Apply'
      await tester.tap(find.byKey(const Key('filter_clear_all_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('applying selected sort and price filters updates provider state',
        (tester) async {
      await tester.pumpWidget(
        createFilterTestApp(container: container),
      );

      await tester.tap(find.text('Open Filters'));
      await tester.pumpAndSettle();

      // Select Price: Low to High
      await tester.tap(find.byKey(const Key('sort_chip_priceLowToHigh')));
      await tester.pumpAndSettle();

      // Select ₹250 - ₹500
      await tester.tap(find.byKey(const Key('price_chip_250to500')));
      await tester.pumpAndSettle();

      // Tap Apply (2)
      await tester.tap(find.byKey(const Key('filter_apply_btn')));
      await tester.pumpAndSettle();

      // Modal should be dismissed
      expect(find.byType(FilterModal), findsNothing);

      // Provider state should be updated
      final filterState = container.read(catalogFilterProvider);
      expect(filterState.sort, SortOption.priceLowToHigh);
      expect(filterState.minPrice, 250.0);
      expect(filterState.maxPrice, 500.0);
    });

    testWidgets('renders cleanly in wide-screen side sheet mode without overflow',
        (tester) async {
      // Set wide screen dimensions (e.g. tablet / desktop 1024x768)
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createFilterTestApp(container: container),
      );

      await tester.tap(find.text('Open Filters'));
      await tester.pumpAndSettle();

      // Header and sections render cleanly
      expect(find.text('Filters & Sorting'), findsOneWidget);
      expect(find.byKey(const Key('filter_apply_btn')), findsOneWidget);

      // Close modal
      await tester.tap(find.byKey(const Key('filter_close_icon_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(FilterModal), findsNothing);
    });
  });
}
