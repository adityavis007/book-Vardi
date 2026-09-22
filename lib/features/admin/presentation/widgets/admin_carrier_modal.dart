import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../orders/domain/tracking_step_model.dart';
import '../controllers/admin_controller.dart';

/// Modal bottom sheet for assigning logistics carrier and AWB tracking code before dispatch.
class AdminCarrierModal extends ConsumerStatefulWidget {
  final String orderId;
  final String? initialCarrier;
  final String? initialTrackingNumber;

  const AdminCarrierModal({
    super.key,
    required this.orderId,
    this.initialCarrier,
    this.initialTrackingNumber,
  });

  /// Displays the carrier assignment modal sheet. Returns true if order was dispatched.
  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    String? initialCarrier,
    String? initialTrackingNumber,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AdminCarrierModal(
          orderId: orderId,
          initialCarrier: initialCarrier,
          initialTrackingNumber: initialTrackingNumber,
        ),
      ),
    );
  }

  @override
  ConsumerState<AdminCarrierModal> createState() => _AdminCarrierModalState();
}

class _AdminCarrierModalState extends ConsumerState<AdminCarrierModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _trackingController;
  late final TextEditingController _customCarrierController;

  static const List<String> _commonCarriers = [
    'BlueDart Express',
    'Delhivery',
    'DTDC',
    'India Post Speed Post',
    'Shadowfax',
    'In-House Logistics',
    'Other',
  ];

  late String _selectedCarrier;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCarrier = widget.initialCarrier != null &&
            _commonCarriers.contains(widget.initialCarrier)
        ? widget.initialCarrier!
        : _commonCarriers.first;

    _trackingController =
        TextEditingController(text: widget.initialTrackingNumber ?? '');
    _customCarrierController = TextEditingController(
      text: widget.initialCarrier != null &&
              !_commonCarriers.contains(widget.initialCarrier)
          ? widget.initialCarrier
          : '',
    );

    if (widget.initialCarrier != null &&
        !_commonCarriers.contains(widget.initialCarrier)) {
      _selectedCarrier = 'Other';
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _customCarrierController.dispose();
    super.dispose();
  }

  Future<void> _submitDispatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final finalCarrier = _selectedCarrier == 'Other'
        ? _customCarrierController.text.trim()
        : _selectedCarrier;
    final finalAwb = _trackingController.text.trim();

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updateOrderStatus(
        widget.orderId,
        OrderStatus.shipped,
        carrierName: finalCarrier,
        trackingNumber: finalAwb,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.successGreen,
            content: Text(
              'Order marked as SHIPPED with $finalCarrier (AWB: $finalAwb).',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.destructiveRed,
            content: Text('Failed to dispatch order: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryAmber.withValues(alpha: 0.18),
                      borderRadius: AppSpacing.roundedSmall,
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.primaryNavy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispatch Order',
                          style: AppTypography.heading2.copyWith(
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Order ID: #${widget.orderId.length > 12 ? widget.orderId.substring(0, 12) : widget.orderId}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'SELECT COURIER PARTNER',
                style: AppTypography.micro.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonCarriers.map((carrier) {
                  final isSelected = _selectedCarrier == carrier;
                  return ChoiceChip(
                    label: Text(carrier),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCarrier = carrier);
                      }
                    },
                    selectedColor: AppColors.primaryNavy,
                    backgroundColor: AppColors.backgroundSlate,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primaryNavy,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryNavy : AppColors.borderGray,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedCarrier == 'Other') ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _customCarrierController,
                  decoration: const InputDecoration(
                    labelText: 'Courier Partner Name *',
                    hintText: 'e.g. Professional Couriers',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (_selectedCarrier == 'Other' &&
                        (val == null || val.trim().isEmpty)) {
                      return 'Please specify courier partner';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'TRACKING / AWB AIRWAY BILL NUMBER',
                style: AppTypography.micro.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _trackingController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'AWB / Tracking Number *',
                  hintText: 'e.g. BLU78291039IN or DEL992831',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'AWB / Tracking number is required for dispatch';
                  }
                  if (val.trim().length < 4) {
                    return 'Tracking number must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: AppColors.secondaryAmber,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving ? null : _submitDispatch,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.secondaryAmber,
                              ),
                            )
                          : const Text(
                              'Confirm Dispatch & Ship',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
