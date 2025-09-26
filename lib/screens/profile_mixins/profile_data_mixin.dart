import 'package:flutter/material.dart';
import 'package:safe_spot/services/auth_service.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/services/child_info_service.dart';
import 'package:safe_spot/models/user_profile.dart';
import 'package:safe_spot/models/child_info.dart';
import 'package:safe_spot/screens/edit_profile_screen.dart';

mixin ProfileDataMixin<T extends StatefulWidget> on State<T> {
  UserProfile? userProfile;
  List<Device> userDevices = [];
  List<ChildInfo> childrenInfo = [];
  
  bool isLoading = true;
  bool isLoggingOut = false;
  bool isLoadingChildren = false;

  Future<void> initializeProfile() async {
    await loadUserProfile();
    await loadUserData();
    await testStorageSetup();
  }

  Future<void> loadUserProfile() async {
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

      debugAvatarData();
    } catch (e) {
      print('Error in loadUserProfile: $e');
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

  Future<void> loadUserData() async {
    setState(() {
      isLoadingChildren = true;
    });

    try {
      if (DeviceService.isAuthenticated) {
        final devices = await DeviceService.getUserDevices();
        setState(() {
          userDevices = devices;
        });

        final children = await ChildInfoService.getAllChildrenInfo();
        setState(() {
          childrenInfo = children;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingChildren = false;
        });
      }
    }
  }

  Future<void> handleLogout() async {
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

  Future<void> editProfile() async {
    if (userProfile == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userProfile: userProfile!),
      ),
    );

    if (result == true) {
      await loadUserProfile();
    }
  }

  void debugAvatarData() {
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

  Future<void> testStorageSetup() async {
    final result = await AuthService.verifyStorageSetup();
    print('Storage setup test: ${result.message}');
  }
}