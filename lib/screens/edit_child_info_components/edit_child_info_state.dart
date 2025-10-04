import 'dart:io';
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
  final formKey = GlobalKey<FormState>();

  // Text controllers
  final childNameController = TextEditingController();
  final ageController = TextEditingController();
  final schoolController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final medicalInfoController = TextEditingController();
  final notesController = TextEditingController();
  final relationshipController = TextEditingController();

  // State variables
  String? selectedGender;
  File? avatarImage;
  String? existingAvatarUrl;
  bool isUploadingAvatar = false;
  bool isSaving = false;
  bool hasChanges = false;

  void dispose() {
    childNameController.dispose();
    ageController.dispose();
    schoolController.dispose();
    emergencyContactController.dispose();
    medicalInfoController.dispose();
    notesController.dispose();
    relationshipController.dispose();
  }
}
