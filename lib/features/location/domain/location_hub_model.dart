import 'package:flutter/foundation.dart';

/// Represents an operational service hub in Book Vardi.
@immutable
class LocationHubModel {
  final String id;
  final String name;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final int activeSchools;
  final int totalSchools;
  final double radiusKm;

  const LocationHubModel({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.activeSchools = 4,
    this.totalSchools = 12,
    this.radiusKm = 25.0,
  });

  LocationHubModel copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    int? activeSchools,
    int? totalSchools,
    double? radiusKm,
  }) {
    return LocationHubModel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      activeSchools: activeSchools ?? this.activeSchools,
      totalSchools: totalSchools ?? this.totalSchools,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }

  /// Default starting hub when user has not yet specified a location
  static const LocationHubModel defaultHub = LocationHubModel(
    id: 'kamta_lucknow',
    name: 'Kamta, Lucknow',
    city: 'Lucknow',
    state: 'Uttar Pradesh',
    latitude: 26.8833,
    longitude: 81.0167,
    activeSchools: 4,
    totalSchools: 12,
  );

  /// Predefined Popular Cities & Hubs matching the website catalog modal
  static const List<LocationHubModel> popularHubs = [
    LocationHubModel(
      id: 'kamta_lucknow',
      name: 'Kamta, Lucknow',
      city: 'Lucknow',
      state: 'Uttar Pradesh',
      latitude: 26.8833,
      longitude: 81.0167,
      activeSchools: 4,
      totalSchools: 12,
    ),
    LocationHubModel(
      id: 'jajmau_kanpur',
      name: 'Jajmau, Kanpur',
      city: 'Kanpur',
      state: 'Uttar Pradesh',
      latitude: 26.4333,
      longitude: 80.4000,
      activeSchools: 3,
      totalSchools: 9,
    ),
    LocationHubModel(
      id: 'rto_azamgarh',
      name: 'RTO, Azamgarh',
      city: 'Azamgarh',
      state: 'Uttar Pradesh',
      latitude: 26.0687,
      longitude: 83.1859,
      activeSchools: 2,
      totalSchools: 6,
    ),
    LocationHubModel(
      id: 'sec14_gurugram',
      name: 'Sector 14, Gurugram',
      city: 'Gurugram',
      state: 'Haryana',
      latitude: 28.4732,
      longitude: 77.0422,
      activeSchools: 5,
      totalSchools: 15,
    ),
    LocationHubModel(
      id: 'rk_puram_delhi',
      name: 'RK Puram, New Delhi',
      city: 'New Delhi',
      state: 'Delhi',
      latitude: 28.5667,
      longitude: 77.1833,
      activeSchools: 6,
      totalSchools: 18,
    ),
    LocationHubModel(
      id: 'delhi_ncr_central',
      name: 'Delhi NCR (Central)',
      city: 'Delhi',
      state: 'Delhi',
      latitude: 28.6139,
      longitude: 77.2090,
      activeSchools: 8,
      totalSchools: 24,
    ),
    LocationHubModel(
      id: 'pune_city',
      name: 'Pune City',
      city: 'Pune',
      state: 'Maharashtra',
      latitude: 18.5204,
      longitude: 73.8567,
      activeSchools: 4,
      totalSchools: 14,
    ),
    LocationHubModel(
      id: 'mumbai_metro',
      name: 'Mumbai Metro',
      city: 'Mumbai',
      state: 'Maharashtra',
      latitude: 19.0760,
      longitude: 72.8777,
      activeSchools: 7,
      totalSchools: 22,
    ),
    LocationHubModel(
      id: 'bengaluru',
      name: 'Bengaluru / Bangalore',
      city: 'Bengaluru',
      state: 'Karnataka',
      latitude: 12.9716,
      longitude: 77.5946,
      activeSchools: 5,
      totalSchools: 16,
    ),
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'activeSchools': activeSchools,
      'totalSchools': totalSchools,
      'radiusKm': radiusKm,
    };
  }

  factory LocationHubModel.fromJson(Map<String, dynamic> json) {
    return LocationHubModel(
      id: json['id'] as String? ?? 'kamta_lucknow',
      name: json['name'] as String? ?? 'Kamta, Lucknow',
      city: json['city'] as String? ?? 'Lucknow',
      state: json['state'] as String? ?? 'Uttar Pradesh',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 26.8833,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 81.0167,
      activeSchools: (json['activeSchools'] as num?)?.toInt() ?? 4,
      totalSchools: (json['totalSchools'] as num?)?.toInt() ?? 12,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 25.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationHubModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LocationHubModel(id: $id, name: $name, city: $city)';
}
