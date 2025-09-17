import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/utils/device_utils.dart';

class DeviceInfoPopup extends StatelessWidget {
  final Device device;
  final LocationHistory latestLocation;
  final int locationCount;
  final BoxConstraints constraints;

  const DeviceInfoPopup({
    Key? key,
    required this.device,
    required this.latestLocation,
    required this.locationCount,
    required this.constraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(latestLocation.latitude, latestLocation.longitude),
          width: constraints.maxWidth > 300 ? 240 : constraints.maxWidth - 80,
          height: 160,
          builder: (context) => _buildPopupCard(context),
        ),
      ],
    );
  }

  Widget _buildPopupCard(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -140),
      child: Card(
        elevation: 12,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth - 80),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDeviceHeader(context),
                const SizedBox(height: 16),
                ..._buildDeviceInfoItems(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DeviceUtils.getDeviceColor(device.deviceId),
                DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.smartphone,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.deviceName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Device Information',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDeviceInfoItems(BuildContext context) {
    List<Widget> items = [
      _buildInfoRow(
        Icons.access_time_filled,
        'Last seen',
        DeviceUtils.formatDateSmart(latestLocation.createdAt),
        context,
      ),
      const SizedBox(height: 8),
      if (latestLocation.speed != null)
        Column(
          children: [
            _buildInfoRow(
              Icons.speed,
              'Speed',
              DeviceUtils.formatSpeed(latestLocation.speed!),
              context,
              valueColor: DeviceUtils.getSpeedColor(latestLocation.speed),
            ),
            const SizedBox(height: 8),
          ],
        ),
      _buildInfoRow(
        Icons.timeline,
        'History',
        '$locationCount points',
        context,
      ),
      const SizedBox(height: 8),
      _buildInfoRow(
        Icons.radio_button_checked,
        'Status',
        device.isActive ? 'Active' : 'Inactive',
        context,
        valueColor: device.isActive ? Colors.green.shade600 : Colors.orange.shade600,
      ),
    ];

    return items;
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    BuildContext context, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: (valueColor ?? theme.colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: valueColor ?? theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (valueColor ?? theme.colorScheme.onSurface).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
