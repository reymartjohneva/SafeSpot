import 'package:flutter/material.dart';
import 'package:safe_spot/models/user_profile.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/utils/profile_utils.dart';
import '../widgets/profile_info_card.dart';

class ProfileInformationSection extends StatelessWidget {
  final UserProfile userProfile;
  final List<Device> userDevices;

  const ProfileInformationSection({
    super.key,
    required this.userProfile,
    required this.userDevices,
  });

  @override
  Widget build(BuildContext context) {
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
}