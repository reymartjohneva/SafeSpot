import 'package:flutter/material.dart';
import 'profile_tabs/profile_tab.dart';
import 'profile_tabs/children_tab.dart';
import 'profile_mixins/profile_data_mixin.dart';
import 'profile_mixins/profile_image_mixin.dart';
import 'profile_mixins/child_info_mixin.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> 
    with SingleTickerProviderStateMixin, ProfileDataMixin, ProfileImageMixin, ChildInfoMixin {
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initializeProfile();
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
            onPressed: isLoggingOut ? null : handleLogout,
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
        ProfileTab(
          userProfile: userProfile!,
          userDevices: userDevices,
          isUploadingImage: isUploadingImage,
          onImagePicker: showImagePicker,
          onEditProfile: editProfile,
        ),
        ChildrenTab(
          childrenInfo: childrenInfo,
          userDevices: userDevices,
          isLoadingChildren: isLoadingChildren,
          onRefresh: loadUserData,
          onAddChild: showDeviceSelectionDialog,
          onEditChild: editChildInfo,
          onDeleteChild: deleteChildInfo,
        ),
      ],
    );
  }
}