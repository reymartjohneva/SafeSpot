import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/services/geofence_service.dart';
import 'widgets/map_controls_panel.dart';
import 'widgets/device_info_popup.dart';
import 'widgets/map_legend_panel.dart';
import 'widgets/device_selector_panel.dart';
import 'widgets/map_layers.dart';

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
  final bool isLoadingGeofences;
  final Function(String?) onDeviceSelected;
  final Function(String) onCenterMapOnDevice;
  final VoidCallback onCenterMapOnCurrentLocation;
  final Function(TapPosition, LatLng) onMapTap;
  final Function(TapPosition, LatLng) onMapLongPress;
  final Device? Function(String) findDeviceById;

  // Added geofence control callbacks
  final VoidCallback onStartDrawing;
  final VoidCallback onStopDrawing;
  final VoidCallback onClearPoints;
  final VoidCallback onLoadGeofences;
  final Future<void> Function(String, bool) onToggleGeofenceStatus;
  final Future<void> Function(String, int) onDeleteGeofence;

  // NEW: History points visibility
  final bool showHistoryPoints;
  final VoidCallback onToggleHistoryPoints;

  // Road-snapped paths
  final Map<String, List<LatLng>> snappedPaths;
  final bool showSnappedPaths;

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
    this.isLoadingGeofences = false,
    required this.onDeviceSelected,
    required this.onCenterMapOnDevice,
    required this.onCenterMapOnCurrentLocation,
    required this.onMapTap,
    required this.onMapLongPress,
    required this.findDeviceById,
    required this.onStartDrawing,
    required this.onStopDrawing,
    required this.onClearPoints,
    required this.onLoadGeofences,
    required this.onToggleGeofenceStatus,
    required this.onDeleteGeofence,
    required this.showHistoryPoints,
    required this.onToggleHistoryPoints,
    this.snappedPaths = const {},
    this.showSnappedPaths = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Drawing instructions overlay
            if (isDrawingGeofence) _buildDrawingInstructions(context),

            // Main Map with Layers
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center:
                    currentPosition != null
                        ? LatLng(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                        )
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

                // All map layers in a separate widget
                MapLayers(
                  geofences: geofences,
                  currentGeofencePoints: currentGeofencePoints,
                  isDragging: isDragging,
                  draggedPointIndex: draggedPointIndex,
                  currentPosition: currentPosition,
                  devices: devices,
                  deviceLocations: deviceLocations,
                  selectedDeviceId: selectedDeviceId,
                  findDeviceById: findDeviceById,
                  onDeviceSelected: onDeviceSelected,
                  showHistoryPoints: showHistoryPoints,
                  snappedPaths: snappedPaths,
                  showSnappedPaths: showSnappedPaths,
                ),

                // Device info popup
                if (selectedDeviceId != null &&
                    deviceLocations[selectedDeviceId]?.isNotEmpty == true)
                  DeviceInfoPopup(
                    device: findDeviceById(selectedDeviceId!)!,
                    latestLocation: deviceLocations[selectedDeviceId]!.first,
                    locationCount: deviceLocations[selectedDeviceId]!.length,
                    constraints: constraints,
                  ),
              ],
            ),

            // Top Device Selector Panel
            DeviceSelectorPanel(
              devices: devices,
              deviceLocations: deviceLocations,
              selectedDeviceId: selectedDeviceId,
              onDeviceSelected: onDeviceSelected,
              onCenterMapOnDevice: onCenterMapOnDevice,
            ),

            // Bottom Map Legend Panel
            MapLegendPanel(
              currentPosition: currentPosition,
              geofences: geofences,
              constraints: constraints,
            ),

            // Combined Map Controls Panel (includes geofence controls)
            MapControlsPanel(
              mapController: mapController,
              currentPosition: currentPosition,
              onCenterMapOnCurrentLocation: onCenterMapOnCurrentLocation,
              onFitMapToBounds: () => _fitMapToBounds(),
              isDrawingGeofence: isDrawingGeofence,
              isDragging: isDragging,
              draggedPointIndex: draggedPointIndex,
              currentGeofencePoints: currentGeofencePoints,
              geofences: geofences,
              isLoadingGeofences: isLoadingGeofences,
              onStartDrawing: onStartDrawing,
              onStopDrawing: onStopDrawing,
              onClearPoints: onClearPoints,
              onLoadGeofences: onLoadGeofences,
              onToggleGeofenceStatus: onToggleGeofenceStatus,
              onDeleteGeofence: onDeleteGeofence,
              showHistoryPoints: showHistoryPoints, // PASS IT HERE
              onToggleHistoryPoints: onToggleHistoryPoints, // PASS IT HERE
              selectedDeviceId: selectedDeviceId, // PASS SELECTED DEVICE
              selectedDeviceName:
                  selectedDeviceId != null
                      ? findDeviceById(selectedDeviceId!)?.deviceName
                      : null, // PASS DEVICE NAME
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawingInstructions(BuildContext context) {
    return Positioned(
      top: 70,
      left: 12,
      right: 60,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isDragging
                  ? Colors.orange.shade100.withOpacity(0.95)
                  : Colors.orange.shade50.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.orange.shade300.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isDragging ? Icons.touch_app : Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDragging
                        ? 'Moving point ${draggedPointIndex! + 1}. Tap to place it.'
                        : 'Tap to add • Long press to move points',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (currentGeofencePoints.isNotEmpty && !isDragging)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${currentGeofencePoints.length} points • ${currentGeofencePoints.length >= 3 ? "Ready!" : "Need ${3 - currentGeofencePoints.length} more"}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _fitMapToBounds() {
    final allPoints = <LatLng>[];

    if (currentPosition != null) {
      allPoints.add(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
      );
    }

    for (var device in devices) {
      final locations = deviceLocations[device.deviceId];
      if (locations != null && locations.isNotEmpty) {
        allPoints.add(
          LatLng(locations.first.latitude, locations.first.longitude),
        );
      }
    }

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

      const padding = 0.01;
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;

      mapController.fitBounds(
        LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
      );
    }
  }
}
