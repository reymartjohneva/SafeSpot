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
            // Main Map with Layers
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

            // Right Side Map Controls Panel
            MapControlsPanel(
              mapController: mapController,
              currentPosition: currentPosition,
              onCenterMapOnCurrentLocation: onCenterMapOnCurrentLocation,
              onFitMapToBounds: () => _fitMapToBounds(),
            ),
          ],
        );
      },
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