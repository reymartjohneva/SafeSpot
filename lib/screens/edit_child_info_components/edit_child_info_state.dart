import 'package:flutter/material.dart';

// Color constants for Child Info theme
class EditChildInfoColors {
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color cardBackground = Color(0xFF2D2D2D);
  static const Color sectionHeaderBackground = Color(0xFF3D3D3D);
  static const Color inputBackground = Color(0xFF404040);
  static const Color borderColor = Color(0xFF404040);
  static const Color primaryOrange = Color(0xFFFF8A50);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF808080);
  static const Color errorRed = Colors.red;
  static const Color successGreen = Color(0xFF4CAF50);
}

// State data class
class EditChildInfoState {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController relationshipController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();
  final TextEditingController medicalInfoController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String selectedGender = 'Male';
  bool isSaving = false;

  // Dropdown options
  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> relationshipOptions = [
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Nephew',
    'Niece',
    'Grandchild',
    'Other'
  ];

  void dispose() {
    nameController.dispose();
    ageController.dispose();
    relationshipController.dispose();
    schoolController.dispose();
    emergencyContactController.dispose();
    medicalInfoController.dispose();
    notesController.dispose();
  }
}