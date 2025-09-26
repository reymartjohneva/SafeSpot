// lib/screens/edit_child_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/child_info.dart';
import '../services/child_info_service.dart';

class EditChildInfoScreen extends StatefulWidget {
  final ChildInfo? existingChildInfo;
  final String deviceId;
  final String deviceName;

  const EditChildInfoScreen({
    super.key,
    this.existingChildInfo,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<EditChildInfoScreen> createState() => _EditChildInfoScreenState();
}

class _EditChildInfoScreenState extends State<EditChildInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _schoolController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isSaving = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _relationshipOptions = [
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Nephew',
    'Niece',
    'Grandchild',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _relationshipController.dispose();
    _schoolController.dispose();
    _emergencyContactController.dispose();
    _medicalInfoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.existingChildInfo != null) {
      final child = widget.existingChildInfo!;
      _nameController.text = child.childName;
      _ageController.text = child.age.toString();
      _selectedGender = child.gender;
      _relationshipController.text = child.relationship ?? '';
      _schoolController.text = child.school ?? '';
      _emergencyContactController.text = child.emergencyContact ?? '';
      _medicalInfoController.text = child.medicalInfo ?? '';
      _notesController.text = child.notes ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          widget.existingChildInfo == null 
            ? 'Add Child Information' 
            : 'Edit Child Information',
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
          TextButton(
            onPressed: _isSaving ? null : _saveChildInfo,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFFFF8A50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceInfo(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildContactInfoSection(),
              const SizedBox(height: 24),
              _buildAdditionalInfoSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Device Information',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB0B0B0),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.deviceName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.person,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Child Name',
          hint: 'Enter child\'s name',
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
          controller: _ageController,
          label: 'Age',
          hint: 'Enter age',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Age is required';
            }
            final age = int.tryParse(value);
            if (age == null || age < 0 || age > 18) {
              return 'Age must be between 0 and 18';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Gender',
          value: _selectedGender,
          items: _genderOptions,
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Relationship',
          value: _relationshipController.text.isEmpty 
              ? null 
              : _relationshipController.text,
          items: _relationshipOptions,
          onChanged: (value) {
            _relationshipController.text = value ?? '';
          },
          isOptional: true,
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      children: [
        _buildTextField(
          controller: _schoolController,
          label: 'School (Optional)',
          hint: 'Enter school name',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emergencyContactController,
          label: 'Emergency Contact (Optional)',
          hint: 'Enter emergency contact number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final phoneRegex = RegExp(r'^[\+]?[0-9\-\(\)\s]+$');
              if (!phoneRegex.hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return _buildSection(
      title: 'Additional Information',
      icon: Icons.info_outline,
      children: [
        _buildTextField(
          controller: _medicalInfoController,
          label: 'Medical Information (Optional)',
          hint: 'Enter any medical conditions, allergies, medications, etc.',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _notesController,
          label: 'Notes (Optional)',
          hint: 'Enter any additional notes or information',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF3D3D3D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFFFF8A50),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

  Widget _buildTextField({
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        hintStyle: const TextStyle(color: Color(0xFF808080)),
        filled: true,
        fillColor: const Color(0xFF404040),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool isOptional = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        filled: true,
        fillColor: const Color(0xFF404040),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF8A50), width: 2),
        ),
      ),
      dropdownColor: const Color(0xFF2D2D2D),
      validator: isOptional
          ? null
          : (value) {
              if (value == null || value.isEmpty) {
                return '$label is required';
              }
              return null;
            },
      items: [
        if (isOptional)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Select an option', style: TextStyle(color: Color(0xFF808080))),
          ),
        ...items.map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(color: Colors.white)),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _saveChildInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final childInfo = ChildInfo(
        id: widget.existingChildInfo?.id,
        deviceId: widget.deviceId,
        childName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        relationship: _relationshipController.text.trim().isEmpty 
            ? null 
            : _relationshipController.text.trim(),
        school: _schoolController.text.trim().isEmpty 
            ? null 
            : _schoolController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim().isEmpty 
            ? null 
            : _emergencyContactController.text.trim(),
        medicalInfo: _medicalInfoController.text.trim().isEmpty 
            ? null 
            : _medicalInfoController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        createdAt: widget.existingChildInfo?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Validate the child info
      final validationError = ChildInfoService.validateChildInfo(childInfo);
      if (validationError != null) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      // Save to database
      await ChildInfoService.upsertChildInfo(childInfo);

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingChildInfo == null 
                ? 'Child information added successfully' 
                : 'Child information updated successfully',
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Return to previous screen
      Navigator.of(context).pop(true);

    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving child information: $e'),
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