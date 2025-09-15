import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geofence_service.dart';

class DeviceGeofenceOverlay extends StatelessWidget {
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

  const DeviceGeofenceOverlay({
    Key? key,
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
    return Stack(
      children: [
        // Drawing instructions
        if (isDrawingGeofence) _buildDrawingInstructions(context),
        
        // Map controls
        _buildMapControls(context),
      ],
    );
  }

  Widget _buildDrawingInstructions(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDragging ? Colors.orange.shade200 : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.shade300,
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
          children: [
            Row(
              children: [
                Icon(
                  isDragging ? Icons.touch_app : Icons.info,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDragging
                        ? 'Moving point ${draggedPointIndex! + 1}. Tap anywhere on map to place it.'
                        : 'Tap to add points • Long press near a point to move it',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isDragging)
                  TextButton(
                    onPressed: () {
                      // This would need to be handled by the parent widget
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Drag cancelled'),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    },
                    child: const Text('Cancel'),
                  )
                else
                  TextButton(
                    onPressed: onStopDrawing,
                    child: const Text('Finish'),
                  ),
              ],
            ),
            if (currentGeofencePoints.isNotEmpty && !isDragging)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${currentGeofencePoints.length} points added • ${currentGeofencePoints.length >= 3 ? "Ready to create!" : "Need ${3 - currentGeofencePoints.length} more point(s)"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(BuildContext context) {
    return Positioned(
      top: isDrawingGeofence ? 120 : 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: "geofence_list",
            onPressed: () => _showGeofencesList(context),
            backgroundColor: Colors.white,
            child: Icon(
              Icons.layers,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "draw_geofence",
            onPressed: isDrawingGeofence ? onStopDrawing : onStartDrawing,
            backgroundColor: isDrawingGeofence
                ? Colors.orange.shade100
                : Colors.white,
            child: Icon(
              isDrawingGeofence ? Icons.stop : Icons.draw,
              color: isDrawingGeofence
                  ? Colors.orange
                  : Colors.grey.shade700,
            ),
          ),
          if (isDrawingGeofence && currentGeofencePoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: "clear_geofence",
              onPressed: () {
                onClearPoints();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Geofence points cleared'),
                    backgroundColor: Colors.grey,
                  ),
                );
              },
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.clear, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  void _showGeofencesList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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