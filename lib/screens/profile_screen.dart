import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:safe_spot/services/auth_service.dart';
import 'widgets/profile_picture_widget.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/image_picker_bottom_sheet.dart';
import 'package:safe_spot/utils/profile_utils.dart';
import 'package:safe_spot/models/user_profile.dart';
import 'package:safe_spot/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? userProfile;
  bool isLoading = true;
  bool isUploadingImage = false;
  bool isLoggingOut = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _testStorageSetup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background like navbar
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Profile',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white, // White text for dark theme
        ),
      ),
      backgroundColor: Colors.black87, // Match navbar color
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.3),
      surfaceTintColor: Colors.black87,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D), // Dark container
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF404040)),
          ),
          child: IconButton(
            icon: isLoggingOut 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)), // Orange accent
                  ),
                )
              : const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF8A50), // Orange accent color
                  size: 20,
                ),
            onPressed: isLoggingOut ? null : _handleLogout,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)), // Orange accent
        ),
      );
    }

    if (userProfile == null) {
      return const Center(
        child: Text(
          'No profile data found.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFB0B0B0), // Light grey for dark theme
          ),
        ),
      );
    }

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
        color: const Color(0xFF2D2D2D), // Dark card background
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
            userProfile: userProfile!,
            isUploadingImage: isUploadingImage,
            onTap: _showImagePicker,
          ),
          const SizedBox(height: 24),
          Text(
            userProfile!.fullName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text
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
              color: const Color(0xFFFF8A50).withOpacity(0.15), // Orange accent background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF8A50).withOpacity(0.3)),
            ),
            child: Text(
              userProfile!.email,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFFF8A50), // Orange accent text
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
            value: userProfile!.mobile,
            color: const Color(0xFFFF8A50), // Orange accent
            backgroundColor: const Color(0xFF2D2D2D), // Dark background
            borderColor: const Color(0xFF404040),
          ),
          const SizedBox(height: 16),
          ProfileInfoCard(
            icon: Icons.calendar_today_rounded,
            title: 'Member Since',
            value: ProfileUtils.formatJoinDate(userProfile!.createdAt),
            color: const Color(0xFFFF8A50), // Orange accent
            backgroundColor: const Color(0xFF2D2D2D), // Dark background
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
        onPressed: _editProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A50), // Orange accent
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

  Future<void> _handleLogout() async {
    await _performLogout();
  }

  Future<void> _performLogout() async {
    if (isLoggingOut) return;
    
    setState(() {
      isLoggingOut = true;
    });

    try {
      final result = await AuthService.signOut();
      
      if (result.success) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (Route<dynamic> route) => false,
          );
        }
      } else {
        setState(() {
          isLoggingOut = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFFF4444), // Red for errors in dark theme
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
      print('Logout error: $e');
      
      setState(() {
        isLoggingOut = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
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
              avatarUrl: user.userMetadata?['avatar_url'],
              createdAt: DateTime.parse(user.createdAt),
              updatedAt: DateTime.now(),
            );
            isLoading = false;
          });
          print('Profile created from user metadata');
        }
      }

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
            backgroundColor: const Color(0xFFFF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _debugAvatarData() {
    print('=== AVATAR DEBUG INFO ===');
    print('User Profile Avatar URL: ${userProfile?.avatarUrl}');
    print('Current User Metadata: ${AuthService.currentUser?.userMetadata}');
    print(
      'Current User Avatar from metadata: ${AuthService.currentUser?.userMetadata?['avatar_url']}',
    );

    if (userProfile?.avatarUrl != null) {
      print('Avatar URL exists: ${userProfile!.avatarUrl}');
      print('URL length: ${userProfile!.avatarUrl!.length}');
    } else {
      print('Avatar URL is null');
    }
    print('========================');
  }

  Future<void> _testStorageSetup() async {
    final result = await AuthService.verifyStorageSetup();
    print('Storage setup test: ${result.message}');
  }

  Future<void> _showImagePicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ImagePickerBottomSheet(
          userProfile: userProfile,
          onCameraTap: () => _pickImage(ImageSource.camera),
          onGalleryTap: () => _pickImage(ImageSource.gallery),
          onDeleteTap: _deleteProfilePicture,
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
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
              backgroundColor: const Color(0xFF4CAF50), // Green for success in dark theme
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          await _loadUserProfile();
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

  Future<void> _deleteProfilePicture() async {
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

        await _loadUserProfile();
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

  Future<void> _editProfile() async {
    if (userProfile == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userProfile: userProfile!),
      ),
    );

    if (result == true) {
      await _loadUserProfile();
    }
  }
}