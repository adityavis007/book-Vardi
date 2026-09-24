import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/checkout/data/address_repository.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';
import 'package:book_vardi/features/checkout/presentation/screens/add_address_screen.dart';

class MockAddressRepoForAddScreen implements IAddressRepository {
  AddressModel? lastAddedAddress;
  AddressModel? lastUpdatedAddress;

  @override
  Stream<List<AddressModel>> watchAddresses(String userId) =>
      Stream.value(const <AddressModel>[]);

  @override
  Future<List<AddressModel>> fetchAddresses(String userId) async => [];

  @override
  Future<AddressModel?> fetchDefaultAddress(String userId) async => null;

  @override
  Future<String> addAddress(String userId, AddressModel address) async {
    lastAddedAddress = address;
    return 'generated_addr_123';
  }

  @override
  Future<void> updateAddress(String userId, AddressModel address) async {
    lastUpdatedAddress = address;
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {}

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAddressRepoForAddScreen mockAddressRepo;

  setUp(() {
    mockAddressRepo = MockAddressRepoForAddScreen();
  });

  Widget createTestWidget({
    AddressModel? initialAddress,
    ValueChanged<AddressModel>? onAddressAdded,
  }) {
    return ProviderScope(
      overrides: [
        addressRepositoryProvider.overrideWithValue(mockAddressRepo),
      ],
      child: MaterialApp(
        home: AddAddressScreen(
          userId: 'test_user_1',
          initialAddress: initialAddress,
          onAddressAdded: onAddressAdded,
        ),
      ),
    );
  }

  group('AddAddressScreen Dedicated Full Page Tests', () {
    testWidgets('renders full page with AppBar, title, and all address form fields',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Add Delivery Address'), findsOneWidget);
      expect(find.byKey(const Key('add_address_back_btn')), findsOneWidget);
      expect(find.byKey(const Key('add_address_close_btn')), findsOneWidget);

      expect(find.text('Address Type'), findsOneWidget);
      expect(find.byKey(const Key('chip_type_Home')), findsOneWidget);
      expect(find.byKey(const Key('chip_type_School')), findsOneWidget);
      expect(find.byKey(const Key('chip_type_Work')), findsOneWidget);

      expect(find.byKey(const Key('field_full_name')), findsOneWidget);
      expect(find.byKey(const Key('field_phone')), findsOneWidget);
      expect(find.byKey(const Key('field_pincode')), findsOneWidget);
      expect(find.byKey(const Key('field_address_line1')), findsOneWidget);
      expect(find.byKey(const Key('field_address_line2')), findsOneWidget);
      expect(find.byKey(const Key('field_landmark')), findsOneWidget);
      expect(find.byKey(const Key('field_city')), findsOneWidget);
      expect(find.byKey(const Key('field_state')), findsOneWidget);
      expect(find.byKey(const Key('switch_is_default')), findsOneWidget);
      expect(find.byKey(const Key('save_address_button')), findsOneWidget);
    });

    testWidgets('switching address type chips updates selection',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chip_type_School')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('chip_type_Work')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('validates required fields and rejects invalid inputs',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_address_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter full name'), findsOneWidget);
      expect(find.text('Please enter 10-digit mobile number'), findsOneWidget);
      expect(find.text('Please enter 6-digit PIN code'), findsOneWidget);
      expect(find.text('Please enter your address line 1'), findsOneWidget);
    });

    testWidgets('entering 6-digit PIN code auto-populates City and State',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('field_pincode')), '122001');
      await tester.pumpAndSettle();

      expect(find.text('Gurugram'), findsWidgets);
      expect(find.text('Haryana'), findsWidgets);
    });

    testWidgets('fills form and successfully saves new address',
        (tester) async {
      AddressModel? capturedAddress;

      await tester.pumpWidget(createTestWidget(
        onAddressAdded: (addr) => capturedAddress = addr,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('field_full_name')), 'Aditya Sharma');
      await tester.enterText(
          find.byKey(const Key('field_phone')), '9876543210');
      await tester.enterText(
          find.byKey(const Key('field_pincode')), '226001');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('field_address_line1')), 'Flat 101, Gomti Nagar');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_address_button')));
      await tester.pumpAndSettle();

      expect(mockAddressRepo.lastAddedAddress, isNotNull);
      expect(mockAddressRepo.lastAddedAddress!.fullName, equals('Aditya Sharma'));
      expect(mockAddressRepo.lastAddedAddress!.city, equals('Lucknow'));
      expect(mockAddressRepo.lastAddedAddress!.state, equals('Uttar Pradesh'));
      expect(capturedAddress, isNotNull);
      expect(capturedAddress!.addressId, equals('generated_addr_123'));
    });

    testWidgets('renders Edit mode when initialAddress provided and updates address',
        (tester) async {
      const initial = AddressModel(
        addressId: 'addr_existing_99',
        fullName: 'Vikram Singh',
        phone: '9988776655',
        addressLine1: 'Villa 5, Palm Meadows',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560066',
        addressType: 'Home',
      );

      await tester.pumpWidget(createTestWidget(initialAddress: initial));
      await tester.pumpAndSettle();

      expect(find.text('Edit Delivery Address'), findsOneWidget);
      expect(find.text('Vikram Singh'), findsOneWidget);
      expect(find.text('Villa 5, Palm Meadows'), findsOneWidget);

      // Modify full name
      await tester.enterText(
          find.byKey(const Key('field_full_name')), 'Vikramaditya Singh');
      await tester.tap(find.byKey(const Key('save_address_button')));
      await tester.pumpAndSettle();

      expect(mockAddressRepo.lastUpdatedAddress, isNotNull);
      expect(mockAddressRepo.lastUpdatedAddress!.fullName,
          equals('Vikramaditya Singh'));
      expect(mockAddressRepo.lastUpdatedAddress!.addressId,
          equals('addr_existing_99'));
    });
  });
}
