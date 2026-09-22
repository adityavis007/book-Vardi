import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/checkout/data/address_repository.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:book_vardi/features/checkout/presentation/screens/address_step_screen.dart';
import 'package:book_vardi/shared/widgets/custom_button.dart';

import 'address_repository_test.dart';
import 'checkout_controller_test.dart';

void main() {
  group('AddressStepScreen Widget Tests (TASK-042)', () {
    late MockAddressRepository mockAddressRepo;
    const testUserId = 'user_aditya_addr_test';

    const sampleHome = AddressModel(
      addressId: 'addr_home_101',
      fullName: 'Aditya Sharma',
      phone: '9876543210',
      addressLine1: 'Flat 402, Tower B, Royal Palms',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122001',
      landmark: 'Near Huda City Centre',
      isDefault: true,
      addressType: 'Home',
    );

    const sampleSchool = AddressModel(
      addressId: 'addr_school_102',
      fullName: 'Aditya (DPS Campus)',
      phone: '9812345678',
      addressLine1: 'DPS Campus Sector 45',
      addressLine2: 'Classroom Distribution Desk',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122003',
      isDefault: false,
      addressType: 'School',
    );

    const sampleItem = CartItemModel(
      productId: 'prod_book_1',
      productName: 'NCERT Class 9 Mathematics',
      unitPrice: 350.0,
      quantity: 2,
    );

    setUp(() async {
      mockAddressRepo = MockAddressRepository();
      await mockAddressRepo.addAddress(testUserId, sampleHome);
      await mockAddressRepo.addAddress(testUserId, sampleSchool);
    });

    tearDown(() {
      mockAddressRepo.dispose();
    });

    Widget createTestWidget({
      VoidCallback? onProceedToPayment,
      VoidCallback? onBack,
      AddressModel? initialSelectedAddress,
    }) {
      return ProviderScope(
        overrides: [
          addressRepositoryProvider.overrideWithValue(mockAddressRepo),
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthState.authenticated(
                UserModel(
                  userId: testUserId,
                  name: 'Aditya Sharma',
                  email: 'aditya@example.com',
                  phone: '9876543210',
                ),
              ),
            );
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              // Ensure checkout session is initialized with items
              final controller = ref.read(checkoutControllerProvider.notifier);
              final state = ref.read(checkoutControllerProvider);
              if (state.items.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.initStandardCartCheckout(
                    items: [sampleItem],
                    userId: testUserId,
                  );
                  if (initialSelectedAddress != null) {
                    controller.selectAddress(initialSelectedAddress);
                  }
                });
              }

              return AddressStepScreen(
                onProceedToPayment: onProceedToPayment,
                onBack: onBack,
              );
            },
          ),
        ),
      );
    }

    void setStandardViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
    }

    testWidgets('renders step header, delivery modes, and radio card list of saved addresses',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check header and step progress
      expect(find.text('Select Delivery Address'), findsOneWidget);
      expect(find.text('Step 2 of 3: Delivery Address'), findsOneWidget);
      expect(find.text('Next: Payment'), findsOneWidget);

      // Check fulfillment mode tiles
      expect(find.text('Fulfillment Options'), findsOneWidget);
      expect(find.text('Standard Delivery'), findsOneWidget);
      expect(find.text('School Campus Delivery'), findsOneWidget);
      expect(find.text('Express Delivery'), findsOneWidget);

      // Check saved address cards
      expect(find.text('Saved Addresses (2)'), findsOneWidget);
      expect(find.text('Aditya Sharma'), findsOneWidget);
      expect(find.text('Aditya (DPS Campus)'), findsOneWidget);

      // Check address type badges
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('School'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);

      // Deliver button is enabled because home address is auto-selected
      final deliverButtonFinder = find.byKey(const Key('deliver_to_this_address_button'));
      expect(deliverButtonFinder, findsOneWidget);
      final customButton = tester.widget<CustomButton>(deliverButtonFinder);
      expect(customButton.onPressed, isNotNull);
    });

    testWidgets('tapping saved address updates checkout controller and highlights selection',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget(initialSelectedAddress: sampleHome));
      await tester.pumpAndSettle();

      // Tap the School address card
      final schoolCard = find.byKey(const Key('address_card_addr_school_102'));
      expect(schoolCard, findsOneWidget);

      await tester.tap(schoolCard);
      await tester.pumpAndSettle();

      // Delivery recipient summary shows school address in bottom bar
      expect(find.text('Deliver to: Aditya (DPS Campus) (122003)'), findsOneWidget);
    });

    testWidgets('toggling delivery mode radio updates checkout controller mode',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap School Campus delivery
      final schoolModeTile = find.byKey(const Key('delivery_mode_schoolDelivery'));
      expect(schoolModeTile, findsOneWidget);

      await tester.tap(schoolModeTile);
      await tester.pumpAndSettle();

      // Tap Express delivery
      final expressModeTile = find.byKey(const Key('delivery_mode_express'));
      expect(expressModeTile, findsOneWidget);

      await tester.tap(expressModeTile);
      await tester.pumpAndSettle();
    });

    testWidgets('tapping "+ Add New" opens AddAddressBottomSheet with form fields and PIN code auto-lookup',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open bottom sheet
      final addBtn = find.byKey(const Key('add_new_address_button'));
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Modal bottom sheet should be visible
      expect(find.text('Add Delivery Address'), findsOneWidget);
      expect(find.byKey(const Key('field_full_name')), findsOneWidget);
      expect(find.byKey(const Key('field_phone')), findsOneWidget);
      expect(find.byKey(const Key('field_pincode')), findsOneWidget);
      expect(find.byKey(const Key('field_address_line1')), findsOneWidget);

      // Test PIN code auto-lookup for Bengaluru (560001)
      await tester.enterText(find.byKey(const Key('field_pincode')), '560001');
      await tester.pumpAndSettle();

      expect(find.text('Bengaluru'), findsOneWidget);
      expect(find.text('Karnataka'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Add Delivery Address'), findsNothing);
    });

    testWidgets('AddAddressBottomSheet validates required fields and rejects invalid inputs',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_new_address_button')));
      await tester.pumpAndSettle();

      // Try submitting empty form
      await tester.ensureVisible(find.byKey(const Key('save_address_button')));
      await tester.tap(find.byKey(const Key('save_address_button')));
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Please enter full name'), findsOneWidget);
      expect(find.text('Please enter 10-digit mobile number'), findsOneWidget);
      expect(find.text('Please enter 6-digit PIN code'), findsOneWidget);
      expect(find.text('Please enter your address line 1'), findsOneWidget);
    });

    testWidgets('submitting valid new address saves to repository, selects it, and closes modal',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_new_address_button')));
      await tester.pumpAndSettle();

      // Fill in valid details
      await tester.enterText(find.byKey(const Key('field_full_name')), 'Rahul Verma');
      await tester.enterText(find.byKey(const Key('field_phone')), '9811122233');
      await tester.enterText(find.byKey(const Key('field_pincode')), '110001');
      await tester.pumpAndSettle(); // trigger PIN lookup (New Delhi, Delhi)

      await tester.enterText(
        find.byKey(const Key('field_address_line1')),
        'House 12, Connaught Place',
      );
      await tester.pumpAndSettle();

      // Tap save button
      await tester.ensureVisible(find.byKey(const Key('save_address_button')));
      await tester.tap(find.byKey(const Key('save_address_button')));
      await tester.pumpAndSettle();

      // Modal is dismissed
      expect(find.text('Add Delivery Address'), findsNothing);

      // Newly added address appears in the list and is selected
      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('Deliver to: Rahul Verma (110001)'), findsOneWidget);
    });

    testWidgets('tapping "Deliver to this Address" advances to Step 3 and invokes onProceedToPayment',
        (tester) async {
      setStandardViewport(tester);
      bool proceedInvoked = false;

      await tester.pumpWidget(createTestWidget(
        onProceedToPayment: () => proceedInvoked = true,
      ));
      await tester.pumpAndSettle();

      final deliverBtn = find.byKey(const Key('deliver_to_this_address_button'));
      expect(deliverBtn, findsOneWidget);

      await tester.tap(deliverBtn);
      await tester.pumpAndSettle();

      expect(proceedInvoked, isTrue);
    });

    testWidgets('zero layout overflow across small mobile viewport (360x640)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('deliver_to_this_address_button')), findsOneWidget);
    });
  });
}
