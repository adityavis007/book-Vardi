import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/legal/presentation/screens/terms_conditions_screen.dart';
import 'package:book_vardi/features/legal/presentation/screens/privacy_policy_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TermsConditionsScreen Widget Tests', () {
    testWidgets('renders terms header and key legal sections', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TermsConditionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Acceptance of Terms'), findsOneWidget);
      expect(find.text('School Curriculum & Textbook Bundles'), findsOneWidget);
      expect(find.text('Uniform Sizing, Exchanges & Returns'), findsOneWidget);
      expect(find.text('Pricing, Taxes & Secure Payments'), findsOneWidget);
      expect(find.text('Shipping & Delivery Timelines'), findsOneWidget);
      expect(find.text('Questions regarding our Terms?'), findsOneWidget);
    });
  });

  group('PrivacyPolicyScreen Widget Tests', () {
    testWidgets('renders privacy header, trust pillars, and data policies', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Your Privacy Matters to Us'), findsOneWidget);
      expect(find.text('256-Bit SSL Encrypted'), findsOneWidget);
      expect(find.text('PCI-DSS Compliant'), findsOneWidget);
      expect(find.text('No Third-Party Ads'), findsOneWidget);
      expect(find.text('Student-Safe Policy'), findsOneWidget);

      expect(find.text('Information We Collect'), findsOneWidget);
      expect(find.text('How We Use Your Data'), findsOneWidget);
      expect(find.text('Payment & Financial Data Security'), findsOneWidget);
      expect(find.text('Student & Children Privacy Commitment'), findsOneWidget);
      expect(find.text('Data Grievance & Privacy Officer'), findsOneWidget);
    });
  });
}
