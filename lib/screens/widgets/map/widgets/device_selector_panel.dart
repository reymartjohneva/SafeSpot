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
      top: 12,
      left: 12,
      right: 80, // Leave space for map controls
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune,
                  color: Colors.blue.shade600,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCompactDropdown(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDropdown(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedDeviceId,
        hint: Text(
          'Filter devices',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        isExpanded: true,
        icon: Icon(
          Icons.expand_more,
          color: Colors.grey.shade600,
          size: 16,
        ),
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.visibility,
                    size: 10,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Show all devices'),
              ],
            ),
          ),
          ...devices.map(
            (device) => DropdownMenuItem<String>(
              value: device.deviceId,
              child: _buildCompactDeviceItem(device),
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

  Widget _buildCompactDeviceItem(Device device) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: DeviceUtils.getDeviceColor(device.deviceId),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.smartphone,
            size: 8,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            device.deviceName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 0.5,
            ),
          ),
          child: Text(
            '${deviceLocations[device.deviceId]?.length ?? 0}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }
}