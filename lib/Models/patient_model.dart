import 'package:flutter/material.dart';
import '../Components/colors.dart';

class Patient {
  final String patientId;
  final String? doctorId;
  final String name;
  final int age;
  final String? gender;
  final String? phone;
  final String? createdAt;
  final String? updatedAt;

  Patient({
    required this.patientId,
    this.doctorId,
    required this.name,
    required this.age,
    this.gender,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      patientId: (json['patient_id'] ?? json['id'] ?? '').toString(),
      doctorId: json['doctor_id']?.toString(),
      name: json['name'] ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      gender: json['gender'],
      phone: json['phone'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() =>
      'Patient(patientId: $patientId, name: $name, age: $age, gender: $gender, phone: $phone)';
}

enum Gender { male, female, other }

extension GenderExtension on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return "Male";
      case Gender.female:
        return "Female";
      case Gender.other:
        return "Other";
    }
  }

  Color get primaryColor {
    switch (this) {
      case Gender.male:
        return AppColors.primaryMale;
      case Gender.female:
        return AppColors.primaryFemale;
      case Gender.other:
        return AppColors.primaryOther;
    }
  }

  Color get secondaryColor {
    switch (this) {
      case Gender.male:
        return AppColors.secondaryMale;
      case Gender.female:
        return AppColors.secondaryFemale;
      case Gender.other:
        return AppColors.secondaryOther;
    }
  }

  static Gender fromString(String? gender) {
    switch (gender?.toLowerCase()) {
      case "male":
        return Gender.male;
      case "female":
        return Gender.female;
      default:
        return Gender.other;
    }
  }
}
