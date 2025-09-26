import 'package:flutter/material.dart';
import 'package:safe_spot/models/child_info.dart';
import 'package:safe_spot/services/device_service.dart';
import '../widgets/child_info_card.dart';

class ChildrenList extends StatelessWidget {
  final List<ChildInfo> childrenInfo;
  final List<Device> userDevices;
  final Function(ChildInfo) onEditChild;
  final Function(ChildInfo) onDeleteChild;

  const ChildrenList({
    super.key,
    required this.childrenInfo,
    required this.userDevices,
    required this.onEditChild,
    required this.onDeleteChild,
  });

  @override
  Widget build(BuildContext context) {
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
}