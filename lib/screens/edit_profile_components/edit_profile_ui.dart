import 'package:flutter/material.dart';
import 'package:safe_spot/models/user_profile.dart';
import 'package:safe_spot/screens/edit_profile_components/edit_profile_state.dart';
import 'package:safe_spot/screens/edit_profile_components/edit_profile_validators.dart';

class EditProfileUI {
  static Widget buildScreen({
    required BuildContext context,
    required EditProfileState state,
    required UserProfile userProfile,
    required Future<void> Function() onSaveChanges,
    required VoidCallback onBackPressed,
  }) {
    return Scaffold(
      backgroundColor: EditProfileColors.darkBackground,
      appBar: _buildAppBar(
        context: context,
        state: state,
        onSaveChanges: onSaveChanges,
        onBackPressed: onBackPressed,
      ),
      body: _buildBody(
        state: state,
        userProfile: userProfile,
        onSaveChanges: onSaveChanges,
      ),
    );
  }

  static AppBar _buildAppBar({
    required BuildContext context,
    required EditProfileState state,
    required Future<void> Function() onSaveChanges,
    required VoidCallback onBackPressed,
  }) {
    return AppBar(
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: EditProfileColors.textPrimary,
        ),
      ),
      backgroundColor: Colors.black87,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.3),
      surfaceTintColor: Colors.black87,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: EditProfileColors.textPrimary),
        onPressed: onBackPressed,
      ),
      actions: [
        if (state.hasChanges)
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: state.isLoading ? null : onSaveChanges,
              style: TextButton.styleFrom(
                foregroundColor: EditProfileColors.primaryOrange,
                backgroundColor: EditProfileColors.primaryOrange.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(EditProfileColors.primaryOrange),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  static Widget _buildBody({
    required EditProfileState state,
    required UserProfile userProfile,
    required Future<void> Function() onSaveChanges,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(userProfile),
            const SizedBox(height: 32),
            _buildEditForm(state),
            const SizedBox(height: 32),
            _buildSaveButton(state, onSaveChanges),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildProfileHeader(UserProfile userProfile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EditProfileColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EditProfileColors.borderColor),
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
          CircleAvatar(
            radius: 40,
            backgroundColor: EditProfileColors.primaryOrange.withOpacity(0.15),
            backgroundImage: userProfile.avatarUrl != null
                ? NetworkImage(userProfile.avatarUrl!)
                : null,
            child: userProfile.avatarUrl == null
                ? Text(
                    userProfile.fullName.isNotEmpty
                        ? userProfile.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: EditProfileColors.primaryOrange,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            userProfile.email,
            style: const TextStyle(
              fontSize: 16,
              color: EditProfileColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildEditForm(EditProfileState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EditProfileColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EditProfileColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: state.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: EditProfileColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: state.firstNameController,
              label: 'First Name',
              icon: Icons.person_outline_rounded,
              validator: EditProfileValidators.validateFirstName,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: state.lastNameController,
              label: 'Last Name',
              icon: Icons.person_outline_rounded,
              validator: EditProfileValidators.validateLastName,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: state.mobileController,
              label: 'Mobile Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: EditProfileValidators.validateMobile,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: EditProfileColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: EditProfileColors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: EditProfileColors.iconColor,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EditProfileColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EditProfileColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EditProfileColors.primaryOrange, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EditProfileColors.errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EditProfileColors.errorRed, width: 2),
            ),
            filled: true,
            fillColor: EditProfileColors.darkBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintStyle: const TextStyle(
              color: EditProfileColors.iconColor,
              fontSize: 16,
            ),
            errorStyle: const TextStyle(
              color: EditProfileColors.errorRed,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildSaveButton(
    EditProfileState state,
    Future<void> Function() onSaveChanges,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (state.hasChanges && !state.isLoading) ? onSaveChanges : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: state.hasChanges 
              ? EditProfileColors.primaryOrange 
              : EditProfileColors.disabledGrey,
          foregroundColor: state.hasChanges 
              ? EditProfileColors.textPrimary 
              : EditProfileColors.iconColor,
          elevation: state.hasChanges ? 2 : 0,
          shadowColor: EditProfileColors.primaryOrange.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: state.isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(EditProfileColors.textPrimary),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Saving...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_rounded,
                    size: 20,
                    color: state.hasChanges 
                        ? EditProfileColors.textPrimary 
                        : EditProfileColors.iconColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Save Changes',
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