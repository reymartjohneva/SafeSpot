import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/services/geofence_service.dart';
import 'package:safe_spot/utils/device_utils.dart';

class MapLayers extends StatelessWidget {
  final List<Geofence> geofences;
  final List<LatLng> currentGeofencePoints;
  final bool isDragging;
  final int? draggedPointIndex;
  final Position? currentPosition;
  final List<Device> devices;
  final Map<String, List<LocationHistory>> deviceLocations;
  final String? selectedDeviceId;
  final Device? Function(String) findDeviceById;
  final Function(String?) onDeviceSelected;
  final bool showHistoryPoints;

  const MapLayers({
    Key? key,
    required this.geofences,
    required this.currentGeofencePoints,
    required this.isDragging,
    this.draggedPointIndex,
    required this.currentPosition,
    required this.devices,
    required this.deviceLocations,
    required this.selectedDeviceId,
    required this.findDeviceById,
    required this.onDeviceSelected,
    required this.showHistoryPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Geofences Polygons Layer
        PolygonLayer(
          polygons: _buildGeofencePolygons(),
        ),

        // Current geofence drawing markers
        if (currentGeofencePoints.isNotEmpty)
          MarkerLayer(
            markers: _buildGeofenceDrawingMarkers(),
          ),

        // Connection lines between geofence points
        if (currentGeofencePoints.length >= 2)
          PolylineLayer(
            polylines: _buildGeofencePolylines(),
          ),

        // Device location history lines
        PolylineLayer(
          polylines: _buildDevicePolylines(),
        ),

        // Historical device markers - ONLY SHOW IF showHistoryPoints IS TRUE
        if (showHistoryPoints)
          MarkerLayer(
            markers: _buildHistoricalDeviceMarkers(),
          ),

        // Current user location accuracy circle
        if (currentPosition != null)
          CircleLayer(
            circles: _buildUserLocationCircle(),
          ),

        // Current user location marker
        if (currentPosition != null)
          MarkerLayer(
            markers: _buildUserLocationMarkers(),
          ),

        // Latest device location markers
        MarkerLayer(
          markers: _buildLatestDeviceLocationMarkers(),
        ),
      ],
    );
  }

  List<Polygon> _buildGeofencePolygons() {
    return [
      // CHANGED: All existing geofences now display in GREEN
      ...geofences.map(
        (geofence) => Polygon(
          points: geofence.points,
          color: Colors.green.withOpacity(0.2), // Always green
          borderColor: Colors.green.shade600,    // Always green
          borderStrokeWidth: 2.0,
        ),
      ),
      // Current drawing geofence - also green
      if (currentGeofencePoints.length >= 3)
        Polygon(
          points: currentGeofencePoints,
          color: Colors.green.withOpacity(0.2),
          borderColor: isDragging
              ? Colors.green.shade700
              : Colors.green.shade600,
          borderStrokeWidth: isDragging ? 3.0 : 2.0,
        ),
    ];
  }

  List<Marker> _buildGeofenceDrawingMarkers() {
    return currentGeofencePoints
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
                    ? Colors.green.shade700
                    : Colors.green.shade600,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: draggedPointIndex == entry.key ? 3 : 2,
                ),
                boxShadow: [
                  if (draggedPointIndex == entry.key)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
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
        .toList();
  }

  List<Polyline> _buildGeofencePolylines() {
    return [
      Polyline(
        points: currentGeofencePoints,
        strokeWidth: isDragging ? 3.0 : 2.0,
        color: (isDragging
                ? Colors.green.shade700
                : Colors.green.shade600)
            .withOpacity(0.8),
      ),
    ];
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

  List<CircleMarker> _buildUserLocationCircle() {
    return [
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
    ];
  }

  List<Marker> _buildUserLocationMarkers() {
    return [
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
    ];
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
}