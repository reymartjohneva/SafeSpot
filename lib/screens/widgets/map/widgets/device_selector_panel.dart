import 'package:flutter/material.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/utils/device_utils.dart';

class DeviceSelectorPanel extends StatelessWidget {
  final List<Device> devices;
  final Map<String, List<LocationHistory>> deviceLocations;
  final String? selectedDeviceId;
  final Function(String?) onDeviceSelected;
  final Function(String) onCenterMapOnDevice;

  const DeviceSelectorPanel({
    Key? key,
    required this.devices,
    required this.deviceLocations,
    required this.selectedDeviceId,
    required this.onDeviceSelected,
    required this.onCenterMapOnDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Device Filter',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildDeviceDropdown(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceDropdown(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedDeviceId,
        hint: Text(
          'Select device to view',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        isExpanded: true,
        icon: Icon(Icons.expand_more, color: Colors.grey.shade600),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.visibility,
                    size: 14,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Show all devices'),
              ],
            ),
          ),
          ...devices.map(
            (device) => DropdownMenuItem<String>(
              value: device.deviceId,
              child: _buildDeviceDropdownItem(device),
            ),
          ),
        ],
        onChanged: (deviceId) {
          onDeviceSelected(deviceId);
          if (deviceId != null) {
            onCenterMapOnDevice(deviceId);
          }
        },
      ),
    );
  }

  Widget _buildDeviceDropdownItem(Device device) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: DeviceUtils.getDeviceColor(device.deviceId),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.smartphone,
            size: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            device.deviceName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Text(
            '${deviceLocations[device.deviceId]?.length ?? 0}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }
}