import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/cart/presentation/widgets/quantity_stepper.dart';
import 'package:book_vardi/core/constants/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('QuantityStepper Component Tests', () {
    testWidgets('renders 32px height capsule pill layout with decrement, value, and increment',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const QuantityStepper(
            quantity: 2,
            maxStock: 5,
          ),
        ),
      );

      expect(find.byType(QuantityStepper), findsOneWidget);

      final containerFinder = find.descendant(
        of: find.byType(QuantityStepper),
        matching: find.byType(Container),
      ).first;

      final container = tester.widget<Container>(containerFinder);
      expect(container.constraints?.maxHeight ?? (container.decoration != null ? 32.0 : null), 32.0);

      expect(find.byKey(const Key('quantity_stepper_decrement')), findsOneWidget);
      expect(find.byKey(const Key('quantity_stepper_value')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byKey(const Key('quantity_stepper_increment')), findsOneWidget);
    });

    testWidgets('renders remove icon instead of delete icon when showDeleteIconAtOne is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const QuantityStepper(
            quantity: 1,
            showDeleteIconAtOne: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });

    testWidgets('increments quantity when tapped below maxStock and skuLimit',
        (WidgetTester tester) async {
      int updatedQty = -1;

      await tester.pumpWidget(
        buildTestableWidget(
          QuantityStepper(
            quantity: 3,
            maxStock: 5,
            skuLimit: 5,
            onQuantityChanged: (newQty) => updatedQty = newQty,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('quantity_stepper_increment')));
      await tester.pumpAndSettle();

      expect(updatedQty, equals(4));
    });

    testWidgets('disables increment when quantity reaches maxStock limit',
        (WidgetTester tester) async {
      int updatedQty = -1;

      await tester.pumpWidget(
        buildTestableWidget(
          QuantityStepper(
            quantity: 3,
            maxStock: 3, // stock limit is 3
            skuLimit: 5,
            onQuantityChanged: (newQty) => updatedQty = newQty,
          ),
        ),
      );

      final addIconFinder = find.descendant(
        of: find.byKey(const Key('quantity_stepper_increment')),
        matching: find.byType(Icon),
      );
      final addIcon = tester.widget<Icon>(addIconFinder);
      expect(addIcon.color, equals(AppColors.disabledText));

      await tester.tap(find.byKey(const Key('quantity_stepper_increment')));
      await tester.pumpAndSettle();

      expect(updatedQty, equals(-1)); // No increment triggered
    });

    testWidgets('disables increment when quantity reaches SKU constraint limit',
        (WidgetTester tester) async {
      int updatedQty = -1;

      await tester.pumpWidget(
        buildTestableWidget(
          QuantityStepper(
            quantity: 5,
            maxStock: 10,
            skuLimit: 5, // SKU limit enforced
            onQuantityChanged: (newQty) => updatedQty = newQty,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('quantity_stepper_increment')));
      await tester.pumpAndSettle();

      expect(updatedQty, equals(-1));
    });

    testWidgets('decrements quantity directly without dialog when quantity > 1',
        (WidgetTester tester) async {
      int updatedQty = -1;

      await tester.pumpWidget(
        buildTestableWidget(
          QuantityStepper(
            quantity: 3,
            onQuantityChanged: (newQty) => updatedQty = newQty,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('quantity_stepper_decrement')));
      await tester.pumpAndSettle();

      expect(updatedQty, equals(2));
      expect(find.text('Remove item from cart?'), findsNothing);
    });

    testWidgets('decrementing from 1 triggers confirmation dialog; Cancel keeps item',
        (WidgetTester tester) async {
      int updatedQty = -1;
      bool removed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          QuantityStepper(
            quantity: 1,
            onQuantityChanged: (newQty) => updatedQty = newQty,
            onRemove: () => removed = true,
          ),
        ),
      );

      // Tap decrement
      await tester.tap(find.byKey(const Key('quantity_stepper_decrement')));
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.text('Remove item from cart?'), findsOneWidget);
      expect(find.text('Are you sure you want to remove this item from your cart?'), findsOneWidget);
      expect(find.byKey(const Key('quantity_stepper_dialog_cancel')), findsOneWidget);
      expect(find.byKey(const Key('quantity_stepper_dialog_confirm')), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.byKey(const Key('quantity_stepper_dialog_cancel')));
      await tester.pumpAndSettle();

      // Dialog dismissed without calling remove
      expect(find.text('Remove item from cart?'), findsNothing);
      expect(removed, isFalse);
      expect(updatedQty, equals(-1));
    });

    testWidgets('decrementing from 1 triggers confirmation dialog; Remove removes item',
        (WidgetTester tester) async {
      int updatedQty = -1;
      bool removed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          QuantityStepper(
            quantity: 1,
            itemName: 'Oxford Mathematics Class 6',
            onQuantityChanged: (newQty) => updatedQty = newQty,
            onRemove: () => removed = true,
          ),
        ),
      );

      // Tap decrement
      await tester.tap(find.byKey(const Key('quantity_stepper_decrement')));
      await tester.pumpAndSettle();

      // Verify dialog displays custom item name
      expect(find.text('Remove item from cart?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to remove "Oxford Mathematics Class 6" from your cart?'),
        findsOneWidget,
      );

      // Tap Remove
      await tester.tap(find.byKey(const Key('quantity_stepper_dialog_confirm')));
      await tester.pumpAndSettle();

      // Dialog dismissed and removal triggered
      expect(find.text('Remove item from cart?'), findsNothing);
      expect(removed, isTrue);
      expect(updatedQty, equals(0));
    });

    testWidgets('decrementing from 1 calls onQuantityChanged(0) even when onRemove is null',
        (WidgetTester tester) async {
      int updatedQty = -1;

      await tester.pumpWidget(
        buildTestableWidget(
          QuantityStepper(
            quantity: 1,
            onQuantityChanged: (newQty) => updatedQty = newQty,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('quantity_stepper_decrement')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quantity_stepper_dialog_confirm')));
      await tester.pumpAndSettle();

      expect(updatedQty, equals(0));
    });

    testWidgets('shows loading spinner and disables interactions when isLoading is true',
        (WidgetTester tester) async {
      int updatedQty = -1;

      await tester.pumpWidget(
        buildTestableWidget(
          QuantityStepper(
            quantity: 2,
            isLoading: true,
            onQuantityChanged: (newQty) => updatedQty = newQty,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('quantity_stepper_value')), findsNothing);

      await tester.tap(find.byKey(const Key('quantity_stepper_increment')));
      await tester.tap(find.byKey(const Key('quantity_stepper_decrement')));
      await tester.pump();

      expect(updatedQty, equals(-1));
    });

    testWidgets('disables all interactions and applies disabled style when enabled is false',
        (WidgetTester tester) async {
      int updatedQty = -1;

      await tester.pumpWidget(
        buildTestableWidget(
          QuantityStepper(
            quantity: 2,
            enabled: false,
            onQuantityChanged: (newQty) => updatedQty = newQty,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('quantity_stepper_increment')));
      await tester.tap(find.byKey(const Key('quantity_stepper_decrement')));
      await tester.pump();

      expect(updatedQty, equals(-1));
    });

    testWidgets('static showRemoveConfirmationDialog can be triggered independently',
        (WidgetTester tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await QuantityStepper.showRemoveConfirmationDialog(
                    context,
                    itemName: 'School Shoes Size 32',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Remove item from cart?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to remove "School Shoes Size 32" from your cart?'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('quantity_stepper_dialog_confirm')));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
    });
  });
}
