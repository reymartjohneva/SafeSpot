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
      bottom: 12,
      right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Geofence Controls Section
              _buildCompactButton(
                icon: Icons.layers,
                onPressed: () => _showGeofencesList(context),
                backgroundColor: Colors.indigo.shade50,
                iconColor: Colors.indigo.shade600,
                tooltip: 'Geofences',
              ),
              
              const SizedBox(height: 6),
              
              _buildCompactButton(
                icon: isDrawingGeofence ? Icons.stop : Icons.draw,
                onPressed: isDrawingGeofence ? onStopDrawing : onStartDrawing,
                backgroundColor: isDrawingGeofence
                    ? Colors.orange.shade100
                    : Colors.orange.shade50,
                iconColor: isDrawingGeofence
                    ? Colors.orange.shade700
                    : Colors.orange.shade600,
                tooltip: isDrawingGeofence ? 'Stop' : 'Draw',
              ),
              
              // Clear points button (compact, only when drawing)
              if (isDrawingGeofence && currentGeofencePoints.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildCompactButton(
                  icon: Icons.clear,
                  onPressed: () {
                    onClearPoints();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Points cleared'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  backgroundColor: Colors.red.shade50,
                  iconColor: Colors.red.shade600,
                  tooltip: 'Clear',
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Thin divider
              Container(
                height: 0.5,
                width: 20,
                color: Colors.grey.shade300,
              ),
              
              const SizedBox(height: 8),
              
              // Navigation Controls
              _buildCompactButton(
                icon: Icons.fit_screen_outlined,
                onPressed: onFitMapToBounds,
                backgroundColor: Colors.purple.shade50,
                iconColor: Colors.purple.shade600,
                tooltip: 'Fit',
              ),
              
              const SizedBox(height: 6),
              
              _buildCompactButton(
                icon: Icons.my_location_outlined,
                onPressed: onCenterMapOnCurrentLocation,
                backgroundColor: currentPosition != null 
                    ? Colors.blue.shade50 
                    : Colors.grey.shade100,
                iconColor: currentPosition != null 
                    ? Colors.blue.shade600 
                    : Colors.grey.shade500,
                tooltip: 'Location',
              ),
              
              const SizedBox(height: 6),
              
              _buildCompactButton(
                icon: Icons.home_outlined,
                onPressed: () {
                  mapController.move(LatLng(8.9511, 125.5439), 13.0);
                },
                backgroundColor: Colors.green.shade50,
                iconColor: Colors.green.shade600,
                tooltip: 'Home',
              ),
              
              const SizedBox(height: 8),
              
              // Divider
              Container(
                height: 0.5,
                width: 20,
                color: Colors.grey.shade300,
              ),
              
              const SizedBox(height: 8),
              
              // Zoom Controls
              _buildCompactButton(
                icon: Icons.add,
                onPressed: () => _zoomIn(),
                backgroundColor: Colors.teal.shade50,
                iconColor: Colors.teal.shade600,
                tooltip: 'Zoom+',
              ),
              
              const SizedBox(height: 6),
              
              _buildCompactButton(
                icon: Icons.remove,
                onPressed: () => _zoomOut(),
                backgroundColor: Colors.red.shade50,
                iconColor: Colors.red.shade600,
                tooltip: 'Zoom-',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iconColor.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  void _zoomIn() {
    var currentZoom = mapController.zoom;
    if (currentZoom < 18) {
      mapController.move(mapController.center, currentZoom + 1);
    }
  }

  void _zoomOut() {
    var currentZoom = mapController.zoom;
    if (currentZoom > 5) {
      mapController.move(mapController.center, currentZoom - 1);
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
          maxChildSize: 0.85,
          minChildSize: 0.3,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact handle
                Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Compact header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Geofences',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoadingGeofences)
                          Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(right: 8),
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                        IconButton(
                          onPressed: onLoadGeofences,
                          icon: const Icon(Icons.refresh, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 20),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Compact geofences list
                Expanded(
                  child: geofences.isEmpty
                      ? _buildEmptyGeofenceState(context)
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: geofences.length,
                          itemBuilder: (context, index) {
                            final geofence = geofences[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: geofence.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            geofence.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '${geofence.points.length} pts • ${geofence.isActive ? "Active" : "Inactive"}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: geofence.isActive,
                                      onChanged: (value) async {
                                        await onToggleGeofenceStatus(geofence.id, value);
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: () async {
                                        final confirmed = await _showDeleteConfirmation(
                                          context,
                                          geofence.name,
                                        );
                                        if (confirmed == true) {
                                          await onDeleteGeofence(geofence.id, index);
                                          Navigator.pop(context);
                                        }
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            isLoadingGeofences ? 'Loading...' : 'No geofences yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (!isLoadingGeofences) ...[
            const SizedBox(height: 6),
            Text(
              'Tap draw to create one',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
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
        content: Text('Delete "$geofenceName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}