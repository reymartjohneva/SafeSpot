import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? userProfile;
  bool isLoading = true;
  bool isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
              onPressed: _showLogoutDialog,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : userProfile == null
              ? const Center(
                  child: Text(
                    'No profile data found.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header Card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildProfilePicture(),
                            const SizedBox(height: 24),
                            Text(
                              userProfile!.fullName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
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
                                color: const Color(0xFF6366F1).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                userProfile!.email,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Information Cards
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildInfoCard(
                              icon: Icons.phone_rounded,
                              title: 'Mobile Number',
                              value: userProfile!.mobile,
                              color: const Color(0xFF10B981),
                              backgroundColor: const Color(0xFFF0FDF4),
                              borderColor: const Color(0xFFBBF7D0),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              icon: Icons.calendar_today_rounded,
                              title: 'Member Since',
                              value: _formatJoinDate(userProfile!.createdAt),
                              color: const Color(0xFF8B5CF6),
                              backgroundColor: const Color(0xFFFAF5FF),
                              borderColor: const Color(0xFFDDD6FE),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Edit Profile Button
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _editProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
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
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _testStorageSetup();
  }

  // Add this debug method to your ProfileScreen class to check avatar data
  void _debugAvatarData() {
    print('=== AVATAR DEBUG INFO ===');
    print('User Profile Avatar URL: ${userProfile?.avatarUrl}');
    print('Current User Metadata: ${AuthService.currentUser?.userMetadata}');
    print(
      'Current User Avatar from metadata: ${AuthService.currentUser?.userMetadata?['avatar_url']}',
    );

    // Check if the URL is accessible
    if (userProfile?.avatarUrl != null) {
      print('Avatar URL exists: ${userProfile!.avatarUrl}');
      print('URL length: ${userProfile!.avatarUrl!.length}');
    } else {
      print('Avatar URL is null');
    }
    print('========================');
  }

  // Updated _loadUserProfile method with better debugging
  Future<void> _loadUserProfile() async {
    try {
      print('Loading user profile...');
      final profileData = await AuthService.getUserProfile();
      print('Profile data from database: $profileData');

      if (profileData != null) {
        setState(() {
          userProfile = UserProfile.fromJson(profileData);
          isLoading = false;
        });
        print('Profile loaded from database successfully');
      } else {
        // Fallback to user metadata if profile table doesn't exist
        final user = AuthService.currentUser;
        print('User metadata: ${user?.userMetadata}');

        if (user != null) {
          setState(() {
            userProfile = UserProfile(
              id: user.id,
              email: user.email ?? '',
              firstName: user.userMetadata?['first_name'] ?? 'N/A',
              lastName: user.userMetadata?['last_name'] ?? 'N/A',
              mobile: user.userMetadata?['mobile'] ?? 'N/A',
              fullName: user.userMetadata?['full_name'] ?? 'N/A',
              avatarUrl:
                  user.userMetadata?['avatar_url'], // This should have the avatar URL
              createdAt: DateTime.parse(user.createdAt),
              updatedAt: DateTime.now(),
            );
            isLoading = false;
          });
          print('Profile created from user metadata');
        }
      }

      // Debug avatar data
      _debugAvatarData();
    } catch (e) {
      print('Error in _loadUserProfile: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _testStorageSetup() async {
    final result = await AuthService.verifyStorageSetup();
    print('Storage setup test: ${result.message}');
  }

  // Enhanced _buildProfilePicture with better design
  Widget _buildProfilePicture() {
    print('Building profile picture. Avatar URL: ${userProfile?.avatarUrl}');

    if (isUploadingImage) {
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

    return GestureDetector(
      onTap: _showImagePicker,
      child: Stack(
        children: [
          Container(
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
            child: userProfile?.avatarUrl != null &&
                    userProfile!.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      userProfile!.avatarUrl!,
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
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Avatar loading error: $error');
                        print(
                          'Avatar URL that failed: ${userProfile!.avatarUrl}',
                        );
                        return Center(
                          child: Text(
                            _getInitials(userProfile!.fullName),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      _getInitials(userProfile?.fullName ?? ''),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          Positioned(
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
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Update Profile Picture',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _buildImageOption(
                          icon: Icons.camera_alt_rounded,
                          title: 'Camera',
                          subtitle: 'Take a new photo',
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImageOption(
                          icon: Icons.photo_library_rounded,
                          title: 'Gallery',
                          subtitle: 'Choose from gallery',
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),

                  if (userProfile?.avatarUrl != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deleteProfilePicture,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                        ),
                        label: const Text(
                          'Remove Current Picture',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Updated _pickImage method with forced refresh
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet

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
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Force reload profile with a delay to ensure Supabase has updated
          await Future.delayed(const Duration(milliseconds: 500));
          await _loadUserProfile();

          // Force rebuild the widget
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFDC2626),
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
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteProfilePicture() async {
    Navigator.pop(context); // Close bottom sheet

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8),
              Text(
                'Delete Profile Picture',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to remove your profile picture?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

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
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Reload profile to reflect changes
        await _loadUserProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: const Color(0xFFDC2626),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      ),
    );

    try {
      final result = await AuthService.signOut();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result.success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to login page and clear ALL navigation stack
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (Route<dynamic> route) => false, // This removes ALL previous routes
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFDC2626),
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
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
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

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit profile functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    } else {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
  }
}