import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_spot/screens/edit_child_info_components/edit_child_info_state.dart';
import 'package:safe_spot/screens/edit_child_info_components/edit_child_info_validators.dart';

class EditChildInfoUI {
  static Widget buildScreen({
    required BuildContext context,
    required EditChildInfoState state,
    required String deviceName,
    required bool isEditMode,
    required Future<void> Function() onSave,
    required void Function(String) onGenderChanged,
    required void Function(String?) onRelationshipChanged,
  }) {
    return Scaffold(
      backgroundColor: EditChildInfoColors.darkBackground,
      appBar: _buildAppBar(
        context: context,
        state: state,
        isEditMode: isEditMode,
        onSave: onSave,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: state.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceInfo(deviceName),
              const SizedBox(height: 24),
              _buildBasicInfoSection(state, onGenderChanged, onRelationshipChanged),
              const SizedBox(height: 24),
              _buildContactInfoSection(state),
              const SizedBox(height: 24),
              _buildAdditionalInfoSection(state),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static AppBar _buildAppBar({
    required BuildContext context,
    required EditChildInfoState state,
    required bool isEditMode,
    required Future<void> Function() onSave,
  }) {
    return AppBar(
      title: Text(
        isEditMode ? 'Edit Child Information' : 'Add Child Information',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: EditChildInfoColors.textPrimary,
        ),
      ),
      backgroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.black87,
      iconTheme: const IconThemeData(color: EditChildInfoColors.textPrimary),
      actions: [
        TextButton(
          onPressed: state.isSaving ? null : onSave,
          child: state.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      EditChildInfoColors.primaryOrange,
                    ),
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(
                    color: EditChildInfoColors.primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  static Widget _buildDeviceInfo(String deviceName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EditChildInfoColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EditChildInfoColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EditChildInfoColors.primaryOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.devices,
              color: EditChildInfoColors.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Device Information',
                style: TextStyle(
                  fontSize: 14,
                  color: EditChildInfoColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                deviceName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: EditChildInfoColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildBasicInfoSection(
    EditChildInfoState state,
    void Function(String) onGenderChanged,
    void Function(String?) onRelationshipChanged,
  ) {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.person,
      children: [
        _buildTextField(
          controller: state.nameController,
          label: 'Child Name',
          hint: 'Enter child\'s name',
          validator: EditChildInfoValidators.validateChildName,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: state.ageController,
          label: 'Age',
          hint: 'Enter age',
          keyboardType: TextInputType.number,
          inputFormatters: EditChildInfoValidators.getDigitsOnlyFormatter(),
          validator: EditChildInfoValidators.validateAge,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Gender',
          value: state.selectedGender,
          items: state.genderOptions,
          onChanged: (value) => onGenderChanged(value!),
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Relationship',
          value: state.relationshipController.text.isEmpty 
              ? null 
              : state.relationshipController.text,
          items: state.relationshipOptions,
          onChanged: onRelationshipChanged,
          isOptional: true,
        ),
      ],
    );
  }

  static Widget _buildContactInfoSection(EditChildInfoState state) {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      children: [
        _buildTextField(
          controller: state.schoolController,
          label: 'School (Optional)',
          hint: 'Enter school name',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: state.emergencyContactController,
          label: 'Emergency Contact (Optional)',
          hint: 'Enter emergency contact number',
          keyboardType: TextInputType.phone,
          validator: EditChildInfoValidators.validateEmergencyContact,
        ),
      ],
    );
  }

  static Widget _buildAdditionalInfoSection(EditChildInfoState state) {
    return _buildSection(
      title: 'Additional Information',
      icon: Icons.info_outline,
      children: [
        _buildTextField(
          controller: state.medicalInfoController,
          label: 'Medical Information (Optional)',
          hint: 'Enter any medical conditions, allergies, medications, etc.',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: state.notesController,
          label: 'Notes (Optional)',
          hint: 'Enter any additional notes or information',
          maxLines: 3,
        ),
      ],
    );
  }

  static Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: EditChildInfoColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EditChildInfoColors.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: EditChildInfoColors.sectionHeaderBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: EditChildInfoColors.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: EditChildInfoColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: EditChildInfoColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: EditChildInfoColors.textSecondary),
        hintStyle: const TextStyle(color: EditChildInfoColors.textHint),
        filled: true,
        fillColor: EditChildInfoColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: EditChildInfoColors.primaryOrange,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: EditChildInfoColors.errorRed,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: EditChildInfoColors.errorRed,
            width: 2,
          ),
        ),
      ),
    );
  }

  static Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool isOptional = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(color: EditChildInfoColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: EditChildInfoColors.textSecondary),
        filled: true,
        fillColor: EditChildInfoColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: EditChildInfoColors.primaryOrange,
            width: 2,
          ),
        ),
      ),
      dropdownColor: EditChildInfoColors.cardBackground,
      validator: isOptional
          ? null
          : (value) => EditChildInfoValidators.validateDropdownRequired(value, label),
      items: [
        if (isOptional)
          const DropdownMenuItem<String>(
            value: null,
            child: Text(
              'Select an option',
              style: TextStyle(color: EditChildInfoColors.textHint),
            ),
          ),
        ...items.map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(color: EditChildInfoColors.textPrimary),
              ),
            )),
      ],
      onChanged: onChanged,
    );
  }
}