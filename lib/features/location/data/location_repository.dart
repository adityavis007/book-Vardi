import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/location_hub_model.dart';

/// Result of resolving the user's current GPS position.
class GpsLocationResult {
  final LocationHubModel hub;
  final String? resolvedLocalityName;
  final double distanceKm;
  final bool isWithinOperationalRadius;

  const GpsLocationResult({
    required this.hub,
    this.resolvedLocalityName,
    required this.distanceKm,
    required this.isWithinOperationalRadius,
  });
}

/// Abstract contract for Location data and GPS resolution.
abstract class ILocationRepository {
  Future<LocationHubModel> getSavedHub();
  Future<void> saveSelectedHub(LocationHubModel hub);
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<bool> isLocationServiceEnabled();
  Future<GpsLocationResult?> determineGpsLocation();
}

class LocationRepository implements ILocationRepository {
  static const String _kSelectedHubKey = 'bv_selected_location_hub_v1';
  final SharedPreferences? prefs;

  LocationRepository({this.prefs});

  static Future<LocationRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocationRepository(prefs: prefs);
  }

  SharedPreferences? get _safePrefs => prefs;

  @override
  Future<LocationHubModel> getSavedHub() async {
    try {
      final prefs = _safePrefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSelectedHubKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        return LocationHubModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[LocationRepository] Failed to load saved hub: $e');
    }
    return LocationHubModel.defaultHub;
  }

  @override
  Future<void> saveSelectedHub(LocationHubModel hub) async {
    try {
      final prefs = _safePrefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_kSelectedHubKey, jsonEncode(hub.toJson()));
    } catch (e) {
      debugPrint('[LocationRepository] Failed to save selected hub: $e');
    }
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<GpsLocationResult?> determineGpsLocation() async {
    // 1. Verify service enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // 2. Verify permission
    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // 3. Get accurate current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    // 4. Reverse Geocode for exact locality
    String? localityName;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final subLocality = place.subLocality?.trim();
        final locality = place.locality?.trim();

        if (subLocality != null && subLocality.isNotEmpty && locality != null) {
          localityName = '$subLocality, $locality';
        } else if (locality != null && locality.isNotEmpty) {
          localityName = locality;
        }
      }
    } catch (e) {
      debugPrint('[LocationRepository] Reverse geocoding fallback: $e');
    }

    // 5. Match nearest hub among popular operational hubs
    LocationHubModel nearestHub = LocationHubModel.defaultHub;
    double minDistanceMeters = double.infinity;

    for (final hub in LocationHubModel.popularHubs) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        hub.latitude,
        hub.longitude,
      );
      if (distance < minDistanceMeters) {
        minDistanceMeters = distance;
        nearestHub = hub;
      }
    }

    final distanceKm = minDistanceMeters / 1000.0;
    final isWithinRadius = distanceKm <= nearestHub.radiusKm;

    LocationHubModel finalHub = nearestHub;
    if (localityName != null && localityName.isNotEmpty && isWithinRadius) {
      finalHub = LocationHubModel(
        id: 'gps_${nearestHub.id}',
        name: localityName,
        city: nearestHub.city,
        state: nearestHub.state,
        latitude: position.latitude,
        longitude: position.longitude,
        activeSchools: nearestHub.activeSchools,
        totalSchools: nearestHub.totalSchools,
        radiusKm: nearestHub.radiusKm,
      );
    }

    return GpsLocationResult(
      hub: finalHub,
      resolvedLocalityName: localityName,
      distanceKm: distanceKm,
      isWithinOperationalRadius: isWithinRadius,
    );
  }
}

/// Riverpod provider for [ILocationRepository]
final locationRepositoryProvider = Provider<ILocationRepository>((ref) {
  return LocationRepository();
});
