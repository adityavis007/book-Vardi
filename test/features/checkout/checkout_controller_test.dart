import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/auth/domain/auth_state.dart';
import 'package:book_vardi/features/auth/domain/user_model.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/catalog/domain/product_model.dart';
import 'package:book_vardi/features/catalog/domain/variant_model.dart';
import 'package:book_vardi/features/checkout/data/address_repository.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/checkout/presentation/controllers/checkout_controller.dart';

import 'address_repository_test.dart';

class FakeAuthController extends StateNotifier<AuthState>
    implements AuthController {
  FakeAuthController(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CheckoutController & CheckoutState Tests (TASK-041)', () {
    late ProviderContainer container;
    late MockAddressRepository mockAddressRepo;
    const testUserId = 'user_aditya_checkout';

    const sampleAddress = AddressModel(
      addressId: 'addr_home_1',
      fullName: 'Aditya Sharma',
      phone: '9876543210',
      addressLine1: 'Flat 402, Royal Palms',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122001',
      isDefault: true,
      addressType: 'Home',
    );

    const schoolAddress = AddressModel(
      addressId: 'addr_school_2',
      fullName: 'Aditya (DPS Campus)',
      phone: '9812345678',
      addressLine1: 'DPS Campus Sector 45',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122003',
      isDefault: false,
      addressType: 'School',
    );

    const item1 = CartItemModel(
      productId: 'prod_trouser',
      variantId: 'v_28',
      productName: 'DPS Navy Trouser',
      schoolName: 'Delhi Public School',
      variantLabel: 'Size: 28',
      unitPrice: 400.0,
      quantity: 2, // 800.0 subtotal (< 999 => ₹50 delivery)
    );

    const item2 = CartItemModel(
      productId: 'prod_shirt',
      variantId: 'v_32',
      productName: 'DPS White Shirt',
      schoolName: 'Delhi Public School',
      variantLabel: 'Size: 32',
      unitPrice: 300.0,
      quantity: 1, // 300.0 subtotal
    );

    setUp(() async {
      mockAddressRepo = MockAddressRepository();
      // Preload a default address for test user
      await mockAddressRepo.addAddress(testUserId, sampleAddress);
      await mockAddressRepo.addAddress(testUserId, schoolAddress);

      container = ProviderContainer(
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
      );
    });

    tearDown(() {
      mockAddressRepo.dispose();
      container.dispose();
    });

    test('initial state has default values and step 1 (review)', () {
      final state = container.read(checkoutControllerProvider);

      expect(state.currentStep, equals(CheckoutStep.review));
      expect(state.currentStep.stepNumber, equals(1));
      expect(state.currentStep.title, equals('Review Order'));
      expect(state.items, isEmpty);
      expect(state.selectedAddress, isNull);
      expect(state.deliveryMode, equals(DeliveryMode.standard));
      expect(state.paymentMethod, equals(PaymentMethodType.upi));
      expect(state.isBuyNowBypass, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.canGoBack, isFalse);
      expect(state.canProceedFromCurrentStep, isFalse); // empty items
    });

    test('initStandardCartCheckout initializes cart items and auto-populates default address', () async {
      final controller = container.read(checkoutControllerProvider.notifier);

      await controller.initStandardCartCheckout(
        items: [item1],
        userId: testUserId,
      );

      final state = container.read(checkoutControllerProvider);
      expect(state.items, hasLength(1));
      expect(state.isBuyNowBypass, isFalse);
      expect(state.basePricing.subtotal, equals(800.0));
      expect(state.effectiveDeliveryCharge, equals(50.0)); // standard subtotal < 999
      expect(state.pricing.grandTotal, equals(850.0));

      // Auto-selected default address from repository
      expect(state.selectedAddress, isNotNull);
      expect(state.selectedAddress!.addressId, equals('addr_home_1'));
      expect(state.selectedAddress!.isDefault, isTrue);
      expect(state.canProceedFromCurrentStep, isTrue);
    });

    test('initBuyNowCheckout initializes single item bypass session and auto-selects default address', () async {
      final controller = container.read(checkoutControllerProvider.notifier);

      await controller.initBuyNowCheckout(
        item: item1,
        userId: testUserId,
      );

      final state = container.read(checkoutControllerProvider);
      expect(state.isBuyNowBypass, isTrue);
      expect(state.items, hasLength(1));
      expect(state.items.first.productId, equals('prod_trouser'));
      expect(state.selectedAddress, isNotNull);
      expect(state.selectedAddress!.addressId, equals('addr_home_1'));
      expect(state.basePricing.subtotal, equals(800.0));
    });

    test('initBuyNowFromProduct creates single item from catalog model and variant', () async {
      final controller = container.read(checkoutControllerProvider.notifier);

      const product = ProductModel(
        productId: 'prod_blazer',
        name: 'DPS Winter Blazer',
        description: 'Blazer for winter',
        categoryId: 'cat_uniforms',
        schoolId: 'sch_dps',
        schoolName: 'Delhi Public School',
        basePrice: 1500.0,
        discountPrice: 1350.0,
      );

      const variant = VariantModel(
        variantId: 'v_36',
        sku: 'DPS-BLZ-36',
        label: 'Size 36',
        price: 1350.0,
        stock: 5,
      );

      await controller.initBuyNowFromProduct(
        product: product,
        variant: variant,
        quantity: 1,
        userId: testUserId,
      );

      final state = container.read(checkoutControllerProvider);
      expect(state.isBuyNowBypass, isTrue);
      expect(state.items, hasLength(1));
      expect(state.items.first.id, equals('prod_blazer_v_36'));
      expect(state.items.first.unitPrice, equals(1350.0));
      expect(state.basePricing.subtotal, equals(1350.0));
      // Subtotal > 999 => Free delivery
      expect(state.effectiveDeliveryCharge, equals(0.0));
      expect(state.pricing.grandTotal, equals(1350.0));
    });

    test('Step transitions retain selected address, delivery mode, and pricing across forward and back navigation', () async {
      final controller = container.read(checkoutControllerProvider.notifier);

      // 1. Initialize session with items
      await controller.initStandardCartCheckout(
        items: [item1, item2], // 800 + 300 = 1100 (> 999 => Free standard delivery)
        userId: testUserId,
      );

      var state = container.read(checkoutControllerProvider);
      expect(state.currentStep, equals(CheckoutStep.review));
      expect(state.pricing.subtotal, equals(1100.0));
      expect(state.pricing.grandTotal, equals(1100.0));

      // 2. Advance to Step 2 (Address)
      final advancedToAddress = controller.nextStep();
      expect(advancedToAddress, isTrue);

      state = container.read(checkoutControllerProvider);
      expect(state.currentStep, equals(CheckoutStep.address));
      expect(state.currentStep.stepNumber, equals(2));
      expect(state.selectedAddress!.addressId, equals('addr_home_1'));

      // 3. User modifies Address and Delivery Mode in Step 2
      controller.selectAddress(schoolAddress);
      controller.selectDeliveryMode(DeliveryMode.schoolDelivery);

      state = container.read(checkoutControllerProvider);
      expect(state.selectedAddress!.addressId, equals('addr_school_2'));
      expect(state.deliveryMode, equals(DeliveryMode.schoolDelivery));
      expect(state.effectiveDeliveryCharge, equals(0.0));

      // 4. Advance to Step 3 (Payment)
      final advancedToPayment = controller.nextStep();
      expect(advancedToPayment, isTrue);

      state = container.read(checkoutControllerProvider);
      expect(state.currentStep, equals(CheckoutStep.payment));
      expect(state.currentStep.stepNumber, equals(3));

      // VERIFY DONE CRITERIA: State retains selected address, delivery mode, and pricing!
      expect(state.selectedAddress!.addressId, equals('addr_school_2'));
      expect(state.deliveryMode, equals(DeliveryMode.schoolDelivery));
      expect(state.pricing.subtotal, equals(1100.0));
      expect(state.pricing.grandTotal, equals(1100.0));

      // 5. User selects Cash on Delivery (COD) in Step 3
      controller.selectPaymentMethod(PaymentMethodType.cod);

      state = container.read(checkoutControllerProvider);
      expect(state.paymentMethod, equals(PaymentMethodType.cod));
      expect(state.codHandlingFee, equals(40.0));
      // Grand Total dynamically includes COD handling fee: 1100 + 0 + 40 = 1140
      expect(state.pricing.grandTotal, equals(1140.0));

      // 6. Navigate backward to Step 2 (Address)
      final backedToAddress = controller.previousStep();
      expect(backedToAddress, isTrue);

      state = container.read(checkoutControllerProvider);
      expect(state.currentStep, equals(CheckoutStep.address));
      // Address, delivery mode, payment method, and pricing are retained!
      expect(state.selectedAddress!.addressId, equals('addr_school_2'));
      expect(state.deliveryMode, equals(DeliveryMode.schoolDelivery));
      expect(state.paymentMethod, equals(PaymentMethodType.cod));
      expect(state.pricing.grandTotal, equals(1140.0));

      // 7. Navigate backward to Step 1 (Review)
      final backedToReview = controller.previousStep();
      expect(backedToReview, isTrue);

      state = container.read(checkoutControllerProvider);
      expect(state.currentStep, equals(CheckoutStep.review));
      expect(state.selectedAddress!.addressId, equals('addr_school_2'));
      expect(state.deliveryMode, equals(DeliveryMode.schoolDelivery));
      expect(state.pricing.grandTotal, equals(1140.0));

      // 8. Cannot go back past Step 1
      expect(controller.previousStep(), isFalse);
    });

    test('DeliveryMode selection dynamically adjusts delivery fee', () async {
      final controller = container.read(checkoutControllerProvider.notifier);

      // Subtotal = 800 (<= 999)
      await controller.initStandardCartCheckout(items: [item1]);

      // Standard delivery: ₹50
      controller.selectDeliveryMode(DeliveryMode.standard);
      var state = container.read(checkoutControllerProvider);
      expect(state.effectiveDeliveryCharge, equals(50.0));
      expect(state.pricing.grandTotal, equals(850.0));

      // School delivery: ₹0
      controller.selectDeliveryMode(DeliveryMode.schoolDelivery);
      state = container.read(checkoutControllerProvider);
      expect(state.effectiveDeliveryCharge, equals(0.0));
      expect(state.pricing.grandTotal, equals(800.0));

      // Express delivery: ₹99
      controller.selectDeliveryMode(DeliveryMode.express);
      state = container.read(checkoutControllerProvider);
      expect(state.effectiveDeliveryCharge, equals(99.0));
      expect(state.pricing.grandTotal, equals(899.0));
    });

    test('PaymentMethodType selection dynamically adds and removes ₹40 COD handling fee', () async {
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.initStandardCartCheckout(items: [item1]); // Subtotal 800 + Delivery 50 = 850

      var state = container.read(checkoutControllerProvider);
      expect(state.pricing.grandTotal, equals(850.0));

      // Select COD
      controller.selectPaymentMethod(PaymentMethodType.cod);
      state = container.read(checkoutControllerProvider);
      expect(state.paymentMethod.isCod, isTrue);
      expect(state.codHandlingFee, equals(40.0));
      expect(state.pricing.grandTotal, equals(890.0)); // 850 + 40

      // Select Card
      controller.selectPaymentMethod(PaymentMethodType.card);
      state = container.read(checkoutControllerProvider);
      expect(state.paymentMethod.isCod, isFalse);
      expect(state.codHandlingFee, equals(0.0));
      expect(state.pricing.grandTotal, equals(850.0));

      // Select Net Banking
      controller.selectPaymentMethod(PaymentMethodType.netBanking);
      state = container.read(checkoutControllerProvider);
      expect(state.paymentMethod.isCod, isFalse);
      expect(state.codHandlingFee, equals(0.0));
      expect(state.pricing.grandTotal, equals(850.0));

      // Select UPI
      controller.selectPaymentMethod(PaymentMethodType.upi);
      state = container.read(checkoutControllerProvider);
      expect(state.paymentMethod.isCod, isFalse);
      expect(state.codHandlingFee, equals(0.0));
      expect(state.pricing.grandTotal, equals(850.0));
    });

    test('Navigation guards prevent jumping forward to payment without address', () async {
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.initStandardCartCheckout(items: [item1]);
      // Explicitly clear address to test guard
      controller.clearSelectedAddress();

      var state = container.read(checkoutControllerProvider);
      expect(state.selectedAddress, isNull);
      expect(state.canProceedFromAddress, isFalse);

      // Attempt jump to payment
      final jumped = controller.goToStep(CheckoutStep.payment);
      expect(jumped, isFalse);

      state = container.read(checkoutControllerProvider);
      expect(state.errorMessage, contains('Please select a delivery address'));
      expect(state.currentStep, equals(CheckoutStep.review));
    });

    test('toOrderIntent produces consistent OrderIntentModel domain entity', () async {
      final controller = container.read(checkoutControllerProvider.notifier);
      await controller.initStandardCartCheckout(items: [item1], userId: testUserId);
      controller.selectAddress(sampleAddress);
      controller.selectPaymentMethod(PaymentMethodType.upi);

      final state = container.read(checkoutControllerProvider);
      final intent = state.toOrderIntent();

      expect(intent.items, hasLength(1));
      expect(intent.shippingAddress, equals(sampleAddress));
      expect(intent.userId, equals(testUserId));
      expect(intent.paymentMethod, equals('UPI'));
      expect(intent.isBuyNowBypass, isFalse);
      expect(intent.isReadyForPayment, isTrue);
      expect(intent.totalItemCount, equals(2));
    });

    test('setLoading, setError, setOrderId, and reset operate correctly', () {
      final controller = container.read(checkoutControllerProvider.notifier);

      controller.setLoading(true);
      expect(container.read(checkoutControllerProvider).isLoading, isTrue);

      controller.setError('Payment gateway error');
      expect(container.read(checkoutControllerProvider).errorMessage, equals('Payment gateway error'));

      controller.setOrderId('BV-2026-999');
      expect(container.read(checkoutControllerProvider).orderId, equals('BV-2026-999'));

      controller.reset();
      final resetState = container.read(checkoutControllerProvider);
      expect(resetState.currentStep, equals(CheckoutStep.review));
      expect(resetState.items, isEmpty);
      expect(resetState.orderId, isNull);
      expect(resetState.errorMessage, isNull);
    });
  });
}
