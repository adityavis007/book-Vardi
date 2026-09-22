/// User role definition matching Firestore permissions schema.
enum UserRole {
  customer,
  admin;

  static UserRole fromString(String? role) {
    if (role?.trim().toLowerCase() == 'admin') {
      return UserRole.admin;
    }
    return UserRole.customer;
  }

  String toValue() => name;
}

/// User Domain Model matching Cloud Firestore `users/{userId}` schema.
class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Student & Profile metadata matching Book Vardi website
  final String? schoolName;
  final String? grade;
  final String? studentId;
  final String? rollNo;
  final String? photoUrl;
  final int rewardPoints;

  // Primary Address metadata
  final String? addressLine;
  final String? city;
  final String? stateName;
  final String? pincode;
  final String? landmark;
  final String? addressLabel;

  const UserModel({
    required this.userId,
    required this.name,
    this.email = '',
    this.phone = '',
    this.role = UserRole.customer,
    this.createdAt,
    this.updatedAt,
    this.schoolName,
    this.grade,
    this.studentId,
    this.rollNo,
    this.photoUrl,
    this.rewardPoints = 480,
    this.addressLine,
    this.city,
    this.stateName,
    this.pincode,
    this.landmark,
    this.addressLabel,
  });

  bool get isAdmin => role == UserRole.admin;

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? schoolName,
    String? grade,
    String? studentId,
    String? rollNo,
    String? photoUrl,
    int? rewardPoints,
    String? addressLine,
    String? city,
    String? stateName,
    String? pincode,
    String? landmark,
    String? addressLabel,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schoolName: schoolName ?? this.schoolName,
      grade: grade ?? this.grade,
      studentId: studentId ?? this.studentId,
      rollNo: rollNo ?? this.rollNo,
      photoUrl: photoUrl ?? this.photoUrl,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      stateName: stateName ?? this.stateName,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      addressLabel: addressLabel ?? this.addressLabel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toValue(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'schoolName': schoolName,
      'grade': grade,
      'studentId': studentId,
      'rollNo': rollNo,
      'photoUrl': photoUrl,
      'rewardPoints': rewardPoints,
      'addressLine': addressLine,
      'city': city,
      'stateName': stateName,
      'pincode': pincode,
      'landmark': landmark,
      'addressLabel': addressLabel,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? fallbackId]) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      // Handles Firestore Timestamp if present dynamically
      try {
        final toDate = (val as dynamic).toDate;
        if (toDate is Function) return toDate() as DateTime;
      } catch (_) {}
      return null;
    }

    return UserModel(
      userId: (map['userId'] as String?) ?? fallbackId ?? '',
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      role: UserRole.fromString(map['role'] as String?),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      schoolName: map['schoolName'] as String?,
      grade: map['grade'] as String?,
      studentId: map['studentId'] as String?,
      rollNo: map['rollNo'] as String?,
      photoUrl: map['photoUrl'] as String?,
      rewardPoints: (map['rewardPoints'] as num?)?.toInt() ?? 480,
      addressLine: map['addressLine'] as String?,
      city: map['city'] as String?,
      stateName: map['stateName'] as String?,
      pincode: map['pincode'] as String?,
      landmark: map['landmark'] as String?,
      addressLabel: map['addressLabel'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          role == other.role &&
          schoolName == other.schoolName &&
          grade == other.grade &&
          studentId == other.studentId;

  @override
  int get hashCode =>
      userId.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      role.hashCode ^
      schoolName.hashCode ^
      grade.hashCode ^
      studentId.hashCode;

  @override
  String toString() =>
      'UserModel(userId: $userId, name: $name, email: $email, role: ${role.name}, school: $schoolName, grade: $grade)';
}
