import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_spot/services/geofence_service.dart';

class MapControlsPanel extends StatelessWidget {
  final MapController mapController;
  final Position? currentPosition;
  final VoidCallback onCenterMapOnCurrentLocation;
  final VoidCallback onFitMapToBounds;
  
  // Geofence-related properties
  final bool isDrawingGeofence;
  final bool isDragging;
  final int? draggedPointIndex;
  final List<LatLng> currentGeofencePoints;
  final List<Geofence> geofences;
  final bool isLoadingGeofences;
  final VoidCallback onStartDrawing;
  final VoidCallback onStopDrawing;
  final VoidCallback onClearPoints;
  final VoidCallback onLoadGeofences;
  final Future<void> Function(String, bool) onToggleGeofenceStatus;
  final Future<void> Function(String, int) onDeleteGeofence;

  const MapControlsPanel({
    Key? key,
    required this.mapController,
    required this.currentPosition,
    required this.onCenterMapOnCurrentLocation,
    required this.onFitMapToBounds,
    required this.isDrawingGeofence,
    required this.isDragging,
    required this.draggedPointIndex,
    required this.currentGeofencePoints,
    required this.geofences,
    required this.isLoadingGeofences,
    required this.onStartDrawing,
    required this.onStopDrawing,
    required this.onClearPoints,
    required this.onLoadGeofences,
    required this.onToggleGeofenceStatus,
    required this.onDeleteGeofence,
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
                // Geofence Controls Section
                _buildMapControlButton(
                  icon: Icons.layers,
                  onPressed: () => _showGeofencesList(context),
                  backgroundColor: Colors.indigo.shade50,
                  iconColor: Colors.indigo.shade600,
                  tooltip: 'Geofences list',
                ),
                
                const SizedBox(height: 8),
                
                _buildMapControlButton(
                  icon: isDrawingGeofence ? Icons.stop : Icons.draw,
                  onPressed: isDrawingGeofence ? onStopDrawing : onStartDrawing,
                  backgroundColor: isDrawingGeofence
                      ? Colors.orange.shade100
                      : Colors.orange.shade50,
                  iconColor: isDrawingGeofence
                      ? Colors.orange.shade700
                      : Colors.orange.shade600,
                  tooltip: isDrawingGeofence ? 'Stop drawing' : 'Draw geofence',
                ),
                
                // Clear geofence points button (only show when drawing and has points)
                if (isDrawingGeofence && currentGeofencePoints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildMapControlButton(
                    icon: Icons.clear,
                    onPressed: () {
                      onClearPoints();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Geofence points cleared'),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    },
                    backgroundColor: Colors.red.shade50,
                    iconColor: Colors.red.shade600,
                    tooltip: 'Clear points',
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Divider
                Container(
                  height: 1,
                  width: 30,
                  color: Colors.grey.shade300,
                ),
                
                const SizedBox(height: 12),
                
                // Map Navigation Controls Section
                _buildMapControlButton(
                  icon: Icons.fit_screen_outlined,
                  onPressed: onFitMapToBounds,
                  backgroundColor: Colors.purple.shade50,
                  iconColor: Colors.purple.shade600,
                  tooltip: 'Fit to bounds',
                ),
                
                const SizedBox(height: 8),
                
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
                
                // Zoom Controls Section
                _buildMapControlButton(
                  icon: Icons.add,
                  onPressed: () => _zoomIn(),
                  backgroundColor: Colors.teal.shade50,
                  iconColor: Colors.teal.shade600,
                  tooltip: 'Zoom in',
                ),
                
                const SizedBox(height: 8),
                
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

  void _showGeofencesList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Geofences',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      children: [
                        if (isLoadingGeofences)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        IconButton(
                          onPressed: onLoadGeofences,
                          icon: const Icon(Icons.refresh),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Geofences list
                Expanded(
                  child: geofences.isEmpty
                      ? _buildEmptyGeofenceState(context)
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: geofences.length,
                          itemBuilder: (context, index) {
                            final geofence = geofences[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: geofence.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(geofence.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${geofence.points.length} points • ${geofence.isActive ? "Active" : "Inactive"}',
                                    ),
                                    Text(
                                      'Created: ${geofence.createdAt.day}/${geofence.createdAt.month}/${geofence.createdAt.year}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: geofence.isActive,
                                      onChanged: (value) async {
                                        await onToggleGeofenceStatus(
                                          geofence.id,
                                          value,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final confirmed = await _showDeleteConfirmation(
                                          context,
                                          geofence.name,
                                        );
                                        if (confirmed == true) {
                                          await onDeleteGeofence(
                                            geofence.id,
                                            index,
                                          );
                                          Navigator.pop(context);
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyGeofenceState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.layers_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isLoadingGeofences
                ? 'Loading geofences...'
                : 'No geofences created yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          if (!isLoadingGeofences) ...[
            const SizedBox(height: 8),
            Text(
              'Tap the draw button to create your first geofence',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String geofenceName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Geofence'),
        content: Text('Are you sure you want to delete "$geofenceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}