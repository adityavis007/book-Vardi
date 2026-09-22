import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/checkout/data/address_repository.dart';
import 'package:book_vardi/features/checkout/domain/address_model.dart';

/// In-memory mock implementation of [IAddressRepository] for testing atomic
/// default address constraints and real-time streams without live Firebase.
class MockAddressRepository implements IAddressRepository {
  final Map<String, Map<String, AddressModel>> _addresses = {};
  final Map<String, StreamController<List<AddressModel>>> _controllers = {};
  int _idCounter = 1;

  StreamController<List<AddressModel>> _getController(String userId) {
    return _controllers.putIfAbsent(
      userId,
      () => StreamController<List<AddressModel>>.broadcast(),
    );
  }

  List<AddressModel> _sortedAddresses(String userId) {
    final list = (_addresses[userId]?.values.toList() ?? []);
    list.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return a.fullName.compareTo(b.fullName);
    });
    return list;
  }

  void _notify(String userId) {
    final list = _sortedAddresses(userId);
    _getController(userId).add(List.unmodifiable(list));
  }

  @override
  Stream<List<AddressModel>> watchAddresses(String userId) {
    final controller = _getController(userId);
    Timer.run(() {
      final list = _sortedAddresses(userId);
      controller.add(List.unmodifiable(list));
    });
    return controller.stream;
  }

  @override
  Future<List<AddressModel>> fetchAddresses(String userId) async {
    return List.unmodifiable(_sortedAddresses(userId));
  }

  @override
  Future<AddressModel?> fetchDefaultAddress(String userId) async {
    final userAddresses = _addresses[userId]?.values.toList() ?? [];
    for (final addr in userAddresses) {
      if (addr.isDefault) return addr;
    }
    final sorted = _sortedAddresses(userId);
    return sorted.isNotEmpty ? sorted.first : null;
  }

  @override
  Future<String> addAddress(String userId, AddressModel address) async {
    final userAddresses = _addresses.putIfAbsent(userId, () => {});
    final isFirst = userAddresses.isEmpty;
    final shouldBeDefault = address.isDefault || isFirst;

    final id = address.addressId.isNotEmpty
        ? address.addressId
        : 'addr_${_idCounter++}';

    // Atomically unset other defaults if this becomes default
    if (shouldBeDefault) {
      for (final key in userAddresses.keys) {
        if (userAddresses[key]!.isDefault) {
          userAddresses[key] = userAddresses[key]!.copyWith(isDefault: false);
        }
      }
    }

    final saved = address.copyWith(
      addressId: id,
      isDefault: shouldBeDefault,
    );

    userAddresses[id] = saved;
    _notify(userId);
    return id;
  }

  @override
  Future<void> updateAddress(String userId, AddressModel address) async {
    final userAddresses = _addresses[userId];
    if (userAddresses == null || !userAddresses.containsKey(address.addressId)) {
      return;
    }

    if (address.isDefault) {
      for (final key in userAddresses.keys) {
        if (key != address.addressId && userAddresses[key]!.isDefault) {
          userAddresses[key] = userAddresses[key]!.copyWith(isDefault: false);
        }
      }
    }

    userAddresses[address.addressId] = address;
    _notify(userId);
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    final userAddresses = _addresses[userId];
    if (userAddresses == null) return;

    final wasDefault = userAddresses[addressId]?.isDefault ?? false;
    userAddresses.remove(addressId);

    // If deleted address was default, auto-promote first remaining address
    if (wasDefault && userAddresses.isNotEmpty) {
      final firstKey = userAddresses.keys.first;
      userAddresses[firstKey] = userAddresses[firstKey]!.copyWith(isDefault: true);
    }

    _notify(userId);
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    final userAddresses = _addresses[userId];
    if (userAddresses == null || !userAddresses.containsKey(addressId)) {
      return;
    }

    for (final key in userAddresses.keys) {
      final isTarget = key == addressId;
      userAddresses[key] = userAddresses[key]!.copyWith(isDefault: isTarget);
    }

    _notify(userId);
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}

void main() {
  group('AddressRepository & FirestoreAddressRepository Tests', () {
    late MockAddressRepository repo;
    const userId = 'user_aditya_test';

    const homeAddress = AddressModel(
      addressId: 'addr_home',
      fullName: 'Aditya Sharma',
      phone: '9876543210',
      addressLine1: 'Flat 402, Royal Palms',
      addressLine2: 'Sector 14',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122001',
      landmark: 'Near Huda City Centre',
      addressType: 'Home',
      isDefault: false,
    );

    const schoolAddress = AddressModel(
      addressId: 'addr_school',
      fullName: 'Aditya (DPS Campus)',
      phone: '9812345678',
      addressLine1: 'Delhi Public School Main Gate',
      addressLine2: 'Security Desk',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122002',
      addressType: 'School',
      isDefault: false,
    );

    const officeAddress = AddressModel(
      addressId: 'addr_office',
      fullName: 'Aditya Workplace',
      phone: '9876500000',
      addressLine1: 'Cyber Hub Building 10',
      city: 'Gurugram',
      state: 'Haryana',
      pincode: '122003',
      addressType: 'Work',
      isDefault: false,
    );

    setUp(() {
      repo = MockAddressRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('initial fetchAddresses returns empty list', () async {
      final addresses = await repo.fetchAddresses(userId);
      expect(addresses, isEmpty);
    });

    test('fetchDefaultAddress returns null when no addresses exist', () async {
      final defaultAddr = await repo.fetchDefaultAddress(userId);
      expect(defaultAddr, isNull);
    });

    test('addAddress automatically sets isDefault to true for the first saved address', () async {
      final id = await repo.addAddress(userId, homeAddress.copyWith(isDefault: false));
      expect(id, equals('addr_home'));

      final addresses = await repo.fetchAddresses(userId);
      expect(addresses, hasLength(1));
      expect(addresses.first.isDefault, isTrue);

      final defaultAddr = await repo.fetchDefaultAddress(userId);
      expect(defaultAddr, isNotNull);
      expect(defaultAddr!.addressId, equals('addr_home'));
    });

    test('addAddress with isDefault: false keeps first address as default', () async {
      await repo.addAddress(userId, homeAddress); // first address auto-becomes default
      await repo.addAddress(userId, schoolAddress.copyWith(isDefault: false));

      final addresses = await repo.fetchAddresses(userId);
      expect(addresses, hasLength(2));

      final home = addresses.firstWhere((a) => a.addressId == 'addr_home');
      final school = addresses.firstWhere((a) => a.addressId == 'addr_school');

      expect(home.isDefault, isTrue);
      expect(school.isDefault, isFalse);
    });

    test('addAddress with isDefault: true atomically unsets previous default flag', () async {
      await repo.addAddress(userId, homeAddress); // home becomes default

      // Add school address marked as default
      await repo.addAddress(userId, schoolAddress.copyWith(isDefault: true));

      final addresses = await repo.fetchAddresses(userId);
      expect(addresses, hasLength(2));

      final home = addresses.firstWhere((a) => a.addressId == 'addr_home');
      final school = addresses.firstWhere((a) => a.addressId == 'addr_school');

      // Previous default must now be false
      expect(home.isDefault, isFalse);
      // New default must be true
      expect(school.isDefault, isTrue);

      final defaultAddr = await repo.fetchDefaultAddress(userId);
      expect(defaultAddr!.addressId, equals('addr_school'));
    });

    test('setDefaultAddress atomically sets specified address and unsets previous', () async {
      await repo.addAddress(userId, homeAddress);
      await repo.addAddress(userId, schoolAddress.copyWith(isDefault: true)); // school is default
      await repo.addAddress(userId, officeAddress.copyWith(isDefault: false));

      var addresses = await repo.fetchAddresses(userId);
      expect(addresses.firstWhere((a) => a.addressId == 'addr_school').isDefault, isTrue);
      expect(addresses.firstWhere((a) => a.addressId == 'addr_home').isDefault, isFalse);

      // Atomically set home as default
      await repo.setDefaultAddress(userId, 'addr_home');

      addresses = await repo.fetchAddresses(userId);
      expect(addresses.firstWhere((a) => a.addressId == 'addr_home').isDefault, isTrue);
      expect(addresses.firstWhere((a) => a.addressId == 'addr_school').isDefault, isFalse);
      expect(addresses.firstWhere((a) => a.addressId == 'addr_office').isDefault, isFalse);

      // Verify exactly 1 address is default
      final defaultCount = addresses.where((a) => a.isDefault).length;
      expect(defaultCount, equals(1));
    });

    test('updateAddress with isDefault: true atomically clears other defaults', () async {
      await repo.addAddress(userId, homeAddress);
      await repo.addAddress(userId, schoolAddress.copyWith(isDefault: false));

      // Home is default. Update school with isDefault: true
      await repo.updateAddress(userId, schoolAddress.copyWith(isDefault: true));

      final addresses = await repo.fetchAddresses(userId);
      expect(addresses.firstWhere((a) => a.addressId == 'addr_school').isDefault, isTrue);
      expect(addresses.firstWhere((a) => a.addressId == 'addr_home').isDefault, isFalse);
    });

    test('deleteAddress removes address', () async {
      await repo.addAddress(userId, homeAddress);
      await repo.addAddress(userId, schoolAddress.copyWith(isDefault: false));

      await repo.deleteAddress(userId, 'addr_school');

      final addresses = await repo.fetchAddresses(userId);
      expect(addresses, hasLength(1));
      expect(addresses.first.addressId, equals('addr_home'));
    });

    test('deleteAddress auto-promotes remaining address when default is deleted', () async {
      await repo.addAddress(userId, homeAddress); // default
      await repo.addAddress(userId, schoolAddress.copyWith(isDefault: false));

      // Delete the default address
      await repo.deleteAddress(userId, 'addr_home');

      final addresses = await repo.fetchAddresses(userId);
      expect(addresses, hasLength(1));
      expect(addresses.first.addressId, equals('addr_school'));
      expect(addresses.first.isDefault, isTrue);

      final defaultAddr = await repo.fetchDefaultAddress(userId);
      expect(defaultAddr!.addressId, equals('addr_school'));
    });

    test('watchAddresses emits real-time updates with default address sorted first', () async {
      final emitted = <List<AddressModel>>[];
      final sub = repo.watchAddresses(userId).listen((list) {
        emitted.add(list);
      });

      await repo.addAddress(userId, homeAddress);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await repo.addAddress(userId, schoolAddress.copyWith(isDefault: true));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted, isNotEmpty);
      final latest = emitted.last;
      expect(latest, hasLength(2));
      // School is default, so it must be first in the sorted list
      expect(latest.first.addressId, equals('addr_school'));
      expect(latest.first.isDefault, isTrue);
      expect(latest.last.addressId, equals('addr_home'));

      await sub.cancel();
    });

    test('addressRepositoryProvider provides IAddressRepository in Riverpod container', () {
      final container = ProviderContainer(
        overrides: [
          addressRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final instance = container.read(addressRepositoryProvider);
      expect(instance, isA<IAddressRepository>());
      container.dispose();
    });
  });
}
