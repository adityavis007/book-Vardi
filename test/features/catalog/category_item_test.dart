import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/core/constants/app_colors.dart';
import 'package:book_vardi/features/catalog/domain/category_model.dart';
import 'package:book_vardi/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:book_vardi/features/catalog/presentation/widgets/category_item.dart';
import 'package:book_vardi/shared/widgets/shimmer_loading.dart';

void main() {
  group('CategoryItem Component Tests', () {
    testWidgets('renders 60x60 circular container with light blue bg and 1px border when inactive',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryItem(
              label: 'Uniforms',
              icon: Icons.checkroom_outlined,
              isSelected: false,
            ),
          ),
        ),
      );

      // Verify label text
      final labelFinder = find.text('Uniforms');
      expect(labelFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(labelFinder);
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.style?.fontSize, 12.0);
      expect(textWidget.style?.color, AppColors.textDark);
      expect(textWidget.style?.fontWeight, FontWeight.w500);

      // Verify AnimatedContainer has 60x60 size, circle shape, and colors
      final containerFinder = find.byType(AnimatedContainer);
      expect(containerFinder, findsOneWidget);

      final animatedContainer =
          tester.widget<AnimatedContainer>(containerFinder);
      final decoration = animatedContainer.decoration as BoxDecoration;

      expect(animatedContainer.constraints?.maxWidth, 60.0);
      expect(animatedContainer.constraints?.maxHeight, 60.0);
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, AppColors.categoryPillBg); // #EFF6FF

      final border = decoration.border as Border;
      expect(border.top.color, AppColors.categoryPillBorder); // #DBEAFE
      expect(border.top.width, 1.0);
    });

    testWidgets('renders active selection indicator with navy bg and 2px border when isSelected is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryItem(
              label: 'Textbooks',
              icon: Icons.menu_book_outlined,
              isSelected: true,
            ),
          ),
        ),
      );

      final animatedContainer =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = animatedContainer.decoration as BoxDecoration;

      // Active state styling
      expect(decoration.color, AppColors.primaryNavy);
      final border = decoration.border as Border;
      expect(border.top.color, AppColors.primaryNavy);
      expect(border.top.width, 2.0);

      // Verify label active text color and bold weight
      final textWidget = tester.widget<Text>(find.text('Textbooks'));
      expect(textWidget.style?.color, AppColors.primaryNavy);
      expect(textWidget.style?.fontWeight, FontWeight.w700);

      // Verify icon color is white
      final iconFinder = find.byIcon(Icons.menu_book_outlined);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, Colors.white);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryItem(
              label: 'Footwear',
              icon: Icons.snowshoeing_outlined,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Footwear'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders fallback icon if iconUrl is empty and icon is null',
        (tester) async {
      const category = CategoryModel(
        categoryId: 'cat_stationery',
        name: 'Stationery',
        iconUrl: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryItem(
              category: category,
            ),
          ),
        ),
      );

      expect(find.text('Stationery'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });
  });

  group('CategoryQuickRail Component Tests', () {
    final sampleCategories = [
      const CategoryModel(
        categoryId: 'cat_uniforms',
        name: 'Uniforms',
        iconUrl: 'uniforms.png',
        displayOrder: 1,
      ),
      const CategoryModel(
        categoryId: 'cat_books',
        name: 'Books',
        iconUrl: 'books.png',
        displayOrder: 2,
      ),
      const CategoryModel(
        categoryId: 'cat_stationery',
        name: 'Stationery',
        iconUrl: 'stationery.png',
        displayOrder: 3,
      ),
    ];

    testWidgets('renders horizontal scroll view with BouncingScrollPhysics',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategoryQuickRail(
                categories: sampleCategories,
                showAllOption: true,
              ),
            ),
          ),
        ),
      );

      final scrollFinder = find.byType(SingleChildScrollView);
      expect(scrollFinder, findsOneWidget);

      final scrollView = tester.widget<SingleChildScrollView>(scrollFinder);
      expect(scrollView.scrollDirection, Axis.horizontal);
      expect(scrollView.physics, isA<BouncingScrollPhysics>());

      // Verifies "All" and the 3 categories are present
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Uniforms'), findsOneWidget);
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Stationery'), findsOneWidget);
    });

    testWidgets('selects category and invokes onCategorySelected callback',
        (tester) async {
      CategoryModel? selectedCat;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CategoryQuickRail(
                categories: sampleCategories,
                selectedCategoryId: 'cat_books',
                onCategorySelected: (cat) => selectedCat = cat,
              ),
            ),
          ),
        ),
      );

      // Verify books is selected
      final booksItemFinder = find.byKey(const ValueKey('category_item_cat_books'));
      expect(booksItemFinder, findsOneWidget);

      // Tap on Uniforms
      await tester.tap(find.text('Uniforms'));
      await tester.pump();

      expect(selectedCat, isNotNull);
      expect(selectedCat!.categoryId, 'cat_uniforms');
    });

    testWidgets('interacts with catalogFilterProvider state when categories not passed',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) async => sampleCategories),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CategoryQuickRail(
                showAllOption: true,
              ),
            ),
          ),
        ),
      );

      // Initial state is loading or immediately data
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Uniforms'), findsOneWidget);

      // Tapping Uniforms updates catalogFilterProvider
      await tester.tap(find.text('Uniforms'));
      await tester.pumpAndSettle();

      expect(container.read(catalogFilterProvider).categoryId, 'cat_uniforms');

      // Tapping Uniforms again toggles it off (clears category)
      await tester.tap(find.text('Uniforms'));
      await tester.pumpAndSettle();

      expect(container.read(catalogFilterProvider).categoryId, isNull);

      // Tapping Books sets books
      await tester.tap(find.text('Books'));
      await tester.pumpAndSettle();
      expect(container.read(catalogFilterProvider).categoryId, 'cat_books');

      // Tapping All clears category
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(container.read(catalogFilterProvider).categoryId, isNull);
    });

    testWidgets('renders ShimmerCategoryItem while categoriesProvider is loading',
        (tester) async {
      final completer = Completer<List<CategoryModel>>();
      final container = ProviderContainer(
        overrides: [
          categoriesProvider.overrideWith((ref) => completer.future),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CategoryQuickRail(),
            ),
          ),
        ),
      );

      // Pump 1 frame to display loading state
      await tester.pump();

      // Shimmer items should be present
      expect(find.byType(ShimmerCategoryItem), findsWidgets);

      // Complete future and settle to avoid dangling async operations
      completer.complete(sampleCategories);
      await tester.pumpAndSettle();
    });
  });
}
