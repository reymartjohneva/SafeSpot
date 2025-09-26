import 'package:flutter/material.dart';
import 'package:safe_spot/models/user_profile.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/utils/profile_utils.dart';
import '../widgets/profile_picture_widget.dart';
import '../widgets/profile_info_card.dart';

class ProfileTab extends StatelessWidget {
  final UserProfile userProfile;
  final List<Device> userDevices;
  final bool isUploadingImage;
  final VoidCallback onImagePicker;
  final VoidCallback onEditProfile;

  const ProfileTab({
    super.key,
    required this.userProfile,
    required this.userDevices,
    required this.isUploadingImage,
    required this.onImagePicker,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(),
          _buildInformationCards(),
          const SizedBox(height: 32),
          _buildEditProfileButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
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

  Widget _buildInformationCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ProfileInfoCard(
            icon: Icons.phone_rounded,
            title: 'Mobile Number',
            value: userProfile.mobile,
            color: const Color(0xFFFF8A50),
            backgroundColor: const Color(0xFF2D2D2D),
            borderColor: const Color(0xFF404040),
          ),
          const SizedBox(height: 16),
          ProfileInfoCard(
            icon: Icons.calendar_today_rounded,
            title: 'Member Since',
            value: ProfileUtils.formatJoinDate(userProfile.createdAt),
            color: const Color(0xFFFF8A50),
            backgroundColor: const Color(0xFF2D2D2D),
            borderColor: const Color(0xFF404040),
          ),
          const SizedBox(height: 16),
          ProfileInfoCard(
            icon: Icons.devices,
            title: 'Registered Devices',
            value: '${userDevices.length} ${userDevices.length == 1 ? 'device' : 'devices'}',
            color: const Color(0xFFFF8A50),
            backgroundColor: const Color(0xFF2D2D2D),
            borderColor: const Color(0xFF404040),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onEditProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A50),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: const Color(0xFFFF8A50).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}