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
          width: constraints.maxWidth > 300 ? 180 : constraints.maxWidth - 60,
          height: 120,
          builder: (context) => _buildCompactPopup(context),
        ),
      ],
    );
  }

  Widget _buildCompactPopup(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -110),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: constraints.maxWidth - 60,
          maxHeight: 120,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactHeader(context),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: _buildCompactInfoItems(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DeviceUtils.getDeviceColor(device.deviceId),
                DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.smartphone, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.deviceName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Device Info',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCompactInfoItems(BuildContext context) {
    List<Widget> items = [
      _buildCompactInfoRow(
        Icons.access_time_filled,
        DeviceUtils.formatDateSmart(latestLocation.timestamp),
        context,
      ),
      const SizedBox(height: 4),
    ];

    if (latestLocation.speed != null) {
      items.addAll([
        _buildCompactInfoRow(
          Icons.speed,
          DeviceUtils.formatSpeed(latestLocation.speed!),
          context,
          valueColor: DeviceUtils.getSpeedColor(latestLocation.speed),
        ),
        const SizedBox(height: 4),
      ]);
    }

    items.addAll([
      _buildCompactInfoRow(Icons.timeline, '$locationCount pts', context),
      const SizedBox(height: 4),
      _buildCompactInfoRow(
        Icons.radio_button_checked,
        device.isActive ? 'Active' : 'Inactive',
        context,
        valueColor:
            device.isActive ? Colors.green.shade600 : Colors.orange.shade600,
      ),
    ]);

    return items;
  }

  Widget _buildCompactInfoRow(
    IconData icon,
    String value,
    BuildContext context, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: (valueColor ?? theme.colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 10,
            color: valueColor ?? theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (valueColor ?? theme.colorScheme.onSurface).withOpacity(
                0.08,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? theme.colorScheme.onSurface,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
