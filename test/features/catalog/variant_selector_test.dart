import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';
import 'package:book_vardi/features/catalog/presentation/widgets/variant_selector.dart';

void main() {
  const uniformVariants = [
    VariantModel(
      variantId: 'var_28',
      sku: 'UNIF-DPS-28',
      label: '28',
      price: 800.0,
      stock: 15,
    ),
    VariantModel(
      variantId: 'var_30',
      sku: 'UNIF-DPS-30',
      label: '30',
      price: 850.0,
      stock: 8,
    ),
    VariantModel(
      variantId: 'var_32',
      sku: 'UNIF-DPS-32',
      label: '32',
      price: 900.0,
      stock: 3, // Low stock (<= 5)
    ),
    VariantModel(
      variantId: 'var_34',
      sku: 'UNIF-DPS-34',
      label: '34',
      price: 950.0,
      stock: 0, // Out of stock
    ),
  ];

  const uniformProduct = ProductModel(
    productId: 'prod_uniform',
    name: 'DPS Regular Boys Uniform Shirt',
    description: 'Cotton blend regular school shirt',
    categoryId: 'cat_uniforms',
    schoolName: 'Delhi Public School',
    basePrice: 1050.0,
    discountPrice: 850.0,
    variants: uniformVariants,
  );

  const textbookVariants = [
    VariantModel(
      variantId: 'var_c1',
      sku: 'MATH-C1',
      label: 'Class 1',
      price: 250.0,
      stock: 20,
    ),
    VariantModel(
      variantId: 'var_c2',
      sku: 'MATH-C2',
      label: 'Class 2',
      price: 280.0,
      stock: 12,
    ),
    VariantModel(
      variantId: 'var_c3',
      sku: 'MATH-C3',
      label: 'Class 3',
      price: 310.0,
      stock: 0,
    ),
  ];

  const textbookProduct = ProductModel(
    productId: 'prod_textbook',
    name: 'NCERT Mathematics Textbook',
    description: 'Standard textbook for primary classes',
    categoryId: 'cat_books',
    basePrice: 300.0,
    variants: textbookVariants,
  );

  const shoeVariants = [
    VariantModel(
      variantId: 'var_s9',
      sku: 'SHOE-BATA-9C',
      label: '9C',
      price: 600.0,
      stock: 10,
    ),
    VariantModel(
      variantId: 'var_s11',
      sku: 'SHOE-BATA-11C',
      label: '11C',
      price: 650.0,
      stock: 5,
    ),
  ];

  const shoeProduct = ProductModel(
    productId: 'prod_shoe',
    name: 'Bata School Shoes Black',
    description: 'Formal school shoes',
    categoryId: 'cat_shoes',
    basePrice: 700.0,
    variants: shoeVariants,
  );

  Widget createSubject({
    required ProductModel product,
    required VariantModel? selectedVariant,
    required ValueChanged<VariantModel> onVariantSelected,
    VoidCallback? onSizeChartTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: VariantSelector(
            product: product,
            selectedVariant: selectedVariant,
            onVariantSelected: onVariantSelected,
            onSizeChartTap: onSizeChartTap,
          ),
        ),
      ),
    );
  }

  group('VariantSelector UI & Interaction Tests', () {
    testWidgets('renders all uniform size pills, labels, and stock info',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          product: uniformProduct,
          selectedVariant: uniformVariants[1], // 30 selected
          onVariantSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // Header: Select Size and Size Chart button
      expect(find.text('Select Size'), findsOneWidget);
      expect(find.byKey(const Key('size_chart_button')), findsOneWidget);

      // Pills
      expect(find.text('28'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('32'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);

      // Out indicator on 34
      expect(find.text('Out'), findsOneWidget);

      // Active variant details for 30 (SKU & stock)
      expect(find.text('SKU: UNIF-DPS-30'), findsOneWidget);
      expect(find.text('In Stock (8 units)'), findsOneWidget);
    });

    testWidgets('displays low stock indicator when stock <= 5', (tester) async {
      await tester.pumpWidget(
        createSubject(
          product: uniformProduct,
          selectedVariant: uniformVariants[2], // 32 selected (stock: 3)
          onVariantSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SKU: UNIF-DPS-32'), findsOneWidget);
      expect(find.text('Only 3 left in stock!'), findsOneWidget);
    });

    testWidgets('tapping in-stock variant invokes onVariantSelected',
        (tester) async {
      VariantModel? selected;

      await tester.pumpWidget(
        createSubject(
          product: uniformProduct,
          selectedVariant: uniformVariants[0], // 28 selected
          onVariantSelected: (v) => selected = v,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 32
      await tester.tap(find.byKey(const Key('variant_pill_var_32')));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected?.variantId, equals('var_32'));
      expect(selected?.label, equals('32'));
    });

    testWidgets(
        'prevents selecting out-of-stock items (tap does not trigger callback)',
        (tester) async {
      VariantModel? selected;

      await tester.pumpWidget(
        createSubject(
          product: uniformProduct,
          selectedVariant: uniformVariants[0], // 28 selected
          onVariantSelected: (v) => selected = v,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 34 (stock: 0)
      await tester.tap(find.byKey(const Key('variant_pill_var_34')));
      await tester.pumpAndSettle();

      // Callback should NOT have been invoked
      expect(selected, isNull);
    });

    testWidgets('renders Select Class header without Size Chart link for textbooks',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          product: textbookProduct,
          selectedVariant: textbookVariants[0],
          onVariantSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Class'), findsOneWidget);
      expect(find.byKey(const Key('size_chart_button')), findsNothing);

      expect(find.text('Class 1'), findsOneWidget);
      expect(find.text('Class 2'), findsOneWidget);
      expect(find.text('Class 3'), findsOneWidget);
    });

    testWidgets('tapping Size Chart opens SizeChartModal and closes cleanly',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          product: uniformProduct,
          selectedVariant: uniformVariants[0],
          onVariantSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // Tap Size Chart button
      await tester.tap(find.byKey(const Key('size_chart_button')));
      await tester.pumpAndSettle();

      // Verify modal opened
      expect(find.byKey(const Key('size_chart_modal')), findsOneWidget);
      expect(find.text('Uniform Sizing Chart'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Waist'), findsOneWidget);
      expect(find.text('Length'), findsOneWidget);
      expect(find.text('Age Guide'), findsOneWidget);
      expect(
        find.textContaining('For growing students, selecting one size larger is recommended'),
        findsOneWidget,
      );

      // Close modal
      await tester.tap(find.byKey(const Key('size_chart_close_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('size_chart_modal')), findsNothing);
    });

    testWidgets('opens Footwear Size Guide for shoe products', (tester) async {
      await tester.pumpWidget(
        createSubject(
          product: shoeProduct,
          selectedVariant: shoeVariants[0],
          onVariantSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('size_chart_button')));
      await tester.pumpAndSettle();

      expect(find.text('Footwear Size Guide'), findsOneWidget);
      expect(find.text('UK Size'), findsOneWidget);
      expect(find.text('Foot (cm)'), findsOneWidget);
    });

    testWidgets('triggers custom onSizeChartTap callback when provided',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createSubject(
          product: uniformProduct,
          selectedVariant: uniformVariants[0],
          onVariantSelected: (_) {},
          onSizeChartTap: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('size_chart_button')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      // Custom handler should not open default bottom sheet
      expect(find.byKey(const Key('size_chart_modal')), findsNothing);
    });
  });

  group('VariantSelector Responsive Viewport Tests', () {
    const viewports = [
      Size(360, 640),
      Size(375, 667),
      Size(390, 844),
      Size(412, 915),
      Size(428, 926),
    ];

    for (final size in viewports) {
      testWidgets('renders with 0 overflow on ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createSubject(
            product: uniformProduct,
            selectedVariant: uniformVariants[0],
            onVariantSelected: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Select Size'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
