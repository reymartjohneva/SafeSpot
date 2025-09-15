import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/device_service.dart';
import '../../services/geofence_service.dart';
import '../../utils/device_utils.dart';

class DeviceMapWidget extends StatelessWidget {
  final MapController mapController;
  final List<Device> devices;
  final Map<String, List<LocationHistory>> deviceLocations;
  final String? selectedDeviceId;
  final Position? currentPosition;
  final List<Geofence> geofences;
  final List<LatLng> currentGeofencePoints;
  final bool isDrawingGeofence;
  final bool isDragging;
  final int? draggedPointIndex;
  final Function(String?) onDeviceSelected;
  final Function(String) onCenterMapOnDevice;
  final VoidCallback onCenterMapOnCurrentLocation;
  final Function(TapPosition, LatLng) onMapTap;
  final Function(TapPosition, LatLng) onMapLongPress;
  final Device? Function(String) findDeviceById;

  const DeviceMapWidget({
    Key? key,
    required this.mapController,
    required this.devices,
    required this.deviceLocations,
    required this.selectedDeviceId,
    this.currentPosition,
    this.geofences = const [],
    this.currentGeofencePoints = const [],
    this.isDrawingGeofence = false,
    this.isDragging = false,
    this.draggedPointIndex,
    required this.onDeviceSelected,
    required this.onCenterMapOnDevice,
    required this.onCenterMapOnCurrentLocation,
    required this.onMapTap,
    required this.onMapLongPress,
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
                center: currentPosition != null
                    ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                    : LatLng(8.9511, 125.5439),
                zoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onTap: onMapTap,
                onLongPress: onMapLongPress,
              ),
              children: [
                // Tile Layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safespot',
                ),

                // Geofences Polygons
                PolygonLayer(
                  polygons: [
                    // Existing geofences
                    ...geofences.map(
                      (geofence) => Polygon(
                        points: geofence.points,
                        color: geofence.color.withOpacity(0.2),
                        borderColor: geofence.color,
                        borderStrokeWidth: 2.0,
                      ),
                    ),
                    // Current drawing geofence
                    if (currentGeofencePoints.length >= 3)
                      Polygon(
                        points: currentGeofencePoints,
                        color: Colors.orange.withOpacity(0.2),
                        borderColor: isDragging
                            ? Colors.orange.shade700
                            : Colors.orange,
                        borderStrokeWidth: isDragging ? 3.0 : 2.0,
                      ),
                  ],
                ),

                // Current geofence drawing markers
                if (currentGeofencePoints.isNotEmpty)
                  MarkerLayer(
                    markers: currentGeofencePoints
                        .asMap()
                        .entries
                        .map(
                          (entry) => Marker(
                            point: entry.value,
                            width: draggedPointIndex == entry.key ? 28 : 24,
                            height: draggedPointIndex == entry.key ? 28 : 24,
                            builder: (context) => Container(
                              width: draggedPointIndex == entry.key ? 28 : 24,
                              height: draggedPointIndex == entry.key ? 28 : 24,
                              decoration: BoxDecoration(
                                color: draggedPointIndex == entry.key
                                    ? Colors.orange.shade700
                                    : Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: draggedPointIndex == entry.key ? 3 : 2,
                                ),
                                boxShadow: [
                                  if (draggedPointIndex == entry.key)
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: draggedPointIndex == entry.key ? 12 : 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                // Connection lines between geofence points
                if (currentGeofencePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: currentGeofencePoints,
                        strokeWidth: isDragging ? 3.0 : 2.0,
                        color: (isDragging
                                ? Colors.orange.shade700
                                : Colors.orange)
                            .withOpacity(0.8),
                      ),
                    ],
                  ),

                // Device location history lines
                PolylineLayer(
                  polylines: _buildDevicePolylines(),
                ),

                // Historical device markers
                MarkerLayer(
                  markers: _buildHistoricalDeviceMarkers(),
                ),

                // Current user location accuracy circle
                if (currentPosition != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                        ),
                        radius: currentPosition!.accuracy,
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.1),
                        borderColor: Colors.blue.withOpacity(0.3),
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),

                // Current user location marker
                if (currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                        ),
                        width: 30,
                        height: 30,
                        builder: (context) => Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade600,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                // Latest device location markers
                MarkerLayer(
                  markers: _buildLatestDeviceLocationMarkers(),
                ),

                // Device info popup
                if (selectedDeviceId != null &&
                    deviceLocations[selectedDeviceId]?.isNotEmpty == true)
                  MarkerLayer(
                    markers: _buildDeviceInfoPopupMarkers(constraints),
                  ),
              ],
            ),

            // Device selector
            _buildDeviceSelector(context),

            // Map legend
            _buildLegend(context, constraints),

            // Map controls
            _buildMapControls(context),
          ],
        );
      },
    );
  }

  List<Polyline> _buildDevicePolylines() {
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

  List<Marker> _buildHistoricalDeviceMarkers() {
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

  List<Marker> _buildLatestDeviceLocationMarkers() {
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

  List<Marker> _buildDeviceInfoPopupMarkers(BoxConstraints constraints) {
    final locations = deviceLocations[selectedDeviceId]!;
    final device = findDeviceById(selectedDeviceId!);
    if (device == null) return [];

    final latestLocation = locations.first;

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
            _buildLegendItem(Icons.smartphone, 'Device location', Colors.blue),
            if (currentPosition != null) ...[
              const SizedBox(height: 8),
              _buildLegendItem(Icons.my_location, 'Your location', Colors.blue),
            ],
            if (geofences.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildLegendItem(Icons.layers, 'Geofences', Colors.orange),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 20, height: 2, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Movement path', style: Theme.of(context).textTheme.bodySmall),
              ],
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

  Widget _buildMapControls(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Fit bounds button
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.small(
              onPressed: () => _fitMapToBounds(),
              heroTag: "fit_bounds",
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.fit_screen, color: Colors.black54, size: 20),
            ),
          ),
          
          // My location button
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.small(
              onPressed: onCenterMapOnCurrentLocation,
              heroTag: "my_location",
              backgroundColor: currentPosition != null ? Colors.blue.shade50 : Colors.white,
              elevation: 4,
              child: Icon(
                Icons.my_location, 
                color: currentPosition != null ? Colors.blue.shade700 : Colors.grey.shade600, 
                size: 20,
              ),
            ),
          ),
          
          // Home/center button
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.small(
              onPressed: () {
                mapController.move(LatLng(8.9511, 125.5439), 13.0);
              },
              heroTag: "center_map",
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.home, color: Colors.black54, size: 20),
            ),
          ),
          
          // Zoom in button
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: FloatingActionButton.small(
              onPressed: () {
                var currentZoom = mapController.zoom;
                if (currentZoom < 18) {
                  mapController.move(
                    mapController.center,
                    currentZoom + 1,
                  );
                }
              },
              heroTag: "zoom_in",
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.black54, size: 20),
            ),
          ),
          
          // Zoom out button
          Container(
            child: FloatingActionButton.small(
              onPressed: () {
                var currentZoom = mapController.zoom;
                if (currentZoom > 5) {
                  mapController.move(
                    mapController.center,
                    currentZoom - 1,
                  );
                }
              },
              heroTag: "zoom_out",
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.remove, color: Colors.black54, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _fitMapToBounds() {
    final allPoints = <LatLng>[];
    
    // Add current user location if available
    if (currentPosition != null) {
      allPoints.add(LatLng(currentPosition!.latitude, currentPosition!.longitude));
    }
    
    // Add device locations
    for (var device in devices) {
      final locations = deviceLocations[device.deviceId];
      if (locations != null && locations.isNotEmpty) {
        allPoints.add(LatLng(
          locations.first.latitude,
          locations.first.longitude,
        ));
      }
    }
    
    // Add geofence points
    for (var geofence in geofences) {
      if (geofence.points.isNotEmpty) {
        allPoints.addAll(geofence.points);
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

      // Add some padding to the bounds
      const padding = 0.01;
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;

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