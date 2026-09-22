import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/address_model.dart';

/// Abstract contract for Customer Delivery Address operations.
abstract class IAddressRepository {
  /// Watches real-time stream of all saved delivery addresses for a user.
  Stream<List<AddressModel>> watchAddresses(String userId);

  /// Fetches a one-time list of all saved delivery addresses.
  Future<List<AddressModel>> fetchAddresses(String userId);

  /// Fetches the user's primary/default address, if one exists.
  Future<AddressModel?> fetchDefaultAddress(String userId);

  /// Adds a new delivery address for the user.
  /// If [address.isDefault] is true or this is the user's first address,
  /// atomically ensures all other addresses have `isDefault: false`.
  Future<String> addAddress(String userId, AddressModel address);

  /// Updates an existing delivery address.
  /// If [address.isDefault] is set to true, atomically unsets the default flag on other addresses.
  Future<void> updateAddress(String userId, AddressModel address);

  /// Deletes an address by [addressId].
  Future<void> deleteAddress(String userId, String addressId);

  /// Atomically sets the specified address as the default, unsetting any previous default.
  Future<void> setDefaultAddress(String userId, String addressId);
}

/// Cloud Firestore implementation of [IAddressRepository].
/// Storage location: `users/{userId}/addresses/{addressId}`.
class FirestoreAddressRepository implements IAddressRepository {
  final FirebaseFirestore _firestore;

  FirestoreAddressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _addressesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('addresses');
  }

  @override
  Stream<List<AddressModel>> watchAddresses(String userId) {
    return _addressesCollection(userId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return AddressModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort: default address first, then alphabetical/type
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.fullName.compareTo(b.fullName);
      });

      return list;
    });
  }

  @override
  Future<List<AddressModel>> fetchAddresses(String userId) async {
    final snapshot = await _addressesCollection(userId).get();
    final list = snapshot.docs.map((doc) {
      return AddressModel.fromMap(doc.data(), doc.id);
    }).toList();

    list.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return a.fullName.compareTo(b.fullName);
    });

    return list;
  }

  @override
  Future<AddressModel?> fetchDefaultAddress(String userId) async {
    final snapshot = await _addressesCollection(userId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return AddressModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    }

    // Fallback: If no explicit default, return first saved address if available
    final all = await fetchAddresses(userId);
    return all.isNotEmpty ? all.first : null;
  }

  @override
  Future<String> addAddress(String userId, AddressModel address) async {
    final col = _addressesCollection(userId);
    final existingSnapshot = await col.get();
    final bool isFirstAddress = existingSnapshot.docs.isEmpty;
    final bool shouldBeDefault = address.isDefault || isFirstAddress;

    final docRef = address.addressId.isNotEmpty
        ? col.doc(address.addressId)
        : col.doc();

    final batch = _firestore.batch();

    // If this address should be default, unset default on all other documents
    if (shouldBeDefault) {
      for (final doc in existingSnapshot.docs) {
        if (doc.data()['isDefault'] == true) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
    }

    final addressToSave = address.copyWith(
      addressId: docRef.id,
      isDefault: shouldBeDefault,
    );

    batch.set(docRef, addressToSave.toMap());
    await batch.commit();

    return docRef.id;
  }

  @override
  Future<void> updateAddress(String userId, AddressModel address) async {
    final col = _addressesCollection(userId);
    final docRef = col.doc(address.addressId);

    final batch = _firestore.batch();

    if (address.isDefault) {
      final snapshot = await col.get();
      for (final doc in snapshot.docs) {
        if (doc.id != address.addressId && doc.data()['isDefault'] == true) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
    }

    batch.update(docRef, address.toMap());
    await batch.commit();
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    final col = _addressesCollection(userId);
    final docRef = col.doc(addressId);
    final docSnapshot = await docRef.get();

    final bool wasDefault = docSnapshot.data()?['isDefault'] == true;

    final batch = _firestore.batch();
    batch.delete(docRef);

    // If we deleted the default address, promote the first remaining address to default
    if (wasDefault) {
      final snapshot = await col.get();
      final remaining = snapshot.docs.where((d) => d.id != addressId).toList();
      if (remaining.isNotEmpty) {
        batch.update(remaining.first.reference, {'isDefault': true});
      }
    }

    await batch.commit();
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    final col = _addressesCollection(userId);
    final snapshot = await col.get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      if (doc.id == addressId) {
        batch.update(doc.reference, {'isDefault': true});
      } else if (doc.data()['isDefault'] == true) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    await batch.commit();
  }
}

/// Global Riverpod provider for [IAddressRepository].
final addressRepositoryProvider = Provider<IAddressRepository>((ref) {
  return FirestoreAddressRepository();
});
