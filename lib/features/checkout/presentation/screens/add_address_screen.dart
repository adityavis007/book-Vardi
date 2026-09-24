import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/address_repository.dart';
import '../../domain/address_model.dart';
import 'address_step_screen.dart';

/// Dedicated Full-Screen Page for Adding or Editing Customer Delivery Addresses.
class AddAddressScreen extends ConsumerStatefulWidget {
  final String? userId;
  final ValueChanged<AddressModel>? onAddressAdded;
  final AddressModel? initialAddress;

  const AddAddressScreen({
    super.key,
    this.userId,
    this.onAddressAdded,
    this.initialAddress,
  });

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
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

  bool get isEditing =>
      widget.initialAddress != null &&
      widget.initialAddress!.addressId.isNotEmpty;

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
      final currentAuthUser = ref.read(authControllerProvider).user;
      final effectiveUserId =
          widget.userId ?? currentAuthUser?.userId ?? 'guest_user';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Address updated successfully!'
                  : 'Address added successfully!',
            ),
          ),
        );
        Navigator.of(context).pop(finalizedAddress);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save address: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSlate,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          key: const Key('add_address_back_btn'),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primaryNavy,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          isEditing ? 'Edit Delivery Address' : 'Add Delivery Address',
          style: AppTypography.heading2.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18.0,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('add_address_close_btn'),
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.pop();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.borderGray.withValues(alpha: 0.6),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: AppColors.borderGray.withValues(alpha: 0.8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address Type Selector
                        Text(
                          'Address Type',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            fontSize: 13.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            _buildTypeChip('Home', Icons.home_outlined),
                            const SizedBox(width: AppSpacing.sm),
                            _buildTypeChip('School', Icons.school_outlined),
                            const SizedBox(width: AppSpacing.sm),
                            _buildTypeChip('Work', Icons.work_outline),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Full Name
                        CustomTextField(
                          key: const Key('field_full_name'),
                          label: 'Full Name *',
                          hintText: 'e.g. Aditya Sharma',
                          controller: _fullNameController,
                          validator: AddressModel.validateFullName,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 10-Digit Mobile Number
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

                        // PIN Code (6 digits)
                        CustomTextField(
                          key: const Key('field_pincode'),
                          label: 'PIN Code (6 digits) *',
                          hintText: '122001',
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          validator: AddressModel.validatePincodeField,
                          suffixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryNavy,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Flat, House No., Building, Apartment
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

                        // Area, Sector, Street, Village (Optional)
                        CustomTextField(
                          key: const Key('field_address_line2'),
                          label: 'Area, Sector, Street, Village (Optional)',
                          hintText: 'Sector 14, Near Golf Course Road',
                          controller: _addressLine2Controller,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Landmark (Optional)
                        CustomTextField(
                          key: const Key('field_landmark'),
                          label: 'Landmark (Optional)',
                          hintText: 'Near Huda City Centre Metro',
                          controller: _landmarkController,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // City & State Row
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

                        // Set as Default Delivery Address
                        Material(
                          color: AppColors.backgroundSlate,
                          borderRadius: BorderRadius.circular(10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                color: AppColors.borderGray.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            child: SwitchListTile(
                              key: const Key('switch_is_default'),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14.0,
                                vertical: 2.0,
                              ),
                              title: Text(
                                'Set as default delivery address',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              value: _isDefault,
                              activeColor: AppColors.primaryNavy,
                              onChanged: (val) =>
                                  setState(() => _isDefault = val),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Sticky Save Button Container
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: CustomButton.accentBuyNow(
                  key: const Key('save_address_button'),
                  text: 'Save Address',
                  isLoading: _isSubmitting,
                  onPressed: _submitAddress,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, IconData icon) {
    final isSelected = _addressType == type;
    return InkWell(
      key: Key('chip_type_$type'),
      borderRadius: BorderRadius.circular(8.0),
      onTap: () => setState(() => _addressType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.backgroundSlate,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryNavy
                : AppColors.borderGray.withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.secondaryAmber,
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.surfaceWhite : AppColors.textDark,
            ),
            const SizedBox(width: 6),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? AppColors.surfaceWhite : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
