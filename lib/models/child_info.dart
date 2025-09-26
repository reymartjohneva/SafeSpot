// lib/models/child_info.dart
class ChildInfo {
  final String? id;
  final String deviceId;
  final String childName;
  final int age;
  final String gender;
  final String? relationship;
  final String? school;
  final String? emergencyContact;
  final String? medicalInfo;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildInfo({
    this.id,
    required this.deviceId,
    required this.childName,
    required this.age,
    required this.gender,
    this.relationship,
    this.school,
    this.emergencyContact,
    this.medicalInfo,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildInfo.fromJson(Map<String, dynamic> json) {
    return ChildInfo(
      id: json['id'],
      deviceId: json['device_id'],
      childName: json['child_name'],
      age: json['age'],
      gender: json['gender'],
      relationship: json['relationship'],
      school: json['school'],
      emergencyContact: json['emergency_contact'],
      medicalInfo: json['medical_info'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'child_name': childName,
      'age': age,
      'gender': gender,
      'relationship': relationship,
      'school': school,
      'emergency_contact': emergencyContact,
      'medical_info': medicalInfo,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChildInfo copyWith({
    String? id,
    String? deviceId,
    String? childName,
    int? age,
    String? gender,
    String? relationship,
    String? school,
    String? emergencyContact,
    String? medicalInfo,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChildInfo(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      childName: childName ?? this.childName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      relationship: relationship ?? this.relationship,
      school: school ?? this.school,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}