import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safe_spot/models/child_info.dart';
import 'package:safe_spot/services/child_info_service.dart';
import 'package:safe_spot/services/child_avatar_service.dart';
import 'edit_child_info_state.dart';

mixin EditChildInfoLogic<T extends StatefulWidget> on State<T> {
  EditChildInfoState get state;
  ChildInfo? get existingChildInfo;
  String get deviceId;
  String get deviceName;

  void initializeForm() {
    if (existingChildInfo != null) {
      state.childNameController.text = existingChildInfo!.childName;
      state.ageController.text = existingChildInfo!.age.toString();
      state.selectedGender = existingChildInfo!.gender;
      state.relationshipController.text = existingChildInfo!.relationship ?? '';
      state.schoolController.text = existingChildInfo!.school ?? '';
      state.emergencyContactController.text = existingChildInfo!.emergencyContact ?? '';
      state.medicalInfoController.text = existingChildInfo!.medicalInfo ?? '';
      state.notesController.text = existingChildInfo!.notes ?? '';
      state.existingAvatarUrl = existingChildInfo!.avatarUrl;
    }

    // Add listeners to track changes
    state.childNameController.addListener(_checkForChanges);
    state.ageController.addListener(_checkForChanges);
    state.schoolController.addListener(_checkForChanges);
    state.emergencyContactController.addListener(_checkForChanges);
    state.medicalInfoController.addListener(_checkForChanges);
    state.notesController.addListener(_checkForChanges);
    state.relationshipController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    if (existingChildInfo != null) {
      final hasChanges = state.childNameController.text != existingChildInfo!.childName ||
          state.ageController.text != existingChildInfo!.age.toString() ||
          state.selectedGender != existingChildInfo!.gender ||
          state.relationshipController.text != (existingChildInfo!.relationship ?? '') ||
          state.schoolController.text != (existingChildInfo!.school ?? '') ||
          state.emergencyContactController.text != (existingChildInfo!.emergencyContact ?? '') ||
          state.medicalInfoController.text != (existingChildInfo!.medicalInfo ?? '') ||
          state.notesController.text != (existingChildInfo!.notes ?? '') ||
          state.avatarImage != null;

      if (hasChanges != state.hasChanges) {
        setState(() {
          state.hasChanges = hasChanges;
        });
      }
    } else {
      setState(() {
        state.hasChanges = true;
      });
    }
  }

  Future<void> pickAvatarFromGallery() async {
    try {
      final image = await ChildAvatarService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          state.avatarImage = image;
          state.hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> pickAvatarFromCamera() async {
    try {
      final image = await ChildAvatarService.pickImageFromCamera();
      if (image != null) {
        setState(() {
          state.avatarImage = image;
          state.hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void removeAvatar() {
    setState(() {
      state.avatarImage = null;
      state.existingAvatarUrl = null;
      state.hasChanges = true;
    });
  }

  void showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Avatar Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFF8A50)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                pickAvatarFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF8A50)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                pickAvatarFromCamera();
              },
            ),
            if (state.existingAvatarUrl != null || state.avatarImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> saveChildInfo() async {
    if (!state.formKey.currentState!.validate()) {
      return;
    }

    if (state.selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      state.isSaving = true;
    });

    try {
      String? avatarUrl = state.existingAvatarUrl;

      // Upload new avatar if selected
      if (state.avatarImage != null) {
        setState(() {
          state.isUploadingAvatar = true;
        });

        avatarUrl = await ChildAvatarService.uploadAvatar(
          state.avatarImage!,
          deviceId,
        );

        setState(() {
          state.isUploadingAvatar = false;
        });
      }

      final childInfo = ChildInfo(
        id: existingChildInfo?.id,
        deviceId: deviceId,
        childName: state.childNameController.text.trim(),
        age: int.parse(state.ageController.text.trim()),
        gender: state.selectedGender!,
        relationship: state.relationshipController.text.trim().isEmpty
            ? null
            : state.relationshipController.text.trim(),
        school: state.schoolController.text.trim().isEmpty
            ? null
            : state.schoolController.text.trim(),
        emergencyContact: state.emergencyContactController.text.trim().isEmpty
            ? null
            : state.emergencyContactController.text.trim(),
        medicalInfo: state.medicalInfoController.text.trim().isEmpty
            ? null
            : state.medicalInfoController.text.trim(),
        notes: state.notesController.text.trim().isEmpty
            ? null
            : state.notesController.text.trim(),
        avatarUrl: avatarUrl,
        createdAt: existingChildInfo?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Validate
      final validationError = ChildInfoService.validateChildInfo(childInfo);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Save to database
      await ChildInfoService.upsertChildInfo(childInfo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingChildInfo != null
                  ? 'Child information updated successfully'
                  : 'Child information added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          state.isSaving = false;
          state.isUploadingAvatar = false;
        });
      }
    }
  }
}