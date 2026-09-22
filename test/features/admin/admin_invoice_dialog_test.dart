import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/admin/presentation/widgets/admin_invoice_dialog.dart';
import 'package:book_vardi/features/cart/domain/cart_item_model.dart';
import 'package:book_vardi/features/cart/domain/price_breakup_model.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/orders/domain/order_model.dart';
import 'package:book_vardi/features/orders/domain/tracking_step_model.dart';

void main() {
  final sampleOrder = OrderModel(
    orderId: 'ORD-987654321',
    userId: 'user_cust_1',
    items: const [
      CartItemModel(
        productId: 'p_unif_1',
        productName: 'Boys Summer Uniform Navy',
        schoolName: 'St. Xavier School',
        variantLabel: 'Size 30',
        unitPrice: 450.0,
        quantity: 2,
      ),
      CartItemModel(
        productId: 'p_book_1',
        productName: 'Class 4 Math Magic',
        schoolName: 'All Schools',
        variantLabel: 'Paperback',
        unitPrice: 160.0,
        quantity: 1,
      ),
    ],
    shippingAddress: const AddressModel(
      addressId: 'addr_1',
      fullName: 'Sunita Verma',
      phone: '9812345678',
      addressLine1: 'House 24, Civil Lines',
      city: 'Kanpur',
      state: 'Uttar Pradesh',
      pincode: '208001',
      addressType: 'Home',
    ),
    pricing: const PriceBreakupModel(
      subtotal: 1060.0, // (450*2 + 160)
      schoolBulkDiscount: 60.0,
      deliveryCharge: 0.0,
      grandTotal: 1000.0,
    ),
    deliveryMode: 'Standard Courier',
    paymentMethod: 'RAZORPAY',
    paymentStatus: 'paid',
    orderStatus: OrderStatus.shipped,
    createdAt: DateTime(2026, 9, 19, 14, 30),
    estimatedDeliveryDate: DateTime(2026, 9, 23),
    trackingMetadata: const TrackingMetadata(
      carrierName: 'BlueDart Express',
      trackingNumber: 'BLU8829103IN',
    ),
  );

  group('TASK-062: Admin Invoice Dialog Tests', () {
    testWidgets('renders GST invoice details, addresses, itemized rows, and taxes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AdminInvoiceDialog.show(context, sampleOrder),
                child: const Text('Show Invoice'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Invoice'));
      await tester.pumpAndSettle();

      // Verify Header details
      expect(find.text('BOOK VARDI'), findsOneWidget);
      expect(find.textContaining('GSTIN: 09AABCB1234F1Z5'), findsOneWidget);
      expect(find.text('TAX INVOICE / PACKING SLIP'), findsOneWidget);
      expect(find.textContaining('BV-INV-ORD-9876'), findsOneWidget);

      // Verify Billed & Shipped To details
      expect(find.text('Sunita Verma'), findsOneWidget);
      expect(find.text('Ph: 9812345678'), findsOneWidget);
      expect(find.textContaining('Kanpur, Uttar Pradesh - 208001'), findsOneWidget);

      // Verify Itemized rows
      expect(find.text('Boys Summer Uniform Navy'), findsOneWidget);
      expect(find.text('Size 30'), findsOneWidget);
      expect(find.text('Class 4 Math Magic'), findsOneWidget);
      expect(find.text('Paperback'), findsOneWidget);

      // Verify Tax & Totals Breakdown
      expect(find.text('Gross Subtotal:'), findsOneWidget);
      expect(find.text('₹1060.00'), findsOneWidget);
      expect(find.text('Bulk Discount:'), findsOneWidget);
      expect(find.text('-₹60.00'), findsOneWidget);
      expect(find.text('TOTAL PAYABLE:'), findsOneWidget);
      expect(find.text('₹1000.00'), findsNWidgets(2));

      // Verify Print Packing Slip CTA
      final printBtn = find.text('Print Packing Slip');
      expect(printBtn, findsOneWidget);
      await tester.ensureVisible(printBtn);
      await tester.pumpAndSettle();
      await tester.tap(printBtn);
      await tester.pump();

      expect(find.textContaining('sent to print spooler'), findsOneWidget);
    });
  });
}
