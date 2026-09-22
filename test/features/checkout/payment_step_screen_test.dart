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
import 'package:book_vardi/features/checkout/presentation/screens/payment_step_screen.dart';

import 'address_repository_test.dart';
import 'checkout_controller_test.dart';

void main() {
  group('PaymentStepScreen Widget Tests (TASK-043)', () {
    late MockAddressRepository mockAddressRepo;
    const testUserId = 'user_aditya_payment_test';

    const sampleAddress = AddressModel(
      addressId: 'addr_payment_1',
      fullName: 'Aditya Sharma',
      phone: '9876543210',
      addressLine1: 'Flat 402, Royal Palms',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122001',
      isDefault: true,
      addressType: 'Home',
    );

    const sampleItem = CartItemModel(
      productId: 'prod_trouser_1',
      variantId: 'v_28',
      productName: 'DPS Navy Blue Trouser',
      schoolName: 'Delhi Public School',
      variantLabel: 'Size: 28',
      unitPrice: 400.0,
      quantity: 2, // Subtotal 800 + Delivery 50 = 850
    );

    setUp(() async {
      mockAddressRepo = MockAddressRepository();
      await mockAddressRepo.addAddress(testUserId, sampleAddress);
    });

    tearDown(() {
      mockAddressRepo.dispose();
    });

    Widget createTestWidget({
      VoidCallback? onPayPressed,
      VoidCallback? onBack,
      VoidCallback? onChangeAddress,
      PaymentMethodType initialMethod = PaymentMethodType.upi,
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
              final controller = ref.read(checkoutControllerProvider.notifier);
              final state = ref.read(checkoutControllerProvider);

              if (state.items.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.initStandardCartCheckout(
                    items: [sampleItem],
                    userId: testUserId,
                  );
                  controller.selectAddress(sampleAddress);
                  controller.selectPaymentMethod(initialMethod);
                  controller.goToStep(CheckoutStep.payment);
                });
              }

              return PaymentStepScreen(
                onPayPressed: onPayPressed,
                onBack: onBack,
                onChangeAddress: onChangeAddress,
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

    testWidgets('renders security banner, address snapshot, and 4 payment options with ₹40 pill',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Step progress bar & Security banner
      expect(find.text('Step 3 of 3: Payment & Confirmation'), findsOneWidget);
      expect(find.text('256-bit SSL Encrypted Transaction'), findsOneWidget);

      // 2. Selected delivery address preview
      expect(find.text('Delivering To'), findsOneWidget);
      expect(find.text('Aditya Sharma • +91 9876543210'), findsOneWidget);
      expect(find.byKey(const Key('change_address_button')), findsOneWidget);

      // 3. Payment options radio list
      expect(find.byKey(const Key('payment_method_upi')), findsOneWidget);
      expect(find.byKey(const Key('payment_method_card')), findsOneWidget);
      expect(find.byKey(const Key('payment_method_netBanking')), findsOneWidget);
      expect(find.byKey(const Key('payment_method_cod')), findsOneWidget);

      // Recommended badge on UPI & Handling fee pill on COD
      expect(find.text('RECOMMENDED'), findsOneWidget);
      expect(find.byKey(const Key('cod_handling_fee_pill')), findsOneWidget);
      expect(find.text('+ ₹40 Handling Fee'), findsOneWidget);

      // 4. Default is UPI -> Grand Total = ₹850 (no COD fee)
      final grandTotalFinder = find.byKey(const Key('payment_grand_total_text'));
      expect(grandTotalFinder, findsOneWidget);
      expect(find.descendant(of: grandTotalFinder, matching: find.text('₹850')), findsOneWidget);

      // Primary pay button displays Pay ₹850
      final buttonFinder = find.byKey(const Key('payment_primary_button'));
      expect(buttonFinder, findsOneWidget);
      expect(find.text('Pay ₹850'), findsOneWidget);
    });

    testWidgets('radio selection of COD dynamically updates ₹40 handling fee in Grand Total',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initial Total is ₹850
      expect(find.text('₹850'), findsOneWidget);
      expect(find.byKey(const Key('price_breakup_cod_fee_value')), findsNothing);

      // Tap Cash on Delivery (COD) radio option
      final codTile = find.byKey(const Key('payment_method_cod'));
      await tester.tap(codTile);
      await tester.pumpAndSettle();

      // DONE CRITERIA: COD fee appears in breakdown, Grand Total dynamically becomes ₹890
      expect(find.byKey(const Key('price_breakup_cod_fee_value')), findsOneWidget);
      expect(find.text('+₹40'), findsOneWidget);

      final grandTotalFinder = find.byKey(const Key('payment_grand_total_text'));
      expect(find.descendant(of: grandTotalFinder, matching: find.text('₹890')), findsOneWidget);

      // Bottom button dynamically updates label for COD
      expect(find.text('Place Order via COD • ₹890'), findsOneWidget);
    });

    testWidgets('switching from COD to Card dynamically removes ₹40 handling fee',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget(initialMethod: PaymentMethodType.cod));
      await tester.pumpAndSettle();

      // Initially in COD: Total is ₹890
      expect(find.text('+₹40'), findsOneWidget);
      final grandTotalFinder = find.byKey(const Key('payment_grand_total_text'));
      expect(find.descendant(of: grandTotalFinder, matching: find.text('₹890')), findsOneWidget);
      expect(find.text('Place Order via COD • ₹890'), findsOneWidget);

      // Select Credit / Debit Card
      final cardTile = find.byKey(const Key('payment_method_card'));
      await tester.tap(cardTile);
      await tester.pumpAndSettle();

      // COD fee is removed, Grand Total reverts to ₹850
      expect(find.byKey(const Key('price_breakup_cod_fee_value')), findsNothing);
      expect(find.descendant(of: grandTotalFinder, matching: find.text('₹850')), findsOneWidget);
      expect(find.text('Pay ₹850'), findsOneWidget);
    });

    testWidgets('switching from COD to Net Banking dynamically removes ₹40 handling fee',
        (tester) async {
      setStandardViewport(tester);
      await tester.pumpWidget(createTestWidget(initialMethod: PaymentMethodType.cod));
      await tester.pumpAndSettle();

      // Select Net Banking
      final netBankingTile = find.byKey(const Key('payment_method_netBanking'));
      await tester.tap(netBankingTile);
      await tester.pumpAndSettle();

      // COD fee is removed, Grand Total reverts to ₹850
      expect(find.byKey(const Key('price_breakup_cod_fee_value')), findsNothing);
      final grandTotalFinder = find.byKey(const Key('payment_grand_total_text'));
      expect(find.descendant(of: grandTotalFinder, matching: find.text('₹850')), findsOneWidget);
      expect(find.text('Pay ₹850'), findsOneWidget);
    });

    testWidgets('tapping CHANGE address triggers callback and navigates back to Step 2',
        (tester) async {
      setStandardViewport(tester);
      bool addressChangeTriggered = false;

      await tester.pumpWidget(createTestWidget(
        onChangeAddress: () => addressChangeTriggered = true,
      ));
      await tester.pumpAndSettle();

      final changeBtn = find.byKey(const Key('change_address_button'));
      expect(changeBtn, findsOneWidget);

      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      expect(addressChangeTriggered, isTrue);
    });

    testWidgets('tapping primary pay button triggers onPayPressed callback',
        (tester) async {
      setStandardViewport(tester);
      bool payPressedTriggered = false;

      await tester.pumpWidget(createTestWidget(
        onPayPressed: () => payPressedTriggered = true,
      ));
      await tester.pumpAndSettle();

      final payButton = find.byKey(const Key('payment_primary_button'));
      expect(payButton, findsOneWidget);

      await tester.tap(payButton);
      await tester.pumpAndSettle();

      expect(payPressedTriggered, isTrue);
    });

    testWidgets('zero layout overflow across compact mobile viewport (360x640)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('payment_primary_button')), findsOneWidget);
    });
  });
}
