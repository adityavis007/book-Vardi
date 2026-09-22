import 'package:flutter_test/flutter_test.dart';
import 'package:book_vardi/features/location/domain/location_hub_model.dart';

void main() {
  group('LocationHubModel', () {
    test('defaultHub is Kamta, Lucknow with correct defaults', () {
      const hub = LocationHubModel.defaultHub;
      expect(hub.id, 'kamta_lucknow');
      expect(hub.name, 'Kamta, Lucknow');
      expect(hub.city, 'Lucknow');
      expect(hub.state, 'Uttar Pradesh');
      expect(hub.latitude, 26.8833);
      expect(hub.longitude, 81.0167);
      expect(hub.activeSchools, 4);
      expect(hub.totalSchools, 12);
      expect(hub.radiusKm, 25.0);
    });

    test('popularHubs contains 9 predefined hubs matching website specifications', () {
      expect(LocationHubModel.popularHubs.length, 9);

      final names = LocationHubModel.popularHubs.map((h) => h.name).toList();
      expect(names, contains('Kamta, Lucknow'));
      expect(names, contains('Jajmau, Kanpur'));
      expect(names, contains('RTO, Azamgarh'));
      expect(names, contains('Sector 14, Gurugram'));
      expect(names, contains('RK Puram, New Delhi'));
      expect(names, contains('Delhi NCR (Central)'));
      expect(names, contains('Pune City'));
      expect(names, contains('Mumbai Metro'));
      expect(names, contains('Bengaluru / Bangalore'));
    });

    test('serialization toJson and fromJson round-trips correctly', () {
      const original = LocationHubModel(
        id: 'test_hub',
        name: 'Gomti Nagar, Lucknow',
        city: 'Lucknow',
        state: 'Uttar Pradesh',
        latitude: 26.8500,
        longitude: 80.9900,
        activeSchools: 3,
        totalSchools: 10,
        radiusKm: 25.0,
      );

      final json = original.toJson();
      final reconstructed = LocationHubModel.fromJson(json);

      expect(reconstructed, equals(original));
      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.city, original.city);
      expect(reconstructed.state, original.state);
      expect(reconstructed.latitude, original.latitude);
      expect(reconstructed.longitude, original.longitude);
      expect(reconstructed.activeSchools, original.activeSchools);
      expect(reconstructed.totalSchools, original.totalSchools);
      expect(reconstructed.radiusKm, original.radiusKm);
    });

    test('copyWith modifies specified fields only', () {
      const original = LocationHubModel.defaultHub;
      final updated = original.copyWith(name: 'Alambagh, Lucknow', activeSchools: 6);

      expect(updated.name, 'Alambagh, Lucknow');
      expect(updated.activeSchools, 6);
      expect(updated.id, original.id);
      expect(updated.city, original.city);
      expect(updated.latitude, original.latitude);
    });
  });
}
