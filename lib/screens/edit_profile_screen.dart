import 'package:flutter/material.dart';
import 'package:safe_spot/models/user_profile.dart';
import 'package:safe_spot/screens/edit_profile_components/edit_profile_state.dart';
import 'package:safe_spot/screens/edit_profile_components/edit_profile_logic.dart';
import 'package:safe_spot/screens/edit_profile_components/edit_profile_ui.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> 
    with EditProfileLogic {
  
  @override
  final EditProfileState state = EditProfileState();

  @override
  UserProfile get userProfile => widget.userProfile;

  @override
  void initState() {
    super.initState();
    initializeControllers();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditProfileUI.buildScreen(
      context: context,
      state: state,
      userProfile: widget.userProfile,
      onSaveChanges: saveChanges,
      onBackPressed: onBackPressed,
    );
  }
}