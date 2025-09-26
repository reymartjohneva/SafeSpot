import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:safe_spot/services/auth_service.dart';
import 'package:safe_spot/utils/profile_utils.dart';
import 'package:safe_spot/models/user_profile.dart';
import '../widgets/image_picker_bottom_sheet.dart';

mixin ProfileImageMixin<T extends StatefulWidget> on State<T> {
  bool isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  // This should be implemented by the class using this mixin
  UserProfile? get userProfile;
  Future<void> loadUserProfile();

  Future<void> showImagePicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ImagePickerBottomSheet(
          userProfile: userProfile,
          onCameraTap: () => pickImage(ImageSource.camera),
          onGalleryTap: () => pickImage(ImageSource.gallery),
          onDeleteTap: deleteProfilePicture,
        );
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    Navigator.pop(context);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          isUploadingImage = true;
        });

        final File imageFile = File(image.path);
        final result = await AuthService.uploadProfilePicture(
          imageFile: imageFile,
        );

        setState(() {
          isUploadingImage = false;
        });

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          await loadUserProfile();
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFFF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: const Color(0xFFFF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> deleteProfilePicture() async {
    Navigator.pop(context);

    final bool? confirmed = await ProfileUtils.showDeleteConfirmationDialog(context);

    if (confirmed == true) {
      setState(() {
        isUploadingImage = true;
      });

      final result = await AuthService.deleteProfilePicture();

      setState(() {
        isUploadingImage = false;
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        await loadUserProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: const Color(0xFFFF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}