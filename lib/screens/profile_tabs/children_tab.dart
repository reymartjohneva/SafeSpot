import 'package:flutter/material.dart';
import 'package:safe_spot/models/child_info.dart';
import 'package:safe_spot/services/device_service.dart';
import '../widgets/child_info_card.dart';

class ChildrenTab extends StatelessWidget {
  final List<ChildInfo> childrenInfo;
  final List<Device> userDevices;
  final bool isLoadingChildren;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddChild;
  final Function(ChildInfo) onEditChild;
  final Function(ChildInfo) onDeleteChild;

  const ChildrenTab({
    super.key,
    required this.childrenInfo,
    required this.userDevices,
    required this.isLoadingChildren,
    required this.onRefresh,
    required this.onAddChild,
    required this.onEditChild,
    required this.onDeleteChild,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingChildren) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
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
                onPressed: onAddChild,
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
            onEdit: () => onEditChild(childInfo),
            onDelete: () => onDeleteChild(childInfo),
          );
        }).toList(),
      ),
    );
  }

  Device? _findDeviceById(String deviceId) {
    try {
      return userDevices.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
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
              onPressed: onAddChild,
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
}