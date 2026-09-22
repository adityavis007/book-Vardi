import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/location/data/location_repository.dart';
import 'package:book_vardi/features/location/domain/location_hub_model.dart';
import 'package:book_vardi/features/location/presentation/controllers/location_controller.dart';
import 'package:geolocator/geolocator.dart';

class MockLocationRepository implements ILocationRepository {
  LocationHubModel savedHub = LocationHubModel.defaultHub;
  GpsLocationResult? mockGpsResult;
  bool shouldThrowGps = false;

  @override
  Future<LocationHubModel> getSavedHub() async => savedHub;

  @override
  Future<void> saveSelectedHub(LocationHubModel hub) async {
    savedHub = hub;
  }

  @override
  Future<GpsLocationResult?> determineGpsLocation() async {
    if (shouldThrowGps) {
      throw Exception('Location service disabled');
    }
    return mockGpsResult;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  double calculateDistanceKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return 10.0;
  }

  LocationHubModel findNearestHub({
    required double latitude,
    required double longitude,
  }) {
    return LocationHubModel.defaultHub;
  }
}

void main() {
  group('LocationController', () {
    late MockLocationRepository mockRepo;
    late LocationController controller;

    setUp(() {
      mockRepo = MockLocationRepository();
      controller = LocationController(mockRepo);
    });

    test('initial state has default hub and not prompted', () async {
      expect(controller.state.currentHub, LocationHubModel.defaultHub);
      expect(controller.state.isLoadingGps, false);
      expect(controller.state.hasPromptedAutoThisSession, false);
      expect(controller.state.errorMessage, isNull);
    });

    test('selectHub updates state and persists hub to repository', () async {
      const kanpurHub = LocationHubModel(
        id: 'jajmau_kanpur',
        name: 'Jajmau, Kanpur',
        city: 'Kanpur',
        state: 'Uttar Pradesh',
        latitude: 26.4333,
        longitude: 80.4000,
      );

      await controller.selectHub(kanpurHub);

      expect(controller.state.currentHub, kanpurHub);
      expect(mockRepo.savedHub, kanpurHub);
      expect(controller.state.errorMessage, isNull);
    });

    test('useCurrentGpsLocation updates hub and persists on success', () async {
      const detectedHub = LocationHubModel(
        id: 'pune_city',
        name: 'Pune City',
        city: 'Pune',
        state: 'Maharashtra',
        latitude: 18.5204,
        longitude: 73.8567,
      );

      mockRepo.mockGpsResult = const GpsLocationResult(
        hub: detectedHub,
        resolvedLocalityName: 'Shivajinagar, Pune',
        distanceKm: 2.5,
        isWithinOperationalRadius: true,
      );

      final result = await controller.useCurrentGpsLocation();

      expect(result, isNotNull);
      expect(result!.hub, detectedHub);
      expect(controller.state.currentHub, detectedHub);
      expect(controller.state.isLoadingGps, false);
      expect(mockRepo.savedHub, detectedHub);
    });

    test('useCurrentGpsLocation sets error message on permission denial', () async {
      mockRepo.mockGpsResult = null;

      final result = await controller.useCurrentGpsLocation();

      expect(result, isNull);
      expect(controller.state.isLoadingGps, false);
      expect(controller.state.errorMessage, contains('Location permission was not granted'));
    });

    test('markPromptedThisSession updates hasPromptedAutoThisSession to true', () {
      expect(controller.state.hasPromptedAutoThisSession, false);
      controller.markPromptedThisSession();
      expect(controller.state.hasPromptedAutoThisSession, true);
    });
  });
}
