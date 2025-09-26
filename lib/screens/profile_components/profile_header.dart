import 'package:flutter/material.dart';
import 'package:safe_spot/models/user_profile.dart';
import '../widgets/profile_picture_widget.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile userProfile;
  final bool isUploadingImage;
  final VoidCallback onImagePicker;

  const ProfileHeader({
    super.key,
    required this.userProfile,
    required this.isUploadingImage,
    required this.onImagePicker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF404040), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ProfilePictureWidget(
            userProfile: userProfile,
            isUploadingImage: isUploadingImage,
            onTap: onImagePicker,
          ),
          const SizedBox(height: 24),
          Text(
            userProfile.fullName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A50).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF8A50).withOpacity(0.3)),
            ),
            child: Text(
              userProfile.email,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFFF8A50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
