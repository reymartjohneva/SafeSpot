import 'package:flutter/material.dart';
import '../../../services/device_service.dart';
import '../../../services/geofence_service.dart';

class DeviceStatsWidget extends StatelessWidget {
  final List<Device> devices;
  final Map<String, List<LocationHistory>> deviceLocations;
  final List<Geofence> geofences;

  const DeviceStatsWidget({
    Key? key,
    required this.devices,
    required this.deviceLocations,
    required this.geofences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeDevices = devices.where((d) => d.isActive).length;
    final devicesWithLocation = devices.where((d) => 
        deviceLocations[d.deviceId]?.isNotEmpty == true).length;
    final activeGeofences = geofences.where((g) => g.isActive).length;

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
          
          // Device Stats Row
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
          
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
              thickness: 1,
            ),
          ),
          
          // Geofence Stats Section
          Row(
            children: [
              Icon(
                Icons.layers_outlined,
                color: theme.colorScheme.onPrimaryContainer,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Geofences',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Geofence Stats Row
          Row(
            children: [
              _buildStatItem(
                'Total', 
                geofences.length.toString(), 
                Icons.layers, 
                theme,
                isSmall: true,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Active', 
                activeGeofences.toString(), 
                Icons.check_circle, 
                theme,
                isSmall: true,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Inactive', 
                (geofences.length - activeGeofences).toString(), 
                Icons.pause_circle, 
                theme,
                isSmall: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label, 
    String value, 
    IconData icon, 
    ThemeData theme, {
    bool isSmall = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: isSmall ? 14 : 16,
        ),
        SizedBox(height: isSmall ? 2 : 4),
        Text(
          value,
          style: (isSmall ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
            fontSize: isSmall ? 10 : null,
          ),
        ),
      ],
    );
  }
}