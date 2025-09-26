import 'package:flutter/material.dart';
import 'package:safe_spot/services/child_info_service.dart';
import 'package:safe_spot/models/child_info.dart';
import 'package:safe_spot/screens/edit_child_info_screen.dart';
import 'package:safe_spot/services/device_service.dart';

mixin ChildInfoMixin<T extends StatefulWidget> on State<T> {
  // These should be implemented by the class using this mixin
  List<Device> get userDevices;
  List<ChildInfo> get childrenInfo;
  Future<void> loadUserData();

  Device? findDeviceById(String deviceId) {
    try {
      return userDevices.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }

  void showDeviceSelectionDialog() {
    final availableDevices = userDevices.where((device) {
      return !childrenInfo.any((child) => child.deviceId == device.deviceId);
    }).toList();

    if (availableDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All devices already have child information added'),
          backgroundColor: Color(0xFFFF8A50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Select Device',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose a device to add child information for:',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
            const SizedBox(height: 16),
            ...availableDevices.map((device) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
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
                title: Text(
                  device.deviceName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'ID: ${device.deviceId}',
                  style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  addChildInfo(device);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF404040)),
                ),
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> addChildInfo(Device device) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditChildInfoScreen(
          deviceId: device.deviceId,
          deviceName: device.deviceName,
        ),
      ),
    );

    if (result == true) {
      await loadUserData();
    }
  }

  Future<void> editChildInfo(ChildInfo childInfo) async {
    final device = findDeviceById(childInfo.deviceId);
    if (device == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditChildInfoScreen(
          existingChildInfo: childInfo,
          deviceId: device.deviceId,
          deviceName: device.deviceName,
        ),
      ),
    );

    if (result == true) {
      await loadUserData();
    }
  }

  Future<void> deleteChildInfo(ChildInfo childInfo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Delete Child Information',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete information for ${childInfo.childName}? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ChildInfoService.deleteChildInfo(childInfo.deviceId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Information for ${childInfo.childName} deleted successfully'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        await loadUserData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting child information: $e'),
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
}