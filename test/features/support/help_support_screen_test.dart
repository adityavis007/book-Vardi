import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/support/presentation/screens/help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget() {
    return const MaterialApp(
      home: HelpSupportScreen(),
    );
  }

  group('HelpSupportScreen Widget Tests', () {
    testWidgets('renders header, quick contact options, and FAQs', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('24/7 STUDENT & PARENT SUPPORT'), findsOneWidget);
      expect(find.text('Quick Contact Options'), findsOneWidget);
      expect(find.text('Call Support Helpline'), findsOneWidget);
      expect(find.text('WhatsApp Assistance'), findsOneWidget);
      expect(find.text('Email Support'), findsOneWidget);

      // FAQs
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('How do I track my school book kit or uniform order?'), findsOneWidget);
      expect(find.text('What if the uniform size does not fit my child?'), findsOneWidget);
    });

    testWidgets('expanding an FAQ shows answer content', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final faqFinder = find.text('What if the uniform size does not fit my child?');
      await tester.ensureVisible(faqFinder);
      await tester.tap(faqFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('7-day hassle-free size exchange policy'), findsOneWidget);
    });

    testWidgets('validates and submits contact form query', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('help_support_submit_button'));
      await tester.ensureVisible(submitFinder);

      // Tap submit with empty fields -> shows validation errors
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);

      // Fill in fields
      await tester.enterText(find.byKey(const Key('help_support_name_field')), 'Aditya Sharma');
      await tester.enterText(find.byKey(const Key('help_support_contact_field')), '9876543210');
      await tester.enterText(find.byKey(const Key('help_support_message_field')), 'Need uniform size guide for Class 8');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(submitFinder);
      await tester.pump(); // Start async submit

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.textContaining('Thank you! Your query has been received'), findsOneWidget);
    });
  });
}
