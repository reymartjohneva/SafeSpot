import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/device_service.dart';
import '../../utils/device_utils.dart';

class DeviceMapWidget extends StatelessWidget {
  final MapController mapController;
  final List<Device> devices;
  final Map<String, List<LocationHistory>> deviceLocations;
  final String? selectedDeviceId;
  final Function(String?) onDeviceSelected;
  final Function(String) onCenterMapOnDevice;
  final Device? Function(String) findDeviceById;

  const DeviceMapWidget({
    Key? key,
    required this.mapController,
    required this.devices,
    required this.deviceLocations,
    required this.selectedDeviceId,
    required this.onDeviceSelected,
    required this.onCenterMapOnDevice,
    required this.findDeviceById,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: LatLng(8.9511, 125.5439),
                zoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safespot',
                ),
                // Location history lines
                PolylineLayer(
                  polylines: _buildPolylines(),
                ),
                // Historical markers
                MarkerLayer(
                  markers: _buildHistoricalMarkers(),
                ),
                // Latest location markers
                MarkerLayer(
                  markers: _buildLatestLocationMarkers(),
                ),
                // Device info popup
                if (selectedDeviceId != null &&
                    deviceLocations[selectedDeviceId]?.isNotEmpty == true)
                  MarkerLayer(
                    markers: _buildInfoPopupMarkers(constraints),
                  ),
              ],
            ),
            _buildDeviceSelector(context),
            _buildLegend(context, constraints),
            _buildMapControls(context),
          ],
        );
      },
    );
  }

  List<Polyline> _buildPolylines() {
    return deviceLocations.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) {
          final deviceId = entry.key;
          final locations = entry.value;
          final device = findDeviceById(deviceId);

          if (device == null) return null;

          final isSelected = selectedDeviceId == null || selectedDeviceId == deviceId;
          if (!isSelected) return null;

          final points = locations.reversed
              .map((location) => LatLng(location.latitude, location.longitude))
              .toList();

          return Polyline(
            points: points,
            strokeWidth: isSelected && selectedDeviceId == deviceId ? 3.0 : 2.0,
            color: DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.7),
          );
        })
        .where((polyline) => polyline != null)
        .cast<Polyline>()
        .toList();
  }

  List<Marker> _buildHistoricalMarkers() {
    return deviceLocations.entries.expand((entry) {
      final deviceId = entry.key;
      final locations = entry.value;
      if (locations.isEmpty) return <Marker>[];

      final device = findDeviceById(deviceId);
      if (device == null) return <Marker>[];

      final isSelected = selectedDeviceId == null || selectedDeviceId == deviceId;
      if (!isSelected || locations.length <= 1) return <Marker>[];

      final locationsList = locations.skip(1).toList();
      return locationsList.map((location) {
        return Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 12,
          height: 12,
          builder: (context) => Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DeviceUtils.getDeviceColor(device.deviceId),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      }).toList();
    }).toList();
  }

  List<Marker> _buildLatestLocationMarkers() {
    return deviceLocations.entries.expand((entry) {
      final deviceId = entry.key;
      final locations = entry.value;
      if (locations.isEmpty) return <Marker>[];

      final device = findDeviceById(deviceId);
      if (device == null) return <Marker>[];

      final latestLocation = locations.first;
      final isSelected = selectedDeviceId == deviceId;
      final isVisible = selectedDeviceId == null || selectedDeviceId == deviceId;

      if (!isVisible) return <Marker>[];

      return [
        Marker(
          point: LatLng(latestLocation.latitude, latestLocation.longitude),
          width: isSelected ? 70 : 60,
          height: isSelected ? 70 : 60,
          builder: (context) => GestureDetector(
            onTap: () {
              onDeviceSelected(selectedDeviceId == deviceId ? null : deviceId);
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    latestLocation.speed != null
                        ? DeviceUtils.getSpeedColor(latestLocation.speed)
                        : DeviceUtils.getDeviceColor(device.deviceId),
                    (latestLocation.speed != null
                            ? DeviceUtils.getSpeedColor(latestLocation.speed)
                            : DeviceUtils.getDeviceColor(device.deviceId))
                        .withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isSelected ? Colors.yellow : Colors.white,
                  width: isSelected ? 4 : 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    device.isActive ? Icons.smartphone : Icons.smartphone_outlined,
                    color: Colors.white,
                    size: isSelected ? 24 : 20,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        device.deviceName.length > 8
                            ? '${device.deviceName.substring(0, 8)}...'
                            : device.deviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ];
    }).toList();
  }

  List<Marker> _buildInfoPopupMarkers(BoxConstraints constraints) {
    final locations = deviceLocations[selectedDeviceId]!;
    final device = findDeviceById(selectedDeviceId!);
    if (device == null) return [];

    final latestLocation = locations.first;
    final theme = ThemeData();

    return [
      Marker(
        point: LatLng(latestLocation.latitude, latestLocation.longitude),
        width: constraints.maxWidth > 300 ? 220 : constraints.maxWidth - 80,
        height: 140,
        builder: (context) => Transform.translate(
          offset: const Offset(0, -120),
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: constraints.maxWidth - 80),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DeviceUtils.getDeviceColor(device.deviceId),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DeviceUtils.getDeviceColor(device.deviceId),
                      ),
                      child: const Icon(Icons.smartphone, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        device.deviceName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Last seen',
                  DeviceUtils.formatDateSmart(latestLocation.createdAt),
                  context,
                ),
                if (latestLocation.speed != null)
                  _buildInfoRow(
                    Icons.speed,
                    'Speed',
                    DeviceUtils.formatSpeed(latestLocation.speed!),
                    context,
                    valueColor: DeviceUtils.getSpeedColor(latestLocation.speed),
                  ),
                _buildInfoRow(
                  Icons.timeline,
                  'History',
                  '${locations.length} points',
                  context,
                ),
                _buildInfoRow(
                  Icons.radio_button_checked,
                  'Status',
                  device.isActive ? 'Active' : 'Inactive',
                  context,
                  valueColor: device.isActive ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildInfoRow(IconData icon, String label, String value, BuildContext context,
      {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor ?? theme.colorScheme.onSurface,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: selectedDeviceId,
                hint: const Text('Select device to view'),
                isExpanded: true,
                underline: Container(),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 16),
                        SizedBox(width: 8),
                        Text('Show all devices'),
                      ],
                    ),
                  ),
                  ...devices.map(
                    (device) => DropdownMenuItem<String>(
                      value: device.deviceId,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DeviceUtils.getDeviceColor(device.deviceId),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              device.deviceName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${deviceLocations[device.deviceId]?.length ?? 0}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, BoxConstraints constraints) {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: constraints.maxWidth > 400 ? 240 : constraints.maxWidth - 100,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Map Legend',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLegendItem(Icons.radio_button_unchecked, 'Historical points', Colors.blue),
            const SizedBox(height: 8),
            _buildLegendItem(Icons.smartphone, 'Current location', Colors.blue),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 20, height: 2, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Movement path', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Speed indicators:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildSpeedLegend('< 5', Colors.red),
                _buildSpeedLegend('5-30', Colors.orange),
                _buildSpeedLegend('30-60', Colors.blue),
                _buildSpeedLegend('> 60', Colors.green),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'km/h',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSpeedLegend(String range, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(range, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildMapControls(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: () => _fitMapToBounds(),
            heroTag: "fit_bounds",
            child: const Icon(Icons.fit_screen),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            onPressed: () {
              mapController.move(LatLng(8.9511, 125.5439), 13.0);
            },
            heroTag: "center_map",
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  void _fitMapToBounds() {
    if (devices.isNotEmpty) {
      final allPoints = <LatLng>[];
      for (var device in devices) {
        final locations = deviceLocations[device.deviceId];
        if (locations != null && locations.isNotEmpty) {
          allPoints.add(LatLng(
            locations.first.latitude,
            locations.first.longitude,
          ));
        }
      }
      if (allPoints.isNotEmpty) {
        double minLat = allPoints.first.latitude;
        double maxLat = allPoints.first.latitude;
        double minLng = allPoints.first.longitude;
        double maxLng = allPoints.first.longitude;

        for (var point in allPoints) {
          minLat = minLat < point.latitude ? minLat : point.latitude;
          maxLat = maxLat > point.latitude ? maxLat : point.latitude;
          minLng = minLng < point.longitude ? minLng : point.longitude;
          maxLng = maxLng > point.longitude ? maxLng : point.longitude;
        }

        mapController.fitBounds(
          LatLngBounds(
            LatLng(minLat, minLng),
            LatLng(maxLat, maxLng),
          ),
          options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
        );
      }
    }
  }
}