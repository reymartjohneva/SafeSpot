import 'package:flutter/material.dart';
import 'edit_child_info_state.dart';

class EditChildInfoUI {
  static Widget buildScreen({
    required BuildContext context,
    required EditChildInfoState state,
    required String deviceName,
    required bool isEditMode,
    required VoidCallback onSave,
    required Function(String?) onGenderChanged,
    required Function(String?) onRelationshipChanged,
    required VoidCallback onAvatarTap,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildAppBar(context, isEditMode, onSave, state),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: state.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device info card
              _buildDeviceInfoCard(deviceName),
              const SizedBox(height: 24),

              // Avatar section
              _buildAvatarSection(state, onAvatarTap),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: state.childNameController,
                label: 'Child Name',
                hint: 'Enter child\'s name',
                icon: Icons.child_care,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Child name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: state.ageController,
                label: 'Age',
                hint: 'Enter age',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 0 || age > 18) {
                    return 'Please enter a valid age (0-18)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildGenderSelector(state, onGenderChanged),
              const SizedBox(height: 16),
              _buildRelationshipSelector(state, onRelationshipChanged),

              const SizedBox(height: 24),

              // Additional Information
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: state.schoolController,
                label: 'School (Optional)',
                hint: 'Enter school name',
                icon: Icons.school,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: state.emergencyContactController,
                label: 'Emergency Contact (Optional)',
                hint: 'Enter emergency contact number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: state.medicalInfoController,
                label: 'Medical Information (Optional)',
                hint: 'Enter medical information',
                icon: Icons.medical_services,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: state.notesController,
                label: 'Additional Notes (Optional)',
                hint: 'Enter any additional notes',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static AppBar _buildAppBar(
    BuildContext context,
    bool isEditMode,
    VoidCallback onSave,
    EditChildInfoState state,
  ) {
    return AppBar(
      title: Text(
        isEditMode ? 'Edit Child Information' : 'Add Child Information',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.black87,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (state.hasChanges)
          TextButton(
            onPressed: state.isSaving ? null : onSave,
            child:
                state.isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF8A50),
                        ),
                      ),
                    )
                    : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFFFF8A50),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
          ),
      ],
    );
  }

  static Widget _buildDeviceInfoCard(String deviceName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0)),
                ),
                const SizedBox(height: 2),
                Text(
                  deviceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAvatarSection(
    EditChildInfoState state,
    VoidCallback onAvatarTap,
  ) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: state.isSaving ? null : onAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF404040),
                    border: Border.all(
                      color: const Color(0xFFFF8A50),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(child: _buildAvatarContent(state)),
                ),
                if (state.isUploadingAvatar)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF8A50),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8A50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.avatarImage != null || state.existingAvatarUrl != null
                ? 'Tap to change photo'
                : 'Tap to add photo',
            style: const TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
          ),
        ],
      ),
    );
  }

  static Widget _buildAvatarContent(EditChildInfoState state) {
    if (state.avatarImage != null) {
      return Image.file(
        state.avatarImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (state.existingAvatarUrl != null) {
      return Image.network(
        state.existingAvatarUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.child_care,
            size: 60,
            color: Color(0xFFB0B0B0),
          );
        },
      );
    } else {
      return const Icon(Icons.child_care, size: 60, color: Color(0xFFB0B0B0));
    }
  }

  static Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
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
            color: Color(0xFFB0B0B0),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF808080), size: 20),
            hintStyle: const TextStyle(color: Color(0xFF808080)),
            filled: true,
            fillColor: const Color(0xFF2D2D2D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF8A50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildGenderSelector(
    EditChildInfoState state,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB0B0B0),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF404040)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.selectedGender,
              hint: const Text(
                'Select gender',
                style: TextStyle(color: Color(0xFF808080)),
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFF2D2D2D),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF8A50)),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items:
                  ['Male', 'Female', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            value == 'Male'
                                ? Icons.male
                                : value == 'Female'
                                ? Icons.female
                                : Icons.person,
                            color: const Color(0xFFFF8A50),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildRelationshipSelector(
    EditChildInfoState state,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Relationship (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB0B0B0),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF404040)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  state.relationshipController.text.isEmpty
                      ? null
                      : state.relationshipController.text,
              hint: const Text(
                'Select relationship',
                style: TextStyle(color: Color(0xFF808080)),
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFF2D2D2D),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF8A50)),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items:
                  ['Son', 'Daughter', 'Sibling', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.family_restroom,
                            color: Color(0xFFFF8A50),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
