import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../cart/data/cart_repository.dart';
import '../../../cart/domain/cart_item_model.dart';
import '../../../cart/domain/price_breakup_model.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../catalog/domain/product_model.dart';
import '../../../catalog/domain/variant_model.dart';
import '../../data/address_repository.dart';
import '../../data/order_repository.dart';
import '../../data/razorpay_service.dart';
import '../../domain/address_model.dart';
import '../../domain/order_intent_model.dart';

/// Active step in the 3-step customer checkout pipeline.
enum CheckoutStep {
  /// Step 1: Review items, quantity & pricing summary.
  review,

  /// Step 2: Select or add delivery address & delivery mode.
  address,

  /// Step 3: Select payment method & complete transaction.
  payment,
}

extension CheckoutStepExtension on CheckoutStep {
  int get stepNumber => index + 1;

  String get title {
    switch (this) {
      case CheckoutStep.review:
        return 'Review Order';
      case CheckoutStep.address:
        return 'Delivery Address';
      case CheckoutStep.payment:
        return 'Payment';
    }
  }

  String get description {
    switch (this) {
      case CheckoutStep.review:
        return 'Verify items and quantities';
      case CheckoutStep.address:
        return 'Choose delivery location & mode';
      case CheckoutStep.payment:
        return 'Select payment method';
    }
  }
}

/// Delivery fulfillment mode chosen by the customer.
enum DeliveryMode {
  /// Standard doorstep delivery (₹50 or Free for orders > ₹999).
  standard,

  /// Direct School Campus / Classroom Desk Delivery (Free ₹0).
  schoolDelivery,

  /// Priority Express Delivery within 24-48 hours (Flat ₹99).
  express,
}

extension DeliveryModeExtension on DeliveryMode {
  String get displayName {
    switch (this) {
      case DeliveryMode.standard:
        return 'Standard Delivery';
      case DeliveryMode.schoolDelivery:
        return 'School Campus Delivery';
      case DeliveryMode.express:
        return 'Express Delivery';
    }
  }

  String get description {
    switch (this) {
      case DeliveryMode.standard:
        return 'Delivered to your doorstep in 3-5 business days';
      case DeliveryMode.schoolDelivery:
        return 'Delivered directly to student classroom / school desk (Free)';
      case DeliveryMode.express:
        return 'Priority dispatch, delivered in 24-48 hours';
    }
  }

  /// Calculates fulfillment fee based on delivery mode and order subtotal.
  double calculateFee(double subtotal) {
    switch (this) {
      case DeliveryMode.schoolDelivery:
        return 0.0;
      case DeliveryMode.express:
        return 99.0;
      case DeliveryMode.standard:
        return PriceBreakupModel.calculateDeliveryCharge(subtotal);
    }
  }
}

/// Payment method options available in Step 3.
enum PaymentMethodType {
  /// UPI payment (GPay, PhonePe, Paytm, QR).
  upi,

  /// Credit or Debit Card (Visa, MasterCard, RuPay).
  card,

  /// Internet Banking across 50+ Indian banks.
  netBanking,

  /// Cash on Delivery at doorstep with ₹40 handling fee.
  cod,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get displayName {
    switch (this) {
      case PaymentMethodType.upi:
        return 'UPI (Google Pay, PhonePe, Paytm)';
      case PaymentMethodType.card:
        return 'Credit / Debit Card';
      case PaymentMethodType.netBanking:
        return 'Net Banking';
      case PaymentMethodType.cod:
        return 'Cash on Delivery (COD)';
    }
  }

  String get rawCode {
    switch (this) {
      case PaymentMethodType.upi:
        return 'UPI';
      case PaymentMethodType.card:
        return 'CARD';
      case PaymentMethodType.netBanking:
        return 'NET_BANKING';
      case PaymentMethodType.cod:
        return 'COD';
    }
  }

  bool get isCod => this == PaymentMethodType.cod;
}

/// Immutable state encapsulating the active checkout pipeline session.
@immutable
class CheckoutState {
  /// Standard handling charge for Cash on Delivery orders (₹40).
  static const double codHandlingFeeAmount = 40.0;

  final CheckoutStep currentStep;
  final List<CartItemModel> items;
  final AddressModel? selectedAddress;
  final DeliveryMode deliveryMode;
  final PaymentMethodType paymentMethod;
  final PriceBreakupModel basePricing;
  final bool isBuyNowBypass;
  final bool isLoading;
  final String? errorMessage;
  final String? orderId;
  final String? userId;

  const CheckoutState({
    this.currentStep = CheckoutStep.review,
    this.items = const [],
    this.selectedAddress,
    this.deliveryMode = DeliveryMode.standard,
    this.paymentMethod = PaymentMethodType.upi,
    this.basePricing = const PriceBreakupModel(
      subtotal: 0.0,
      deliveryCharge: 0.0,
      grandTotal: 0.0,
    ),
    this.isBuyNowBypass = false,
    this.isLoading = false,
    this.errorMessage,
    this.orderId,
    this.userId,
  });

  /// Total units across all items in active checkout.
  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Active delivery charge based on [deliveryMode] and items [subtotal].
  double get effectiveDeliveryCharge =>
      deliveryMode.calculateFee(basePricing.subtotal);

  /// Additional Cash on Delivery handling fee (₹40 if COD, ₹0 otherwise).
  double get codHandlingFee =>
      paymentMethod == PaymentMethodType.cod ? codHandlingFeeAmount : 0.0;

  /// Dynamically computed effective price breakup incorporating the active delivery mode fee
  /// and COD handling fee (₹40) in Grand Total.
  PriceBreakupModel get pricing {
    final delivery = effectiveDeliveryCharge;
    final totalDiscount = basePricing.totalDiscounts;
    final rawGrandTotal =
        basePricing.subtotal + delivery - totalDiscount + codHandlingFee;
    final grandTotal = rawGrandTotal < 0.0 ? 0.0 : rawGrandTotal;

    return basePricing.copyWith(
      deliveryCharge: delivery,
      grandTotal: grandTotal,
    );
  }

  /// Converts active state into the domain [OrderIntentModel].
  OrderIntentModel toOrderIntent() {
    return OrderIntentModel.create(
      items: items,
      shippingAddress: selectedAddress,
      pricing: pricing,
      isBuyNowBypass: isBuyNowBypass,
      orderId: orderId,
      userId: userId,
      paymentMethod: paymentMethod.rawCode,
    );
  }

  // --- Step Prerequisites & Navigation Guards ---

  bool get canProceedFromReview => items.isNotEmpty;

  bool get canProceedFromAddress =>
      selectedAddress != null && selectedAddress!.isValid;

  bool get canProceedFromPayment => toOrderIntent().isReadyForPayment;

  /// Whether the user has met all criteria to advance from the current step.
  bool get canProceedFromCurrentStep {
    switch (currentStep) {
      case CheckoutStep.review:
        return canProceedFromReview;
      case CheckoutStep.address:
        return canProceedFromAddress;
      case CheckoutStep.payment:
        return canProceedFromPayment;
    }
  }

  /// Whether backward step navigation is possible.
  bool get canGoBack => currentStep.index > 0;

  int get currentStepIndex => currentStep.index;
  int get totalSteps => CheckoutStep.values.length;

  CheckoutState copyWith({
    CheckoutStep? currentStep,
    List<CartItemModel>? items,
    AddressModel? selectedAddress,
    bool clearAddress = false,
    DeliveryMode? deliveryMode,
    PaymentMethodType? paymentMethod,
    PriceBreakupModel? basePricing,
    bool? isBuyNowBypass,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? orderId,
    String? userId,
  }) {
    return CheckoutState(
      currentStep: currentStep ?? this.currentStep,
      items: items ?? this.items,
      selectedAddress:
          clearAddress ? null : (selectedAddress ?? this.selectedAddress),
      deliveryMode: deliveryMode ?? this.deliveryMode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      basePricing: basePricing ?? this.basePricing,
      isBuyNowBypass: isBuyNowBypass ?? this.isBuyNowBypass,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckoutState &&
        other.currentStep == currentStep &&
        listEquals(other.items, items) &&
        other.selectedAddress == selectedAddress &&
        other.deliveryMode == deliveryMode &&
        other.paymentMethod == paymentMethod &&
        other.basePricing == basePricing &&
        other.isBuyNowBypass == isBuyNowBypass &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.orderId == orderId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(
        currentStep,
        Object.hashAll(items),
        selectedAddress,
        deliveryMode,
        paymentMethod,
        basePricing,
        isBuyNowBypass,
        isLoading,
        errorMessage,
        orderId,
        userId,
      );

  @override
  String toString() {
    return 'CheckoutState(step: $currentStep, items: ${items.length}, address: ${selectedAddress?.fullName}, mode: $deliveryMode, payment: $paymentMethod, grandTotal: ${pricing.grandTotal}, isBuyNow: $isBuyNowBypass)';
  }
}

/// StateNotifier controlling active checkout sessions, address selection,
/// delivery modes, dynamic COD pricing, and step transitions.
class CheckoutController extends StateNotifier<CheckoutState> {
  final Ref _ref;

  CheckoutController(this._ref) : super(const CheckoutState());

  String? get _currentUserId => _ref.read(authControllerProvider).user?.userId;
  IAddressRepository get _addressRepo => _ref.read(addressRepositoryProvider);
  IOrderRepository get _orderRepo => _ref.read(orderRepositoryProvider);
  ICartRepository get _cartRepo => _ref.read(cartRepositoryProvider);
  IRazorpayService get _razorpayService => _ref.read(razorpayServiceProvider);

  /// Initializes a Standard Cart Checkout session from persistent shopping cart.
  /// Automatically fetches and selects user's default delivery address if available.
  Future<void> initStandardCartCheckout({
    List<CartItemModel>? items,
    PriceBreakupModel? pricing,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _currentUserId;
    final List<CartItemModel> cartItems =
        items ?? _ref.read(cartItemsListProvider);
    final calculatedPricing =
        pricing ?? PriceBreakupModel.fromItems(cartItems);

    state = CheckoutState(
      currentStep: CheckoutStep.review,
      items: List.unmodifiable(cartItems),
      basePricing: calculatedPricing,
      deliveryMode: DeliveryMode.standard,
      paymentMethod: PaymentMethodType.upi,
      isBuyNowBypass: false,
      userId: effectiveUserId,
    );

    await _autoSelectDefaultAddress(effectiveUserId);
  }

  /// Initializes a Direct "Buy Now" session bypassing the persistent shopping cart.
  /// Takes a single [item], calculates standalone pricing, and auto-fetches default address.
  Future<void> initBuyNowCheckout({
    required CartItemModel item,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? _currentUserId;
    final itemsList = [item];
    final calculatedPricing = PriceBreakupModel.fromItems(itemsList);

    state = CheckoutState(
      currentStep: CheckoutStep.review,
      items: List.unmodifiable(itemsList),
      basePricing: calculatedPricing,
      deliveryMode: DeliveryMode.standard,
      paymentMethod: PaymentMethodType.upi,
      isBuyNowBypass: true,
      userId: effectiveUserId,
    );

    await _autoSelectDefaultAddress(effectiveUserId);
  }

  /// Convenience helper to start Direct "Buy Now" checkout directly from a catalog [ProductModel].
  Future<void> initBuyNowFromProduct({
    required ProductModel product,
    VariantModel? variant,
    int quantity = 1,
    String? userId,
  }) async {
    final cartItem = CartItemModel.fromProduct(
      product,
      variant: variant,
      quantity: quantity,
    );
    await initBuyNowCheckout(item: cartItem, userId: userId);
  }

  /// Internal helper to look up and pre-select the user's default delivery address.
  Future<void> _autoSelectDefaultAddress(String? userId) async {
    if (userId == null || userId.isEmpty) return;

    try {
      final defaultAddr = await _addressRepo.fetchDefaultAddress(userId);
      if (defaultAddr != null && mounted) {
        state = state.copyWith(selectedAddress: defaultAddr);
      }
    } catch (_) {
      // Soft-fail: User can manually select/enter address in Step 2.
    }
  }

  // --- Step Navigation Methods ---

  /// Navigates to a specific [step] in the checkout pipeline.
  /// If navigating forward to payment, verifies that an address is selected.
  bool goToStep(CheckoutStep step) {
    if (step == CheckoutStep.payment && !state.canProceedFromAddress) {
      state = state.copyWith(
        errorMessage: 'Please select a delivery address to proceed to payment.',
      );
      return false;
    }

    if (step == CheckoutStep.address && !state.canProceedFromReview) {
      state = state.copyWith(
        errorMessage: 'Cannot proceed with an empty order.',
      );
      return false;
    }

    state = state.copyWith(
      currentStep: step,
      clearError: true,
    );
    return true;
  }

  /// Advances to the next step: Review -> Address -> Payment.
  /// Returns `true` if step was advanced, `false` if prerequisites were unmet.
  bool nextStep() {
    if (!state.canProceedFromCurrentStep) {
      if (state.currentStep == CheckoutStep.review) {
        state = state.copyWith(errorMessage: 'Your order contains no items.');
      } else if (state.currentStep == CheckoutStep.address) {
        state = state.copyWith(
          errorMessage: 'Please select a valid delivery address to continue.',
        );
      }
      return false;
    }

    if (state.currentStep == CheckoutStep.payment) {
      return false; // Already at final step
    }

    final nextIndex = state.currentStep.index + 1;
    state = state.copyWith(
      currentStep: CheckoutStep.values[nextIndex],
      clearError: true,
    );
    return true;
  }

  /// Navigates back one step: Payment -> Address -> Review.
  /// Retains selected address, delivery mode, and pricing.
  bool previousStep() {
    if (!state.canGoBack) return false;

    final prevIndex = state.currentStep.index - 1;
    state = state.copyWith(
      currentStep: CheckoutStep.values[prevIndex],
      clearError: true,
    );
    return true;
  }

  // --- Selection & Mutation Methods ---

  /// Sets the chosen shipping [address].
  /// Preserves delivery mode, pricing breakdown, and active step.
  void selectAddress(AddressModel address) {
    state = state.copyWith(
      selectedAddress: address,
      clearError: true,
    );
  }

  /// Clears the currently selected delivery address.
  void clearSelectedAddress() {
    state = state.copyWith(clearAddress: true);
  }

  /// Updates the fulfillment [mode] (Standard, School Campus, Express).
  /// Dynamically updates effective delivery fee while retaining address, pricing, and step.
  void selectDeliveryMode(DeliveryMode mode) {
    state = state.copyWith(
      deliveryMode: mode,
      clearError: true,
    );
  }

  /// Selects payment method (UPI, Card, Net Banking, COD).
  /// Radio selection dynamically updates COD handling fee (₹40) in Grand Total.
  void selectPaymentMethod(PaymentMethodType method) {
    state = state.copyWith(
      paymentMethod: method,
      clearError: true,
    );
  }

  /// Applies a coupon discount to the active checkout pricing.
  void applyCoupon(String couponCode, double discountAmount) {
    final updatedBase = state.basePricing.copyWith(
      couponDiscount: discountAmount,
    );
    state = state.copyWith(basePricing: updatedBase);
  }

  /// Sets loading indicator for asynchronous operations (e.g. order placement).
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Sets an explicit error message to display in checkout UI.
  void setError(String? error) {
    if (error == null) {
      state = state.copyWith(clearError: true);
    } else {
      state = state.copyWith(errorMessage: error);
    }
  }

  /// Sets generated Order ID upon successful placement.
  void setOrderId(String orderId) {
    state = state.copyWith(orderId: orderId);
  }

  /// Resets the controller back to initial default state.
  void reset() {
    state = const CheckoutState();
  }

  /// Places the customer order based on the selected payment method:
  /// - On COD: Directly writes order to Firestore with status 'CONFIRMED'.
  /// - On Online (UPI/Card/NetBanking): Launches native Razorpay sheet.
  ///   On payment success, records order in Firestore with payment ID and status 'CONFIRMED'.
  /// On successful order creation: Clears cart in Firestore (unless Buy-Now bypass),
  /// updates state with generated orderId, and invokes [onSuccess].
  /// On failure/cancellation: Retains shipping address and payment selections,
  /// updates errorMessage, and invokes [onFailure].
  Future<String?> placeOrder({
    void Function(String orderId)? onSuccess,
    void Function(String errorMessage)? onFailure,
  }) async {
    final effectiveUserId = state.userId ?? _currentUserId;
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      const errorMsg = 'Please log in to complete your order.';
      state = state.copyWith(errorMessage: errorMsg);
      onFailure?.call(errorMsg);
      return null;
    }

    if (!state.canProceedFromPayment) {
      final errorMsg = state.selectedAddress == null
          ? 'Please select a delivery address.'
          : 'Please add items to your order.';
      state = state.copyWith(errorMessage: errorMsg);
      onFailure?.call(errorMsg);
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (state.paymentMethod == PaymentMethodType.cod) {
      return _processCodOrder(
        userId: effectiveUserId,
        onSuccess: onSuccess,
        onFailure: onFailure,
      );
    } else {
      return _processOnlineOrder(
        userId: effectiveUserId,
        onSuccess: onSuccess,
        onFailure: onFailure,
      );
    }
  }

  Future<String?> _processCodOrder({
    required String userId,
    void Function(String orderId)? onSuccess,
    void Function(String errorMessage)? onFailure,
  }) async {
    try {
      final orderId = await _orderRepo.createOrder(
        userId: userId,
        intent: state.toOrderIntent(),
        deliveryMode: state.deliveryMode.name,
        status: 'CONFIRMED',
        paymentId: 'COD',
        paymentStatus: 'PENDING',
      );

      if (!state.isBuyNowBypass) {
        await _clearUserCart(userId);
      }

      state = state.copyWith(
        isLoading: false,
        orderId: orderId,
        clearError: true,
      );

      onSuccess?.call(orderId);
      return orderId;
    } catch (e) {
      final errorMsg = 'Failed to place order: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
      onFailure?.call(errorMsg);
      return null;
    }
  }

  Future<String?> _processOnlineOrder({
    required String userId,
    void Function(String orderId)? onSuccess,
    void Function(String errorMessage)? onFailure,
  }) {
    final completer = Completer<String?>();
    final user = _ref.read(authControllerProvider).user;
    final contactPhone = state.selectedAddress?.phone ?? user?.phone;
    final contactEmail = user?.email;

    _razorpayService.openCheckout(
      amountInRupees: state.pricing.grandTotal,
      orderName: 'Book Vardi Order',
      description:
          '${state.totalItemCount} items • ${state.deliveryMode.displayName}',
      prefillPhone: contactPhone,
      prefillEmail: contactEmail,
      notes: {
        'userId': userId,
        'deliveryMode': state.deliveryMode.name,
        'isBuyNow': state.isBuyNowBypass.toString(),
      },
      onSuccess: (response) async {
        try {
          final orderId = await _orderRepo.createOrder(
            userId: userId,
            intent: state.toOrderIntent(),
            deliveryMode: state.deliveryMode.name,
            status: 'CONFIRMED',
            paymentId: response.paymentId,
            razorpayOrderId: response.orderId,
            signature: response.signature,
            paymentStatus: 'PAID',
          );

          if (!state.isBuyNowBypass) {
            await _clearUserCart(userId);
          }

          state = state.copyWith(
            isLoading: false,
            orderId: orderId,
            clearError: true,
          );

          onSuccess?.call(orderId);
          if (!completer.isCompleted) completer.complete(orderId);
        } catch (e) {
          final errorMsg =
              'Payment succeeded but failed to record order: ${e.toString()}';
          state = state.copyWith(
            isLoading: false,
            errorMessage: errorMsg,
          );
          onFailure?.call(errorMsg);
          if (!completer.isCompleted) completer.complete(null);
        }
      },
      onFailure: (response) {
        final errorMsg = response.message ??
            'Payment cancelled or failed. Your selections have been saved. Please try again.';
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMsg,
        );
        onFailure?.call(errorMsg);
        if (!completer.isCompleted) completer.complete(null);
      },
      onExternalWallet: (response) {
        debugPrint(
            '[CheckoutController] Selected external wallet: ${response.walletName}');
      },
    );

    return completer.future;
  }

  Future<void> _clearUserCart(String userId) async {
    try {
      await _cartRepo.clearCart(userId);
      // Invalidate cart state cache
      _ref.invalidate(cartItemsListProvider);
    } catch (e) {
      debugPrint('[CheckoutController] Failed to clear cart: $e');
    }
  }
}

/// Global Riverpod StateNotifierProvider for [CheckoutController] and [CheckoutState].
final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>((ref) {
  return CheckoutController(ref);
});
