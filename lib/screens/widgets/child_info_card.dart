// lib/widgets/child_info_card.dart
import 'package:flutter/material.dart';
import 'package:safe_spot/models/child_info.dart';
import 'package:safe_spot/widgets/child_avatar_widget.dart';

class ChildInfoCard extends StatelessWidget {
  final ChildInfo childInfo;
  final String deviceName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ChildInfoCard({
    super.key,
    required this.childInfo,
    required this.deviceName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header with avatar, device info and actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF3D3D3D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                ChildAvatarWidget(
                  avatarUrl: childInfo.avatarUrl,
                  childName: childInfo.childName,
                  size: 60,
                ),
                const SizedBox(width: 16),
                // Child info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childInfo.childName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Device: $deviceName',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFB0B0B0),
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu
                PopupMenuButton<String>(
                  color: const Color(0xFF2D2D2D),
                  icon: const Icon(Icons.more_vert, color: Color(0xFFB0B0B0)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: Color(0xFFFF8A50),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),

          // Child information content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow('Age', '${childInfo.age} years old', Icons.cake),
                _buildInfoRow('Gender', childInfo.gender, Icons.person),
                if (childInfo.relationship != null &&
                    childInfo.relationship!.isNotEmpty)
                  _buildInfoRow(
                    'Relationship',
                    childInfo.relationship!,
                    Icons.family_restroom,
                  ),
                if (childInfo.school != null && childInfo.school!.isNotEmpty)
                  _buildInfoRow('School', childInfo.school!, Icons.school),
                if (childInfo.emergencyContact != null &&
                    childInfo.emergencyContact!.isNotEmpty)
                  _buildInfoRow(
                    'Emergency Contact',
                    childInfo.emergencyContact!,
                    Icons.phone,
                  ),
                if (childInfo.medicalInfo != null &&
                    childInfo.medicalInfo!.isNotEmpty)
                  _buildInfoRow(
                    'Medical Info',
                    childInfo.medicalInfo!,
                    Icons.medical_services,
                  ),
                if (childInfo.notes != null && childInfo.notes!.isNotEmpty)
                  _buildInfoRow('Notes', childInfo.notes!, Icons.note),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF404040),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFB0B0B0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0B0B0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
