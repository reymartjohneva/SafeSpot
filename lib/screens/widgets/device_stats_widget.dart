import 'package:flutter/material.dart';
import '../../../services/device_service.dart';

class DeviceStatsWidget extends StatelessWidget {
  final List<Device> devices;
  final Map<String, List<LocationHistory>> deviceLocations;

  const DeviceStatsWidget({
    Key? key,
    required this.devices,
    required this.deviceLocations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeDevices = devices.where((d) => d.isActive).length;
    final devicesWithLocation = devices.where((d) => 
        deviceLocations[d.deviceId]?.isNotEmpty == true).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                'Total', 
                devices.length.toString(), 
                Icons.devices, 
                theme
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Active', 
                activeDevices.toString(), 
                Icons.radio_button_checked, 
                theme
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Located', 
                devicesWithLocation.toString(), 
                Icons.location_on, 
                theme
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}