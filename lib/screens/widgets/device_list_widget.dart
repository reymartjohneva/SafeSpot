import 'package:flutter/material.dart';
import '../../../services/device_service.dart';
import '../../../utils/device_utils.dart';

class DeviceListWidget extends StatelessWidget {
  final List<Device> devices;
  final Map<String, List<LocationHistory>> deviceLocations;
  final Function(Device) onDeleteDevice;
  final Function(String) onCenterMapOnDevice;

  const DeviceListWidget({
    Key? key,
    required this.devices,
    required this.deviceLocations,
    required this.onDeleteDevice,
    required this.onCenterMapOnDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final locations = deviceLocations[device.deviceId] ?? [];
        final latestLocation = locations.isNotEmpty ? locations.first : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                DeviceUtils.getDeviceColor(device.deviceId),
                                DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            device.isActive ? Icons.smartphone : Icons.smartphone_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      device.deviceName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _buildStatusChip(device.isActive, latestLocation != null, theme),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${device.deviceId}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              onDeleteDevice(device);
                            } else if (value == 'center') {
                              onCenterMapOnDevice(device.deviceId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'center',
                              child: Row(
                                children: [
                                  Icon(Icons.center_focus_strong, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Center on Map'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDeviceDetails(device, latestLocation, locations, theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(bool isActive, bool hasLocation, ThemeData theme) {
    Color chipColor;
    String text;
    IconData icon;

    if (isActive && hasLocation) {
      chipColor = Colors.green;
      text = 'Active';
      icon = Icons.radio_button_checked;
    } else if (isActive && !hasLocation) {
      chipColor = Colors.orange;
      text = 'No GPS';
      icon = Icons.gps_off;
    } else {
      chipColor = Colors.grey;
      text = 'Offline';
      icon = Icons.radio_button_unchecked;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceDetails(Device device, LocationHistory? latestLocation, 
      List<LocationHistory> locations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.access_time,
            'Added',
            DeviceUtils.formatDateSmart(device.createdAt),
            theme,
          ),
          if (latestLocation != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.location_history,
              'Last seen',
              DeviceUtils.formatDateSmart(latestLocation.createdAt),
              theme,
            ),
            if (latestLocation.speed != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.speed,
                'Speed',
                DeviceUtils.formatSpeed(latestLocation.speed!),
                theme,
                valueColor: DeviceUtils.getSpeedColor(latestLocation.speed),
              ),
            ],
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.timeline,
              'History',
              '${locations.length} points',
              theme,
            ),
          ] else
            _buildDetailRow(
              Icons.location_disabled,
              'Status',
              'No location data available',
              theme,
              valueColor: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, 
      ThemeData theme, {Color? valueColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}