import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:safe_spot/services/auth_service.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/services/child_info_service.dart';
import 'widgets/profile_picture_widget.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/image_picker_bottom_sheet.dart';
import 'widgets/child_info_card.dart';
import 'package:safe_spot/utils/profile_utils.dart';
import 'package:safe_spot/models/user_profile.dart';
import 'package:safe_spot/models/child_info.dart';
import 'package:safe_spot/screens/edit_profile_screen.dart';
import 'package:safe_spot/screens/edit_child_info_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  UserProfile? userProfile;
  List<Device> userDevices = [];
  List<ChildInfo> childrenInfo = [];
  
  bool isLoading = true;
  bool isUploadingImage = false;
  bool isLoggingOut = false;
  bool isLoadingChildren = false;
  
  final ImagePicker _picker = ImagePicker();
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
    _loadUserData();
    _testStorageSetup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
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
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.black87,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.3),
      surfaceTintColor: Colors.black87,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)),
                  ),
                )
              : const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF8A50),
                  size: 20,
                ),
            onPressed: isLoggingOut ? null : _handleLogout,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFFFF8A50),
              borderRadius: BorderRadius.circular(24),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFB0B0B0),
            tabs: const [
              Tab(text: 'Profile', icon: Icon(Icons.person)),
              Tab(text: 'Children', icon: Icon(Icons.child_care)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)),
        ),
      );
    }

    if (userProfile == null) {
      return const Center(
        child: Text(
          'No profile data found.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFFB0B0B0),
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProfileTab(),
        _buildChildrenTab(),
      ],
    );
  }

  Widget _buildProfileTab() {
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

  Widget _buildChildrenTab() {
    if (isLoadingChildren) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: const Color(0xFFFF8A50),
      backgroundColor: const Color(0xFF2D2D2D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildChildrenHeader(),
            _buildChildrenList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF404040)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.child_care,
                  color: Color(0xFFFF8A50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Children Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${childrenInfo.length} ${childrenInfo.length == 1 ? 'child' : 'children'} registered',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (userDevices.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showDeviceSelectionDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Child Information'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildrenList() {
    if (childrenInfo.isEmpty) {
      return _buildEmptyChildrenState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: childrenInfo.map((childInfo) {
          final device = _findDeviceById(childInfo.deviceId);
          final deviceName = device?.deviceName ?? 'Unknown Device';
          
          return ChildInfoCard(
            key: ValueKey(childInfo.deviceId),
            childInfo: childInfo,
            deviceName: deviceName,
            onEdit: () => _editChildInfo(childInfo),
            onDelete: () => _deleteChildInfo(childInfo),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyChildrenState() {
    return Container(
      margin: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.child_friendly,
              size: 64,
              color: Color(0xFFB0B0B0),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Children Added Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            userDevices.isEmpty 
                ? 'Add devices first to register children information'
                : 'Add information about the children using your tracked devices',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFB0B0B0),
            ),
            textAlign: TextAlign.center,
          ),
          if (userDevices.isNotEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showDeviceSelectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Child Information'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: const Color(0xFFFF8A50),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0xFFFF8A50).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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
              userProfile!.email,
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
            value: userProfile!.mobile,
            color: const Color(0xFFFF8A50),
            backgroundColor: const Color(0xFF2D2D2D),
            borderColor: const Color(0xFF404040),
          ),
          const SizedBox(height: 16),
          ProfileInfoCard(
            icon: Icons.calendar_today_rounded,
            title: 'Member Since',
            value: ProfileUtils.formatJoinDate(userProfile!.createdAt),
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
        onPressed: _editProfile,
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

  // Child Information Methods
  Future<void> _loadUserData() async {
    setState(() {
      isLoadingChildren = true;
    });

    try {
      // Load user devices
      if (DeviceService.isAuthenticated) {
        final devices = await DeviceService.getUserDevices();
        setState(() {
          userDevices = devices;
        });

        // Load children information
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

  Device? _findDeviceById(String deviceId) {
    try {
      return userDevices.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }

  void _showDeviceSelectionDialog() {
    // Filter devices that don't have child info yet
    final availableDevices = userDevices.where((device) {
      return !childrenInfo.any((child) => child.deviceId == device.deviceId);
    }).toList();

    if (availableDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All devices already have child information added'),
          backgroundColor: Color(0xFFFF8A50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Select Device',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose a device to add child information for:',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
            const SizedBox(height: 16),
            ...availableDevices.map((device) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.devices,
                    color: Color(0xFFFF8A50),
                    size: 20,
                  ),
                ),
                title: Text(
                  device.deviceName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'ID: ${device.deviceId}',
                  style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addChildInfo(device);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF404040)),
                ),
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addChildInfo(Device device) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditChildInfoScreen(
          deviceId: device.deviceId,
          deviceName: device.deviceName,
        ),
      ),
    );

    if (result == true) {
      await _loadUserData();
    }
  }

  Future<void> _editChildInfo(ChildInfo childInfo) async {
    final device = _findDeviceById(childInfo.deviceId);
    if (device == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditChildInfoScreen(
          existingChildInfo: childInfo,
          deviceId: device.deviceId,
          deviceName: device.deviceName,
        ),
      ),
    );

    if (result == true) {
      await _loadUserData();
    }
  }

  Future<void> _deleteChildInfo(ChildInfo childInfo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Delete Child Information',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete information for ${childInfo.childName}? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ChildInfoService.deleteChildInfo(childInfo.deviceId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Information for ${childInfo.childName} deleted successfully'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        await _loadUserData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting child information: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Existing methods (logout, profile management, etc.)
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
              backgroundColor: const Color(0xFF4CAF50),
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