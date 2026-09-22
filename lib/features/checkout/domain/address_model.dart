import 'package:flutter/foundation.dart';

/// Represents a customer delivery address for Book Vardi checkout.
/// Corresponds to Firestore document in `users/{userId}/addresses/{addressId}`.
@immutable
class AddressModel {
  final String addressId;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final String? landmark;
  final String addressType; // 'Home' | 'School' | 'Work'

  const AddressModel({
    required this.addressId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    this.landmark,
    this.addressType = 'Home',
  });

  // --- Validation Regex & Helpers ---

  /// Indian mobile number regex (10 digits starting with 6-9).
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  /// Indian postal PIN code regex (6 digits, first digit 1-9).
  static final RegExp _pincodeRegex = RegExp(r'^[1-9]\d{5}$');

  /// Normalizes and validates whether [phone] is a valid 10-digit Indian mobile number.
  /// Tolerates '+91', leading '0', spaces, and dashes.
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return false;
    final cleaned = phone.replaceAll(RegExp(r'[\s\-+]'), '');
    String digits = cleaned;
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return _phoneRegex.hasMatch(digits);
  }

  /// Validates whether [pincode] is a valid 6-digit Indian postal code.
  static bool isValidPincode(String? pincode) {
    if (pincode == null || pincode.trim().isEmpty) return false;
    final cleaned = pincode.trim().replaceAll(' ', '');
    return _pincodeRegex.hasMatch(cleaned);
  }

  /// Validates full name presence and minimum length.
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Form field validator for 10-digit phone number.
  static String? validatePhoneField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter 10-digit mobile number';
    }
    if (!isValidPhone(value)) {
      return 'Please enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  /// Form field validator for 6-digit Indian PIN code.
  static String? validatePincodeField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter 6-digit PIN code';
    }
    if (!isValidPincode(value)) {
      return 'Please enter a valid 6-digit postal PIN code';
    }
    return null;
  }

  /// General required text validator.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// Whether all mandatory fields satisfy validation rules.
  bool get isValid =>
      fullName.trim().isNotEmpty &&
      isValidPhone(phone) &&
      addressLine1.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      state.trim().isNotEmpty &&
      isValidPincode(pincode);

  /// Clean human-readable multi-line or single-line address description.
  String get formattedAddress {
    final parts = <String>[
      addressLine1.trim(),
      if (addressLine2 != null && addressLine2!.trim().isNotEmpty)
        addressLine2!.trim(),
      if (landmark != null && landmark!.trim().isNotEmpty)
        landmark!.trim().toLowerCase().startsWith('near')
            ? landmark!.trim()
            : 'Near ${landmark!.trim()}',
      city.trim(),
      '$state - $pincode',
    ];
    return parts.join(', ');
  }

  AddressModel copyWith({
    String? addressId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
    String? landmark,
    String? addressType,
  }) {
    return AddressModel(
      addressId: addressId ?? this.addressId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      landmark: landmark ?? this.landmark,
      addressType: addressType ?? this.addressType,
    );
  }

  factory AddressModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AddressModel(
      addressId: (map['addressId'] as String?) ?? docId ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      addressLine1: (map['addressLine1'] as String?) ?? '',
      addressLine2: map['addressLine2'] as String?,
      city: (map['city'] as String?) ?? '',
      state: (map['state'] as String?) ?? '',
      pincode: (map['pincode'] as String?) ?? '',
      isDefault: (map['isDefault'] as bool?) ?? false,
      landmark: map['landmark'] as String?,
      addressType: (map['addressType'] as String?) ?? 'Home',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addressId': addressId,
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isDefault': isDefault,
      'landmark': landmark,
      'addressType': addressType,
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> json, [String? docId]) =>
      AddressModel.fromMap(json, docId);

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressModel &&
        other.addressId == addressId &&
        other.fullName == fullName &&
        other.phone == phone &&
        other.addressLine1 == addressLine1 &&
        other.addressLine2 == addressLine2 &&
        other.city == city &&
        other.state == state &&
        other.pincode == pincode &&
        other.isDefault == isDefault &&
        other.landmark == landmark &&
        other.addressType == addressType;
  }

  @override
  int get hashCode => Object.hash(
        addressId,
        fullName,
        phone,
        addressLine1,
        addressLine2,
        city,
        state,
        pincode,
        isDefault,
        landmark,
        addressType,
      );

  @override
  String toString() {
    return 'AddressModel(addressId: $addressId, fullName: $fullName, phone: $phone, pincode: $pincode, isDefault: $isDefault)';
  }
}
