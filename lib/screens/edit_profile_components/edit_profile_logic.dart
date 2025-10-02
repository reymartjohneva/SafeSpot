import 'package:flutter/material.dart';
import 'package:safe_spot/services/auth_service.dart';
import 'package:safe_spot/models/user_profile.dart';
import 'package:safe_spot/screens/edit_profile_components/edit_profile_state.dart';

mixin EditProfileLogic<T extends StatefulWidget> on State<T> {
  EditProfileState get state;
  UserProfile get userProfile;

  void initializeControllers() {
    state.firstNameController.text = userProfile.firstName;
    state.lastNameController.text = userProfile.lastName;
    state.mobileController.text = userProfile.mobile;

    // Add listeners to track changes
    state.firstNameController.addListener(onFieldChanged);
    state.lastNameController.addListener(onFieldChanged);
    state.mobileController.addListener(onFieldChanged);
  }

  void onFieldChanged() {
    final hasChanges = state.firstNameController.text != userProfile.firstName ||
                      state.lastNameController.text != userProfile.lastName ||
                      state.mobileController.text != userProfile.mobile;

    if (hasChanges != state.hasChanges) {
      setState(() {
        state.hasChanges = hasChanges;
      });
    }
  }

  Future<void> saveChanges() async {
    if (!state.formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      state.isLoading = true;
    });

    try {
      // Create updated profile data
      final updatedData = {
        'first_name': state.firstNameController.text.trim(),
        'last_name': state.lastNameController.text.trim(),
        'mobile': state.mobileController.text.trim(),
        'full_name': '${state.firstNameController.text.trim()} ${state.lastNameController.text.trim()}',
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Call your AuthService to update the profile
      final result = await AuthService.updateUserProfile(updatedData);

      if (result.success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!'),
              backgroundColor: EditProfileColors.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate back to profile screen
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Show error message
        if (mounted) {
          _showErrorSnackBar(result.message);
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to update profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          state.isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EditProfileColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void onBackPressed() {
    if (state.hasChanges) {
      showUnsavedChangesDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> showUnsavedChangesDialog() async {
    final bool? shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: EditProfileColors.cardBackground,
          title: const Text(
            'Unsaved Changes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: EditProfileColors.textPrimary,
            ),
          ),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            style: TextStyle(color: EditProfileColors.textSecondary),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: EditProfileColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: EditProfileColors.errorRed,
                foregroundColor: EditProfileColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Discard',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDiscard == true) {
      Navigator.of(context).pop();
    }
  }
}