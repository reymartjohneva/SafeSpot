import 'package:flutter/services.dart';

class EditChildInfoValidators {
  static String? validateChildName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Child name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age < 0 || age > 18) {
      return 'Age must be between 0 and 18';
    }
    return null;
  }

  static String? validateEmergencyContact(String? value) {
    if (value != null && value.isNotEmpty) {
      final phoneRegex = RegExp(r'^[\+]?[0-9\-\(\)\s]+$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  static String? validateDropdownRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static List<TextInputFormatter> getDigitsOnlyFormatter() {
    return [FilteringTextInputFormatter.digitsOnly];
  }
}