import 'package:flutter/material.dart';

// Color constants for Edit Profile theme
class EditProfileColors {
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color cardBackground = Color(0xFF2D2D2D);
  static const Color borderColor = Color(0xFF404040);
  static const Color primaryOrange = Color(0xFFFF8A50);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color iconColor = Color(0xFF808080);
  static const Color errorRed = Color(0xFFFF4444);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color disabledGrey = Color(0xFF404040);
}

// State data class
class EditProfileState {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  
  bool isLoading = false;
  bool hasChanges = false;

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
  }
}