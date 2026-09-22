import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/location/data/location_repository.dart';
import 'package:book_vardi/features/location/domain/location_hub_model.dart';
import 'package:book_vardi/features/location/presentation/controllers/location_controller.dart';
import 'package:book_vardi/features/location/presentation/widgets/location_modal_bottom_sheet.dart';
import 'package:geolocator/geolocator.dart';

class TestLocationRepository implements ILocationRepository {
  LocationHubModel saved = LocationHubModel.defaultHub;

  @override
  Future<LocationHubModel> getSavedHub() async => saved;

  @override
  Future<void> saveSelectedHub(LocationHubModel hub) async {
    saved = hub;
  }

  @override
  Future<GpsLocationResult?> determineGpsLocation() async => null;

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
  }) => 5.0;

  LocationHubModel findNearestHub({
    required double latitude,
    required double longitude,
  }) => LocationHubModel.defaultHub;
}

Widget createTestApp({required ProviderContainer container, required Widget child}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  group('LocationModalBottomSheet Widget Tests', () {
    late ProviderContainer container;
    late TestLocationRepository testRepo;

    setUp(() {
      testRepo = TestLocationRepository();
      container = ProviderContainer(
        overrides: [
          locationRepositoryProvider.overrideWithValue(testRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('renders website header, GPS button, privacy text and 2-column hubs grid',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          container: container,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LocationModalBottomSheet.show(context),
              child: const Text('Open Location Modal'),
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('Open Location Modal'));
      await tester.pumpAndSettle();

      // Header and title
      expect(find.text('Find Schools Near You'), findsOneWidget);
      expect(find.textContaining('25 km'), findsWidgets);

      // Yellow GPS Button
      expect(find.byKey(const Key('use_gps_location_button')), findsOneWidget);
      expect(find.text('Use Current GPS Location'), findsOneWidget);

      // Privacy note
      expect(
        find.textContaining('We never store or share your exact coordinates'),
        findsOneWidget,
      );

      // Divider
      expect(find.text('OR CHOOSE CITY'), findsOneWidget);

      // Popular Hubs
      expect(find.text('Kamta, Lucknow'), findsWidgets);
      expect(find.text('Jajmau, Kanpur'), findsOneWidget);
      expect(find.text('RTO, Azamgarh'), findsOneWidget);
      expect(find.text('Sector 14, Gurugram'), findsOneWidget);
      expect(find.text('Pune City'), findsOneWidget);
      expect(find.text('Mumbai Metro'), findsOneWidget);
      expect(find.text('Bengaluru / Bangalore'), findsOneWidget);

      // Bottom capsule active filter
      expect(find.textContaining('in 25 km'), findsOneWidget);
    });

    testWidgets('tapping a hub card selects it and closes the modal sheet',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          container: container,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LocationModalBottomSheet.show(context),
              child: const Text('Open Location Modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Location Modal'));
      await tester.pumpAndSettle();

      // Tap on 'Jajmau, Kanpur' chip
      await tester.tap(find.byKey(const Key('location_chip_jajmau_kanpur')));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.byType(LocationModalBottomSheet), findsNothing);

      // Selected hub should be Kanpur
      final selectedHub = container.read(selectedLocationProvider);
      expect(selectedHub.name, 'Jajmau, Kanpur');
      expect(selectedHub.city, 'Kanpur');
    });
  });
}
