import 'package:flutter/material.dart';
import 'package:safe_spot/services/auth_service.dart';
import 'package:safe_spot/utils/profile_utils.dart';

class ProfilePictureWidget extends StatelessWidget {
  final UserProfile userProfile;
  final bool isUploadingImage;
  final VoidCallback onTap;

  const ProfilePictureWidget({
    super.key,
    required this.userProfile,
    required this.isUploadingImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print('Building profile picture. Avatar URL: ${userProfile.avatarUrl}');

    if (isUploadingImage) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          _buildProfileImage(),
          _buildCameraIcon(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF6366F1).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: userProfile.avatarUrl != null && userProfile.avatarUrl!.isNotEmpty
          ? _buildNetworkImage()
          : _buildInitialsDisplay(),
    );
  }

  Widget _buildNetworkImage() {
    return ClipOval(
      child: Image.network(
        userProfile.avatarUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('Avatar loaded successfully');
            return child;
          }
          print(
            'Loading avatar... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}',
          );
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Avatar loading error: $error');
          print('Avatar URL that failed: ${userProfile.avatarUrl}');
          return _buildInitialsDisplay();
        },
      ),
    );
  }

  Widget _buildInitialsDisplay() {
    return Center(
      child: Text(
        ProfileUtils.getInitials(userProfile.fullName),
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCameraIcon() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Color(0xFF6366F1),
          size: 18,
        ),
      ),
    );
  }
}