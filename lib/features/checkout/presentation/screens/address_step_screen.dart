import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_vardi/core/constants/app_colors.dart';
import 'package:book_vardi/core/constants/app_spacing.dart';
import 'package:book_vardi/core/theme/app_typography.dart';
import 'package:book_vardi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:book_vardi/features/checkout/data/address_repository.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/checkout/presentation/screens/add_address_screen.dart';
import 'package:book_vardi/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:book_vardi/features/location/domain/location_hub_model.dart';
import 'package:book_vardi/features/location/presentation/controllers/location_controller.dart';
import 'package:book_vardi/shared/widgets/custom_button.dart';
import 'package:book_vardi/shared/widgets/custom_text_field.dart';

/// StreamProvider exposing the user's real-time saved delivery addresses from Firestore.
final savedAddressesStreamProvider =
    StreamProvider<List<AddressModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final userId = authState.user?.userId;

  if (userId == null || userId.isEmpty) {
    return Stream.value(const <AddressModel>[]);
  }

  final repo = ref.watch(addressRepositoryProvider);
  return repo.watchAddresses(userId);
});

/// Step 2 Screen in the Checkout Pipeline: Delivery Address Selection & Creation.
class AddressStepScreen extends ConsumerStatefulWidget {
  final VoidCallback? onProceedToPayment;
  final VoidCallback? onBack;
  final bool showAppBar;

  const AddressStepScreen({
    super.key,
    this.onProceedToPayment,
    this.onBack,
    this.showAppBar = true,
  });

  @override
  ConsumerState<AddressStepScreen> createState() => _AddressStepScreenState();
}

class _AddressStepScreenState extends ConsumerState<AddressStepScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure active checkout step is Step 2 (Address)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(checkoutControllerProvider.notifier);
      final currentStep = ref.read(checkoutControllerProvider).currentStep;
      if (currentStep == CheckoutStep.review) {
        controller.goToStep(CheckoutStep.address);
      }
    });
  }

  void _openAddAddressModal(
    BuildContext context,
    String? userId, {
    AddressModel? initialAddress,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddAddressScreen(
          userId: userId,
          initialAddress: initialAddress,
          onAddressAdded: (newAddress) {
            ref.read(checkoutControllerProvider.notifier).selectAddress(newAddress);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final userId = authState.user?.userId;
    final addressesAsync = ref.watch(savedAddressesStreamProvider);
    final selectedAddress = checkoutState.selectedAddress;
    final canProceed = checkoutState.canProceedFromAddress;
    final selectedLocation = ref.watch(selectedLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Select Delivery Address'),
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        ref.read(checkoutControllerProvider.notifier).previousStep();
                        widget.onBack!();
                      },
                    )
                  : null,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            _buildStepProgressBar(checkoutState),

            Expanded(
              child: addressesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.destructiveRed,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Failed to load saved addresses',
                          style: AppTypography.heading2,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        CustomButton.outline(
                          text: 'Add New Address',
                          isFullWidth: false,
                          onPressed: () => _openAddAddressModal(context, userId),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (savedAddresses) {
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      // Delivery Fulfillment Mode Selector
                      _buildDeliveryModeSection(checkoutState),
                      const SizedBox(height: AppSpacing.lg),

                      // Saved Addresses Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Saved Addresses (${savedAddresses.length})',
                              style: AppTypography.heading2.copyWith(
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            key: const Key('add_new_address_button'),
                            onPressed: () => _openAddAddressModal(context, userId),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: AppColors.primaryNavy,
                            ),
                            label: Text(
                              '+ Add New',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Addresses List or Empty State
                      if (savedAddresses.isEmpty)
                        _buildEmptyAddressCard(context, userId)
                      else
                        ...savedAddresses.map((address) {
                          final isSelected = selectedAddress?.addressId == address.addressId;
                          return _buildAddressCard(
                            context: context,
                            address: address,
                            isSelected: isSelected,
                            userId: userId,
                            onTap: () {
                              ref
                                  .read(checkoutControllerProvider.notifier)
                                  .selectAddress(address);
                            },
                          );
                        }),

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  );
                },
              ),
            ),

            // Sticky Bottom Purchase / Deliver Button Bar
            _buildStickyBottomBar(
              context: context,
              canProceed: canProceed,
              selectedAddress: selectedAddress,
              selectedLocation: selectedLocation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgressBar(CheckoutState state) {
    return Container(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Step 2 of 3: Delivery Address',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              Text(
                'Next: Payment',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const ClipRRect(
            borderRadius: AppSpacing.roundedFull,
            child: LinearProgressIndicator(
              value: 0.66,
              minHeight: 6.0,
              backgroundColor: AppColors.borderGray,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryModeSection(CheckoutState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: AppColors.primaryNavy,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Fulfillment Options',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildDeliveryModeTile(
            title: DeliveryMode.standard.displayName,
            subtitle: 'Doorstep Delivery (₹50, Free over ₹999)',
            mode: DeliveryMode.standard,
            current: state.deliveryMode,
            trailingBadge: state.basePricing.isFreeDelivery ? 'FREE' : null,
          ),
          const Divider(height: 1),
          _buildDeliveryModeTile(
            title: DeliveryMode.schoolDelivery.displayName,
            subtitle: 'Direct School Campus / Classroom Desk Drop',
            mode: DeliveryMode.schoolDelivery,
            current: state.deliveryMode,
            trailingBadge: 'FREE',
          ),
          const Divider(height: 1),
          _buildDeliveryModeTile(
            title: DeliveryMode.express.displayName,
            subtitle: 'Priority 24-48 Hours Express Dispatch (+₹99)',
            mode: DeliveryMode.express,
            current: state.deliveryMode,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryModeTile({
    required String title,
    required String subtitle,
    required DeliveryMode mode,
    required DeliveryMode current,
    String? trailingBadge,
  }) {
    final isSelected = mode == current;
    return InkWell(
      key: Key('delivery_mode_${mode.name}'),
      onTap: () {
        ref.read(checkoutControllerProvider.notifier).selectDeliveryMode(mode);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Radio<DeliveryMode>(
              value: mode,
              groupValue: current,
              activeColor: AppColors.primaryNavy,
              onChanged: (val) {
                if (val != null) {
                  ref
                      .read(checkoutControllerProvider.notifier)
                      .selectDeliveryMode(val);
                }
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingBadge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.12),
                  borderRadius: AppSpacing.roundedMicro,
                ),
                child: Text(
                  trailingBadge,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required BuildContext context,
    required AddressModel address,
    required bool isSelected,
    required VoidCallback onTap,
    String? userId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFF0F4FF)
            : AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(
          color: isSelected ? AppColors.primaryNavy : AppColors.borderGray,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected ? AppSpacing.elevationSm : null,
      ),
      child: InkWell(
        key: Key('address_card_${address.addressId}'),
        onTap: onTap,
        borderRadius: AppSpacing.roundedMedium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Radio Button + Badges
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: isSelected,
                    activeColor: AppColors.primaryNavy,
                    onChanged: (_) => onTap(),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            address.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildAddressTypeBadge(address.addressType),
                      ],
                    ),
                  ),
                  if (address.isDefault) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withOpacity(0.1),
                        borderRadius: AppSpacing.roundedMicro,
                      ),
                      child: Text(
                        'DEFAULT',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  InkWell(
                    key: Key('edit_address_btn_${address.addressId}'),
                    onTap: () => _openAddAddressModal(
                      context,
                      userId,
                      initialAddress: address,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Address Body
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.formattedAddress,
                      style: AppTypography.bodyRegular.copyWith(
                        color: AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                    if (address.landmark != null &&
                        address.landmark!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        'Landmark: ${address.landmark}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '+91 ${address.phone}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTypeBadge(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'school':
        icon = Icons.school_outlined;
        color = AppColors.secondaryAmber;
        break;
      case 'work':
        icon = Icons.work_outline;
        color = AppColors.textSecondary;
        break;
      case 'home':
      default:
        icon = Icons.home_outlined;
        color = AppColors.primaryNavy;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.roundedMicro,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            type,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAddressCard(BuildContext context, String? userId) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppSpacing.roundedMedium,
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Delivery Addresses Saved',
            style: AppTypography.heading2.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add your home or school address to receive your books, uniforms & stationery.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            key: const Key('empty_add_address_button'),
            text: '+ Add New Delivery Address',
            onPressed: () => _openAddAddressModal(context, userId),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar({
    required BuildContext context,
    required bool canProceed,
    required AddressModel? selectedAddress,
    required LocationHubModel selectedLocation,
  }) {
    final isCityMismatch = selectedAddress != null &&
        selectedAddress.city.trim().isNotEmpty &&
        selectedLocation.city.trim().isNotEmpty &&
        !selectedAddress.city
            .toLowerCase()
            .contains(selectedLocation.city.toLowerCase()) &&
        !selectedLocation.city
            .toLowerCase()
            .contains(selectedAddress.city.toLowerCase());

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          top: BorderSide(color: AppColors.borderGray, width: 1),
        ),
        boxShadow: AppSpacing.shadowNavBar,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedAddress != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Deliver to: ${selectedAddress.fullName} (${selectedAddress.pincode})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isCityMismatch)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm, top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryAmber.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(
                    color: AppColors.secondaryAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 15,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Note: Delivery address is in ${selectedAddress.city}, but your active hub is ${selectedLocation.name}. School kit deliveries will still be processed.',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: Color(0xFF78350F),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          CustomButton(
            key: const Key('deliver_to_this_address_button'),
            text: 'Deliver to this Address',
            onPressed: canProceed
                ? () {
                    final advanced = ref
                        .read(checkoutControllerProvider.notifier)
                        .nextStep();
                    if (advanced && widget.onProceedToPayment != null) {
                      widget.onProceedToPayment!();
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

/// Modal Bottom Sheet for Entering and Validating a New Delivery Address with PIN code auto-lookup.
class AddAddressBottomSheet extends ConsumerStatefulWidget {
  final String? userId;
  final ValueChanged<AddressModel>? onAddressAdded;
  final AddressModel? initialAddress;

  const AddAddressBottomSheet({
    super.key,
    this.userId,
    this.onAddressAdded,
    this.initialAddress,
  });

  @override
  ConsumerState<AddAddressBottomSheet> createState() =>
      _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends ConsumerState<AddAddressBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  String _addressType = 'Home';
  bool _isDefault = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      final addr = widget.initialAddress!;
      _fullNameController.text = addr.fullName;
      _phoneController.text = addr.phone;
      _pincodeController.text = addr.pincode;
      _addressLine1Controller.text = addr.addressLine1;
      _addressLine2Controller.text = addr.addressLine2 ?? '';
      _landmarkController.text = addr.landmark ?? '';
      _cityController.text = addr.city;
      _stateController.text = addr.state;
      _addressType = addr.addressType;
      _isDefault = addr.isDefault;
    }
    _pincodeController.addListener(_handlePincodeChange);
  }

  @override
  void dispose() {
    _pincodeController.removeListener(_handlePincodeChange);
    _fullNameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  /// Indian PIN code lookup dictionary and heuristic city/state population.
  void _handlePincodeChange() {
    final pincode = _pincodeController.text.trim();
    if (pincode.length == 6 && AddressModel.isValidPincode(pincode)) {
      final lookup = lookupIndianPincode(pincode);
      if (lookup != null) {
        setState(() {
          _cityController.text = lookup.city;
          _stateController.text = lookup.state;
        });
      }
    }
  }

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final isEditing = widget.initialAddress != null &&
        widget.initialAddress!.addressId.isNotEmpty;

    final newAddress = AddressModel(
      addressId: isEditing ? widget.initialAddress!.addressId : '',
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isNotEmpty
          ? _addressLine2Controller.text.trim()
          : null,
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      landmark: _landmarkController.text.trim().isNotEmpty
          ? _landmarkController.text.trim()
          : null,
      addressType: _addressType,
      isDefault: _isDefault,
    );

    try {
      final repo = ref.read(addressRepositoryProvider);
      final effectiveUserId = widget.userId ?? 'guest_user';
      AddressModel finalizedAddress;

      if (isEditing) {
        await repo.updateAddress(effectiveUserId, newAddress);
        finalizedAddress = newAddress;
      } else {
        final generatedId = await repo.addAddress(effectiveUserId, newAddress);
        finalizedAddress = newAddress.copyWith(addressId: generatedId);
      }

      if (widget.onAddressAdded != null) {
        widget.onAddressAdded!(finalizedAddress);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Address updated successfully!'
                : 'Address added successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        elevation: 8.0,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bottom Sheet Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Delivery Address',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                // Scrollable Form Fields
                Expanded(
                  child: ListView(
                    children: [
                      // Address Type Segmented Chips
                      Text(
                        'Address Type',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          _buildTypeChip('Home', Icons.home_outlined),
                          const SizedBox(width: AppSpacing.sm),
                          _buildTypeChip('School', Icons.school_outlined),
                          const SizedBox(width: AppSpacing.sm),
                          _buildTypeChip('Work', Icons.work_outline),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Full Name
                      CustomTextField(
                        key: const Key('field_full_name'),
                        label: 'Full Name *',
                        hintText: 'e.g. Aditya Sharma',
                        controller: _fullNameController,
                        validator: AddressModel.validateFullName,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Phone Number
                      CustomTextField(
                        key: const Key('field_phone'),
                        label: '10-Digit Mobile Number *',
                        hintText: '9876543210',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: AddressModel.validatePhoneField,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // PIN Code with auto-lookup indicator
                      CustomTextField(
                        key: const Key('field_pincode'),
                        label: 'PIN Code (6 digits) *',
                        hintText: '122001',
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        validator: AddressModel.validatePincodeField,
                        suffixIcon: const Icon(
                          Icons.pin_drop_outlined,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Address Line 1
                      CustomTextField(
                        key: const Key('field_address_line1'),
                        label: 'Flat, House No., Building, Apartment *',
                        hintText: 'Flat 402, Tower B, Royal Palms',
                        controller: _addressLine1Controller,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your address line 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Address Line 2
                      CustomTextField(
                        key: const Key('field_address_line2'),
                        label: 'Area, Sector, Street, Village (Optional)',
                        hintText: 'Sector 14, Near Golf Course Road',
                        controller: _addressLine2Controller,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Landmark
                      CustomTextField(
                        key: const Key('field_landmark'),
                        label: 'Landmark (Optional)',
                        hintText: 'Near Huda City Centre Metro',
                        controller: _landmarkController,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // City & State row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              key: const Key('field_city'),
                              label: 'City *',
                              hintText: 'Gurugram',
                              controller: _cityController,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter city';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: CustomTextField(
                              key: const Key('field_state'),
                              label: 'State *',
                              hintText: 'Haryana',
                              controller: _stateController,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter state';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Set as Default switch
                      SwitchListTile(
                        key: const Key('switch_is_default'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Set as default delivery address',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        value: _isDefault,
                        activeColor: AppColors.primaryNavy,
                        onChanged: (val) => setState(() => _isDefault = val),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),

                // Submit Button
                CustomButton.accentBuyNow(
                  key: const Key('save_address_button'),
                  text: 'Save Address',
                  isLoading: _isSubmitting,
                  onPressed: _submitAddress,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, IconData icon) {
    final isSelected = _addressType == type;
    return ChoiceChip(
      key: Key('chip_type_$type'),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.surfaceWhite : AppColors.textDark,
          ),
          const SizedBox(width: 4),
          Text(type),
        ],
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryNavy,
      backgroundColor: AppColors.backgroundSlate,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.surfaceWhite : AppColors.textDark,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _addressType = type);
        }
      },
    );
  }
}

/// Helper record for Indian PIN code lookups.
class IndianPincodeInfo {
  final String city;
  final String state;
  const IndianPincodeInfo({required this.city, required this.state});
}

/// Built-in fast Indian postal PIN code lookup directory with regional fallbacks.
IndianPincodeInfo? lookupIndianPincode(String pincode) {
  if (pincode.length != 6) return null;

  // Specific high-frequency metro PIN codes
  const Map<String, IndianPincodeInfo> metroCodes = {
    '110001': IndianPincodeInfo(city: 'New Delhi', state: 'Delhi'),
    '110002': IndianPincodeInfo(city: 'Central Delhi', state: 'Delhi'),
    '110020': IndianPincodeInfo(city: 'South Delhi', state: 'Delhi'),
    '122001': IndianPincodeInfo(city: 'Gurugram', state: 'Haryana'),
    '122002': IndianPincodeInfo(city: 'Gurugram', state: 'Haryana'),
    '122003': IndianPincodeInfo(city: 'Gurugram', state: 'Haryana'),
    '121001': IndianPincodeInfo(city: 'Faridabad', state: 'Haryana'),
    '201301': IndianPincodeInfo(city: 'Noida', state: 'Uttar Pradesh'),
    '201303': IndianPincodeInfo(city: 'Noida', state: 'Uttar Pradesh'),
    '201001': IndianPincodeInfo(city: 'Ghaziabad', state: 'Uttar Pradesh'),
    '400001': IndianPincodeInfo(city: 'Mumbai', state: 'Maharashtra'),
    '400050': IndianPincodeInfo(city: 'Bandra Mumbai', state: 'Maharashtra'),
    '411001': IndianPincodeInfo(city: 'Pune', state: 'Maharashtra'),
    '560001': IndianPincodeInfo(city: 'Bengaluru', state: 'Karnataka'),
    '560034': IndianPincodeInfo(city: 'Koramangala Bengaluru', state: 'Karnataka'),
    '600001': IndianPincodeInfo(city: 'Chennai', state: 'Tamil Nadu'),
    '500001': IndianPincodeInfo(city: 'Hyderabad', state: 'Telangana'),
    '700001': IndianPincodeInfo(city: 'Kolkata', state: 'West Bengal'),
    '380001': IndianPincodeInfo(city: 'Ahmedabad', state: 'Gujarat'),
    '302001': IndianPincodeInfo(city: 'Jaipur', state: 'Rajasthan'),
    '226001': IndianPincodeInfo(city: 'Lucknow', state: 'Uttar Pradesh'),
    '800001': IndianPincodeInfo(city: 'Patna', state: 'Bihar'),
    '682001': IndianPincodeInfo(city: 'Kochi', state: 'Kerala'),
  };

  if (metroCodes.containsKey(pincode)) {
    return metroCodes[pincode];
  }

  // Regional 2-digit prefix fallback
  final prefix2 = pincode.substring(0, 2);
  switch (prefix2) {
    case '11':
      return const IndianPincodeInfo(city: 'New Delhi', state: 'Delhi');
    case '12':
      return const IndianPincodeInfo(city: 'Gurugram', state: 'Haryana');
    case '13':
      return const IndianPincodeInfo(city: 'Ambala', state: 'Haryana');
    case '14':
    case '15':
      return const IndianPincodeInfo(city: 'Ludhiana', state: 'Punjab');
    case '16':
      return const IndianPincodeInfo(city: 'Chandigarh', state: 'Chandigarh');
    case '17':
      return const IndianPincodeInfo(city: 'Shimla', state: 'Himachal Pradesh');
    case '18':
    case '19':
      return const IndianPincodeInfo(city: 'Jammu', state: 'Jammu and Kashmir');
    case '20':
    case '21':
    case '22':
    case '23':
    case '24':
    case '25':
    case '26':
    case '27':
    case '28':
      return const IndianPincodeInfo(city: 'Noida', state: 'Uttar Pradesh');
    case '30':
    case '31':
    case '32':
    case '33':
    case '34':
      return const IndianPincodeInfo(city: 'Jaipur', state: 'Rajasthan');
    case '36':
    case '37':
    case '38':
    case '39':
      return const IndianPincodeInfo(city: 'Ahmedabad', state: 'Gujarat');
    case '40':
    case '41':
    case '42':
    case '43':
    case '44':
      return const IndianPincodeInfo(city: 'Mumbai', state: 'Maharashtra');
    case '45':
    case '46':
    case '47':
    case '48':
      return const IndianPincodeInfo(city: 'Bhopal', state: 'Madhya Pradesh');
    case '49':
      return const IndianPincodeInfo(city: 'Raipur', state: 'Chhattisgarh');
    case '50':
      return const IndianPincodeInfo(city: 'Hyderabad', state: 'Telangana');
    case '51':
    case '52':
    case '53':
      return const IndianPincodeInfo(city: 'Vijayawada', state: 'Andhra Pradesh');
    case '56':
    case '57':
    case '58':
    case '59':
      return const IndianPincodeInfo(city: 'Bengaluru', state: 'Karnataka');
    case '60':
    case '61':
    case '62':
    case '63':
    case '64':
      return const IndianPincodeInfo(city: 'Chennai', state: 'Tamil Nadu');
    case '67':
    case '68':
    case '69':
      return const IndianPincodeInfo(city: 'Thiruvananthapuram', state: 'Kerala');
    case '70':
    case '71':
    case '72':
    case '73':
    case '74':
      return const IndianPincodeInfo(city: 'Kolkata', state: 'West Bengal');
    case '75':
    case '76':
    case '77':
      return const IndianPincodeInfo(city: 'Bhubaneswar', state: 'Odisha');
    case '78':
      return const IndianPincodeInfo(city: 'Guwahati', state: 'Assam');
    case '80':
    case '81':
    case '82':
    case '83':
    case '84':
    case '85':
      return const IndianPincodeInfo(city: 'Patna', state: 'Bihar');
    default:
      return null;
  }
}
