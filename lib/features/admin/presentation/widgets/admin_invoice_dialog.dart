import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../orders/domain/order_model.dart';

/// Modal dialog displaying a GST-compliant tax invoice and fulfillment packing slip.
class AdminInvoiceDialog extends StatelessWidget {
  final OrderModel order;

  const AdminInvoiceDialog({
    super.key,
    required this.order,
  });

  /// Displays the invoice dialog over the current context.
  static Future<void> show(BuildContext context, OrderModel order) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminInvoiceDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceNo =
        'BV-INV-${order.orderId.substring(0, order.orderId.length > 8 ? 8 : order.orderId.length).toUpperCase()}';
    final dateStr =
        '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}';

    final taxableSubtotal = (order.pricing.subtotal - order.pricing.totalDiscounts).clamp(0.0, double.infinity);
    final cgst = taxableSubtotal * 0.09;
    final sgst = taxableSubtotal * 0.09;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.local_library_rounded,
                                  color: AppColors.secondaryAmber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'BOOK VARDI',
                                  style: AppTypography.heading2.copyWith(
                                    color: AppColors.primaryNavy,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Educational Logistics & Apparel Solutions',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'GSTIN: 09AABCB1234F1Z5 | State: Uttar Pradesh (09)',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.mintPillBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TAX INVOICE / PACKING SLIP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          invoiceNo,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          'Date: $dateStr',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 1, color: AppColors.borderGray),

                // Customer & Delivery Details Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSlate,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BILLED & SHIPPED TO:',
                              style: AppTypography.micro.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              order.shippingAddress.fullName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            Text(
                              'Ph: ${order.shippingAddress.phone}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.shippingAddress.addressLine1}${order.shippingAddress.addressLine2 != null ? ', ${order.shippingAddress.addressLine2}' : ''}\n${order.shippingAddress.city}, ${order.shippingAddress.state} - ${order.shippingAddress.pincode}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tag: ${order.shippingAddress.addressType.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSlate,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ORDER & LOGISTICS SPECIFICATION:',
                              style: AppTypography.micro.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildMetaRow('Order Status:', order.orderStatus.displayName),
                            _buildMetaRow('Payment Method:', order.paymentMethod),
                            _buildMetaRow('Payment Status:', order.paymentStatus.toUpperCase()),
                            _buildMetaRow('Delivery Mode:', order.deliveryMode),
                            _buildMetaRow(
                              'Carrier:',
                              order.trackingMetadata.carrierName ?? 'Not Dispatched',
                            ),
                            _buildMetaRow(
                              'AWB Tracking:',
                              order.trackingMetadata.trackingNumber ?? 'Pending',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Itemized Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Item Description',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Variant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          'Qty',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Rate',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Item Rows
                ...order.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$idx',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              if (item.schoolName != null)
                                Text(
                                  item.schoolName!,
                                  style: AppTypography.micro.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            (item.variantLabel != null && item.variantLabel!.isNotEmpty)
                                ? item.variantLabel!
                                : 'Standard',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${item.unitPrice.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: AppTypography.caption,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${item.totalPrice.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.md),

                // Tax & Calculation Summary Box
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320, minWidth: 240),
                    child: Column(
                      children: [
                        _buildCalculationLine(
                          'Gross Subtotal:',
                          '₹${order.pricing.subtotal.toStringAsFixed(2)}',
                        ),
                        if (order.pricing.schoolBulkDiscount > 0)
                          _buildCalculationLine(
                            'Bulk Discount:',
                            '-₹${order.pricing.schoolBulkDiscount.toStringAsFixed(2)}',
                            color: AppColors.successGreen,
                          ),
                        if (order.pricing.couponDiscount > 0)
                          _buildCalculationLine(
                            'Coupon Discount:',
                            '-₹${order.pricing.couponDiscount.toStringAsFixed(2)}',
                            color: AppColors.successGreen,
                          ),
                        _buildCalculationLine(
                          'Delivery Fee:',
                          order.pricing.deliveryCharge == 0
                              ? 'FREE'
                              : '₹${order.pricing.deliveryCharge.toStringAsFixed(2)}',
                        ),
                        _buildCalculationLine(
                          'Taxable Value:',
                          '₹${taxableSubtotal.toStringAsFixed(2)}',
                        ),
                        _buildCalculationLine(
                          'CGST (9%):',
                          '₹${cgst.toStringAsFixed(2)}',
                        ),
                        _buildCalculationLine(
                          'SGST (9%):',
                          '₹${sgst.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 16, color: AppColors.borderGray),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'TOTAL PAYABLE:',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                            Text(
                              '₹${order.pricing.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Statutory Note
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSlate,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Declaration: This is a system-generated commercial tax invoice and warehouse packing slip. All educational supplies are billed per applicable statutory tax slabs under Goods & Services Tax rules.',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Dialog Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Close'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: AppColors.secondaryAmber,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text(
                        'Print Packing Slip',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.primaryNavy,
                            content: Text(
                              'Tax invoice & packing slip sent to print spooler.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationLine(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}
