import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';

void main() {
  group('AddressModel Phone Validation Tests', () {
    test('validates standard 10-digit Indian mobile numbers starting with 6-9', () {
      expect(AddressModel.isValidPhone('9876543210'), isTrue);
      expect(AddressModel.isValidPhone('8123456789'), isTrue);
      expect(AddressModel.isValidPhone('7001234567'), isTrue);
      expect(AddressModel.isValidPhone('6200112233'), isTrue);
    });

    test('tolerates +91 prefix, leading 0, spaces, and hyphens', () {
      expect(AddressModel.isValidPhone('+919876543210'), isTrue);
      expect(AddressModel.isValidPhone('+91 98765 43210'), isTrue);
      expect(AddressModel.isValidPhone('09876543210'), isTrue);
      expect(AddressModel.isValidPhone('98765-43210'), isTrue);
    });

    test('rejects numbers starting with invalid digits (0-5)', () {
      expect(AddressModel.isValidPhone('5876543210'), isFalse);
      expect(AddressModel.isValidPhone('1234567890'), isFalse);
      expect(AddressModel.isValidPhone('0000000000'), isFalse);
      expect(AddressModel.isValidPhone('4876543210'), isFalse);
    });

    test('rejects numbers with invalid lengths or non-numeric characters', () {
      expect(AddressModel.isValidPhone('987654321'), isFalse); // 9 digits
      expect(AddressModel.isValidPhone('98765432100'), isFalse); // 11 digits without prefix
      expect(AddressModel.isValidPhone('98765abcde'), isFalse);
      expect(AddressModel.isValidPhone(''), isFalse);
      expect(AddressModel.isValidPhone('   '), isFalse);
      expect(AddressModel.isValidPhone(null), isFalse);
    });

    test('form field validator returns error message for invalid phone', () {
      expect(AddressModel.validatePhoneField(null), equals('Please enter 10-digit mobile number'));
      expect(AddressModel.validatePhoneField(''), equals('Please enter 10-digit mobile number'));
      expect(AddressModel.validatePhoneField('12345'), equals('Please enter a valid 10-digit Indian mobile number'));
      expect(AddressModel.validatePhoneField('9876543210'), isNull);
    });
  });

  group('AddressModel PIN Code Validation Tests', () {
    test('validates standard 6-digit Indian PIN codes', () {
      expect(AddressModel.isValidPincode('110001'), isTrue); // New Delhi
      expect(AddressModel.isValidPincode('400001'), isTrue); // Mumbai
      expect(AddressModel.isValidPincode('560001'), isTrue); // Bengaluru
      expect(AddressModel.isValidPincode('700001'), isTrue); // Kolkata
      expect(AddressModel.isValidPincode('600001'), isTrue); // Chennai
      expect(AddressModel.isValidPincode(' 110001 '), isTrue); // with whitespace
    });

    test('rejects PIN codes starting with 0', () {
      expect(AddressModel.isValidPincode('010001'), isFalse);
      expect(AddressModel.isValidPincode('000000'), isFalse);
    });

    test('rejects PIN codes with invalid lengths or letters', () {
      expect(AddressModel.isValidPincode('11000'), isFalse); // 5 digits
      expect(AddressModel.isValidPincode('1100011'), isFalse); // 7 digits
      expect(AddressModel.isValidPincode('11000A'), isFalse);
      expect(AddressModel.isValidPincode('ABCDEF'), isFalse);
      expect(AddressModel.isValidPincode(''), isFalse);
      expect(AddressModel.isValidPincode('   '), isFalse);
      expect(AddressModel.isValidPincode(null), isFalse);
    });

    test('form field validator returns error message for invalid PIN code', () {
      expect(AddressModel.validatePincodeField(null), equals('Please enter 6-digit PIN code'));
      expect(AddressModel.validatePincodeField(''), equals('Please enter 6-digit PIN code'));
      expect(AddressModel.validatePincodeField('123'), equals('Please enter a valid 6-digit postal PIN code'));
      expect(AddressModel.validatePincodeField('110001'), isNull);
    });
  });

  group('AddressModel Serialization & Formatting Tests', () {
    const validAddress = AddressModel(
      addressId: 'addr_1',
      fullName: 'Rahul Verma',
      phone: '9876543210',
      addressLine1: 'Flat 402, Sunshine Apartments',
      addressLine2: 'Sector 14',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122001',
      isDefault: true,
      landmark: 'Near City Park',
      addressType: 'Home',
    );

    test('isValid returns true for fully populated valid address', () {
      expect(validAddress.isValid, isTrue);
    });

    test('isValid returns false if phone or pincode is invalid', () {
      final invalidPhone = validAddress.copyWith(phone: '12345');
      expect(invalidPhone.isValid, isFalse);

      final invalidPin = validAddress.copyWith(pincode: '012200');
      expect(invalidPin.isValid, isFalse);

      final emptyName = validAddress.copyWith(fullName: '  ');
      expect(emptyName.isValid, isFalse);
    });

    test('formats address cleanly with all components', () {
      expect(
        validAddress.formattedAddress,
        equals(
          'Flat 402, Sunshine Apartments, Sector 14, Near City Park, Gurugram, Haryana - 122001',
        ),
      );
    });

    test('roundtrip serialization toMap / fromMap produces identical object', () {
      final map = validAddress.toMap();
      final reconstructed = AddressModel.fromMap(map);

      expect(reconstructed, equals(validAddress));
      expect(reconstructed.addressId, equals('addr_1'));
      expect(reconstructed.fullName, equals('Rahul Verma'));
      expect(reconstructed.isDefault, isTrue);
    });

    test('roundtrip serialization toJson / fromJson produces identical object', () {
      final json = validAddress.toJson();
      final reconstructed = AddressModel.fromJson(json);

      expect(reconstructed, equals(validAddress));
    });

    test('copyWith produces modified copy while preserving unchanged fields', () {
      final modified = validAddress.copyWith(
        fullName: 'Aman Verma',
        isDefault: false,
      );

      expect(modified.fullName, equals('Aman Verma'));
      expect(modified.isDefault, isFalse);
      expect(modified.phone, equals(validAddress.phone));
      expect(modified.pincode, equals(validAddress.pincode));
    });
  });
}
