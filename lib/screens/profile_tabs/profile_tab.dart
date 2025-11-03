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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildStatsBar(),
            const SizedBox(height: 24),
            _buildInformationCards(),
            const SizedBox(height: 32),
            _buildEditProfileButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D2D2D),
            const Color(0xFF252525),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFF404040),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: const Color(0xFFFF8A50).withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ProfilePictureWidget(
                userProfile: userProfile,
                isUploadingImage: isUploadingImage,
                onTap: onImagePicker,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2D2D2D),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A50).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            userProfile.fullName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF8A50).withOpacity(0.2),
                  const Color(0xFFFF8A50).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFF8A50).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email_rounded,
                  color: const Color(0xFFFF8A50),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    userProfile.email,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFFF8A50),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF404040),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.devices_rounded,
              '${userDevices.length}',
              userDevices.length == 1 ? 'Device' : 'Devices',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF404040),
          ),
          Expanded(
            child: _buildStatItem(
              Icons.verified_user_rounded,
              'Active',
              'Status',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF8A50),
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInformationCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Account Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ProfileInfoCard(
          icon: Icons.phone_rounded,
          title: 'Mobile Number',
          value: userProfile.mobile,
          color: const Color(0xFFFF8A50),
          backgroundColor: const Color(0xFF2D2D2D),
          borderColor: const Color(0xFF404040),
        ),
        const SizedBox(height: 12),
        ProfileInfoCard(
          icon: Icons.calendar_today_rounded,
          title: 'Member Since',
          value: ProfileUtils.formatJoinDate(userProfile.createdAt),
          color: const Color(0xFFFF8A50),
          backgroundColor: const Color(0xFF2D2D2D),
          borderColor: const Color(0xFF404040),
        ),
        const SizedBox(height: 12),
        ProfileInfoCard(
          icon: Icons.devices,
          title: 'Registered Devices',
          value: '${userDevices.length} ${userDevices.length == 1 ? 'device' : 'devices'}',
          color: const Color(0xFFFF8A50),
          backgroundColor: const Color(0xFF2D2D2D),
          borderColor: const Color(0xFF404040),
        ),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A50).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onEditProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A50),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, size: 22),
            SizedBox(width: 10),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}