import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapControlsPanel extends StatelessWidget {
  final MapController mapController;
  final Position? currentPosition;
  final VoidCallback onCenterMapOnCurrentLocation;
  final VoidCallback onFitMapToBounds;

  const MapControlsPanel({
    Key? key,
    required this.mapController,
    required this.currentPosition,
    required this.onCenterMapOnCurrentLocation,
    required this.onFitMapToBounds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  onPressed: onFitMapToBounds,
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
                  onPressed: () => _zoomIn(),
                  backgroundColor: Colors.orange.shade50,
                  iconColor: Colors.orange.shade600,
                  tooltip: 'Zoom in',
                ),
                
                const SizedBox(height: 8),
                
                // Zoom out button
                _buildMapControlButton(
                  icon: Icons.remove,
                  onPressed: () => _zoomOut(),
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

  void _zoomIn() {
    var currentZoom = mapController.zoom;
    if (currentZoom < 18) {
      mapController.move(
        mapController.center,
        currentZoom + 1,
      );
    }
  }

  void _zoomOut() {
    var currentZoom = mapController.zoom;
    if (currentZoom > 5) {
      mapController.move(
        mapController.center,
        currentZoom - 1,
      );
    }
  }
}