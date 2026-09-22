import 'package:flutter/foundation.dart';

/// Represents an affiliated school in Book Vardi's customized curriculum/uniform catalog.
@immutable
class SchoolModel {
  final String schoolId;
  final String name;
  final String city;
  final String logoUrl;
  final List<String> grades;

  const SchoolModel({
    required this.schoolId,
    required this.name,
    required this.city,
    required this.logoUrl,
    this.grades = const [],
  });

  SchoolModel copyWith({
    String? schoolId,
    String? name,
    String? city,
    String? logoUrl,
    List<String>? grades,
  }) {
    return SchoolModel(
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      city: city ?? this.city,
      logoUrl: logoUrl ?? this.logoUrl,
      grades: grades ?? this.grades,
    );
  }

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      schoolId: json['schoolId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      grades: (json['grades'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolId': schoolId,
      'name': name,
      'city': city,
      'logoUrl': logoUrl,
      'grades': grades,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolModel &&
          runtimeType == other.runtimeType &&
          schoolId == other.schoolId &&
          name == other.name &&
          city == other.city &&
          logoUrl == other.logoUrl &&
          listEquals(grades, other.grades);

  @override
  int get hashCode =>
      schoolId.hashCode ^
      name.hashCode ^
      city.hashCode ^
      logoUrl.hashCode ^
      grades.hashCode;

  @override
  String toString() =>
      'SchoolModel(id: $schoolId, name: $name, city: $city, grades: ${grades.length})';
}
