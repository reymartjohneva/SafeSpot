import 'package:flutter/material.dart';
import 'package:safe_spot/models/child_info.dart';
import 'package:safe_spot/services/child_info_service.dart';
import 'package:safe_spot/screens/edit_child_info_components/edit_child_info_state.dart';

mixin EditChildInfoLogic<T extends StatefulWidget> on State<T> {
  EditChildInfoState get state;
  ChildInfo? get existingChildInfo;
  String get deviceId;
  String get deviceName;

  void initializeForm() {
    if (existingChildInfo != null) {
      final child = existingChildInfo!;
      state.nameController.text = child.childName;
      state.ageController.text = child.age.toString();
      state.selectedGender = child.gender;
      state.relationshipController.text = child.relationship ?? '';
      state.schoolController.text = child.school ?? '';
      state.emergencyContactController.text = child.emergencyContact ?? '';
      state.medicalInfoController.text = child.medicalInfo ?? '';
      state.notesController.text = child.notes ?? '';
    }
  }

  Future<void> saveChildInfo() async {
    if (!state.formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      state.isSaving = true;
    });

    try {
      final childInfo = ChildInfo(
        id: existingChildInfo?.id,
        deviceId: deviceId,
        childName: state.nameController.text.trim(),
        age: int.parse(state.ageController.text.trim()),
        gender: state.selectedGender,
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
        createdAt: existingChildInfo?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Validate the child info
      final validationError = ChildInfoService.validateChildInfo(childInfo);
      if (validationError != null) {
        setState(() {
          state.isSaving = false;
        });
        
        _showErrorSnackBar(validationError);
        return;
      }

      // Save to database
      await ChildInfoService.upsertChildInfo(childInfo);

      setState(() {
        state.isSaving = false;
      });

      _showSuccessSnackBar(
        existingChildInfo == null 
            ? 'Child information added successfully' 
            : 'Child information updated successfully',
      );

      // Return to previous screen
      Navigator.of(context).pop(true);

    } catch (e) {
      setState(() {
        state.isSaving = false;
      });

      _showErrorSnackBar('Error saving child information: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EditChildInfoColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EditChildInfoColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}