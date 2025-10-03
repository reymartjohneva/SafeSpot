import 'package:flutter/material.dart';
import '../models/child_info.dart';
import 'package:safe_spot/screens/edit_child_info_components/edit_child_info_state.dart';
import 'package:safe_spot/screens/edit_child_info_components/edit_child_info_logic.dart';
import 'package:safe_spot/screens/edit_child_info_components/edit_child_info_ui.dart';

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

class _EditChildInfoScreenState extends State<EditChildInfoScreen>
    with EditChildInfoLogic {
  @override
  final EditChildInfoState state = EditChildInfoState();

  @override
  ChildInfo? get existingChildInfo => widget.existingChildInfo;

  @override
  String get deviceId => widget.deviceId;

  @override
  String get deviceName => widget.deviceName;

  @override
  void initState() {
    super.initState();
    initializeForm();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditChildInfoUI.buildScreen(
      context: context,
      state: state,
      deviceName: widget.deviceName,
      isEditMode: widget.existingChildInfo != null,
      onSave: saveChildInfo,
      onGenderChanged: (value) {
        setState(() {
          state.selectedGender = value;
        });
      },
      onRelationshipChanged: (value) {
        state.relationshipController.text = value ?? '';
      },
      onAvatarTap: showAvatarPicker,
    );
  }
}
