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
            // Main Map
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

            // Top Controls Panel
            _buildTopControlsPanel(context, constraints),

            // Bottom Information Panel
            _buildBottomInformationPanel(context, constraints),

            // Right Side Map Controls
            _buildMapControlsPanel(context),
          ],
        );
      },
    );
  }

  // Top Controls Panel with Device Selector
  Widget _buildTopControlsPanel(BuildContext context, BoxConstraints constraints) {
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
                      DropdownButtonHideUnderline(
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
                                child: Row(
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bottom Information Panel with Legend
  Widget _buildBottomInformationPanel(BuildContext context, BoxConstraints constraints) {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth > 400 ? 280 : constraints.maxWidth - 120,
          ),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Legend Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.map_outlined,
                        size: 16,
                        color: Colors.orange.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Map Legend',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Legend Items
                _buildLegendItem(
                  Icons.radio_button_unchecked,
                  'Historical points',
                  Colors.blue.shade400,
                  context,
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  Icons.smartphone,
                  'Device location',
                  Colors.green.shade500,
                  context,
                ),
                if (currentPosition != null) ...[
                  const SizedBox(height: 12),
                  _buildLegendItem(
                    Icons.my_location,
                    'Your location',
                    Colors.blue.shade600,
                    context,
                  ),
                ],
                if (geofences.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildLegendItem(
                    Icons.layers_outlined,
                    'Geofences',
                    Colors.orange.shade500,
                    context,
                  ),
                ],
                const SizedBox(height: 12),
                
                // Movement Path
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Movement path',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Right Side Map Controls Panel
  Widget _buildMapControlsPanel(BuildContext context) {
    return Positioned(
      bottom: 16,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fit bounds button
                _buildMapControlButton(
                  icon: Icons.fit_screen_outlined,
                  onPressed: () => _fitMapToBounds(),
                  backgroundColor: Colors.purple.shade50,
                  iconColor: Colors.purple.shade600,
                  tooltip: 'Fit to bounds',
                ),
                
                const SizedBox(height: 8),
                
                // My location button
                _buildMapControlButton(
                  icon: Icons.my_location_outlined,
                  onPressed: onCenterMapOnCurrentLocation,
                  backgroundColor: currentPosition != null 
                      ? Colors.blue.shade50 
                      : Colors.grey.shade100,
                  iconColor: currentPosition != null 
                      ? Colors.blue.shade600 
                      : Colors.grey.shade500,
                  tooltip: 'My location',
                ),
                
                const SizedBox(height: 8),
                
                // Home/center button
                _buildMapControlButton(
                  icon: Icons.home_outlined,
                  onPressed: () {
                    mapController.move(LatLng(8.9511, 125.5439), 13.0);
                  },
                  backgroundColor: Colors.green.shade50,
                  iconColor: Colors.green.shade600,
                  tooltip: 'Center map',
                ),
                
                const SizedBox(height: 12),
                
                // Divider
                Container(
                  height: 1,
                  width: 30,
                  color: Colors.grey.shade300,
                ),
                
                const SizedBox(height: 12),
                
                // Zoom in button
                _buildMapControlButton(
                  icon: Icons.add,
                  onPressed: () {
                    var currentZoom = mapController.zoom;
                    if (currentZoom < 18) {
                      mapController.move(
                        mapController.center,
                        currentZoom + 1,
                      );
                    }
                  },
                  backgroundColor: Colors.orange.shade50,
                  iconColor: Colors.orange.shade600,
                  tooltip: 'Zoom in',
                ),
                
                const SizedBox(height: 8),
                
                // Zoom out button
                _buildMapControlButton(
                  icon: Icons.remove,
                  onPressed: () {
                    var currentZoom = mapController.zoom;
                    if (currentZoom > 5) {
                      mapController.move(
                        mapController.center,
                        currentZoom - 1,
                      );
                    }
                  },
                  backgroundColor: Colors.red.shade50,
                  iconColor: Colors.red.shade600,
                  tooltip: 'Zoom out',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for map control buttons
  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for legend items
  Widget _buildLegendItem(IconData icon, String label, Color color, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Keep all existing functionality methods unchanged
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
        width: constraints.maxWidth > 300 ? 240 : constraints.maxWidth - 80,
        height: 160,
        builder: (context) => Transform.translate(
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
                    // Device Header
                    Row(
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
                    ),
                    const SizedBox(height: 16),
                    
                    // Device Info Items
                    _buildInfoRow(
                      Icons.access_time_filled,
                      'Last seen',
                      DeviceUtils.formatDateSmart(latestLocation.createdAt),
                      context,
                    ),
                    const SizedBox(height: 8),
                    if (latestLocation.speed != null)
                      _buildInfoRow(
                        Icons.speed,
                        'Speed',
                        DeviceUtils.formatSpeed(latestLocation.speed!),
                        context,
                        valueColor: DeviceUtils.getSpeedColor(latestLocation.speed),
                      ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.timeline,
                      'History',
                      '${locations.length} points',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildInfoRow(IconData icon, String label, String value, BuildContext context,
      {Color? valueColor}) {
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