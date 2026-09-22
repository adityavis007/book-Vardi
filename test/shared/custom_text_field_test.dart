import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/shared/widgets/custom_text_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }

  group('CustomTextField Component Tests', () {
    testWidgets('renders label and hintText, receives text input',
        (WidgetTester tester) async {
      String enteredText = '';

      await tester.pumpWidget(
        buildTestableWidget(
          CustomTextField(
            label: 'Email or Phone Number',
            hintText: 'Enter your email',
            onChanged: (val) => enteredText = val,
          ),
        ),
      );

      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'parent@school.com');
      await tester.pump();
      expect(enteredText, equals('parent@school.com'));
    });

    testWidgets('triggers validation error styling when form validated',
        (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        buildTestableWidget(
          Form(
            key: formKey,
            child: CustomTextField(
              label: 'Password',
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
          ),
        ),
      );

      expect(find.text('Password is required'), findsNothing);

      formKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('toggles password obscureText state on eye icon tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CustomTextField(
            label: 'Password',
            isPassword: true,
          ),
        ),
      );

      // Initially obscureText should be true
      final initialField = tester.widget<EditableText>(find.byType(EditableText));
      expect(initialField.obscureText, isTrue);

      // Tap the eye toggle button
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Now obscureText should be false
      final revealedField = tester.widget<EditableText>(find.byType(EditableText));
      expect(revealedField.obscureText, isFalse);

      // Tap again to obscure
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      final reObscuredField = tester.widget<EditableText>(find.byType(EditableText));
      expect(reObscuredField.obscureText, isTrue);
    });
  });
}
