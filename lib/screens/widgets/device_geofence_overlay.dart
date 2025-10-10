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
  final VoidCallback? onCancelDrag;

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
    this.onCancelDrag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Drawing instructions with modern design
        if (isDrawingGeofence) _buildDrawingInstructions(context),
      ],
    );
  }

  Widget _buildDrawingInstructions(BuildContext context) {
    final canFinish = currentGeofencePoints.length >= 3;
    
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDragging
                ? [Colors.orange.shade100, Colors.orange.shade50]
                : [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDragging
                ? Colors.orange.shade300
                : Colors.blue.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Main instruction area
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Animated icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDragging
                            ? Colors.orange.shade200
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDragging ? Icons.touch_app : Icons.draw,
                        color: isDragging
                            ? Colors.orange.shade900
                            : Colors.blue.shade900,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Instructions text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDragging
                                ? 'Moving Point ${draggedPointIndex! + 1}'
                                : 'Drawing Geofence',
                            style: TextStyle(
                              color: isDragging
                                  ? Colors.orange.shade900
                                  : Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDragging
                                ? 'Tap anywhere to place point'
                                : 'Tap to add • Long press to move',
                            style: TextStyle(
                              color: isDragging
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Action buttons
                    if (isDragging)
                      _buildCancelButton(context)
                    else
                      _buildFinishButton(context, canFinish),
                  ],
                ),
              ),
              
              // Progress indicator
              if (!isDragging && currentGeofencePoints.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: canFinish
                        ? Colors.green.shade50
                        : Colors.amber.shade50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Points indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: canFinish
                              ? Colors.green.shade100
                              : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: canFinish
                                ? Colors.green.shade300
                                : Colors.amber.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: canFinish
                                  ? Colors.green.shade700
                                  : Colors.amber.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${currentGeofencePoints.length} points',
                              style: TextStyle(
                                color: canFinish
                                    ? Colors.green.shade900
                                    : Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Status message
                      Expanded(
                        child: Text(
                          canFinish
                              ? '✓ Ready to create!'
                              : 'Need ${3 - currentGeofencePoints.length} more',
                          style: TextStyle(
                            color: canFinish
                                ? Colors.green.shade700
                                : Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      
                      // Clear button
                      IconButton(
                        onPressed: () {
                          onClearPoints();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.clear_all, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text('Points cleared'),
                                ],
                              ),
                              backgroundColor: Colors.grey.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.clear_all,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        tooltip: 'Clear all points',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        if (onCancelDrag != null) {
          onCancelDrag!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.undo, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Move cancelled'),
              ],
            ),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.close, size: 18),
      label: const Text(
        'Cancel',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.orange.shade900,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildFinishButton(BuildContext context, bool canFinish) {
    return ElevatedButton.icon(
      onPressed: canFinish ? onStopDrawing : null,
      icon: Icon(
        canFinish ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 18,
      ),
      label: const Text(
        'Finish',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: canFinish ? Colors.green.shade600 : Colors.grey.shade400,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: canFinish ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showGeofencesList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) => Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.blue.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.layers,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geofences',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${geofences.length} ${geofences.length == 1 ? 'zone' : 'zones'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoadingGeofences)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade400,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: onLoadGeofences,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Geofences list
              Expanded(
                child: geofences.isEmpty
                    ? _buildEmptyGeofenceState(context)
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: geofences.length,
                        itemBuilder: (context, index) {
                          final geofence = geofences[index];
                          return _buildGeofenceCard(context, geofence, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeofenceCard(BuildContext context, Geofence geofence, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: geofence.color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: geofence.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Color indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: geofence.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: geofence.color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: geofence.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        geofence.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.radio_button_checked,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${geofence.points.length} points',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: geofence.isActive
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: geofence.isActive
                                    ? Colors.green.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              geofence.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: geofence.isActive
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created ${_formatDate(geofence.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Toggle switch
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        geofence.isActive
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
                  activeColor: Colors.green.shade600,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                
                // Delete button
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
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade400,
                  tooltip: 'Delete',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyGeofenceState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.layers_outlined,
                size: 64,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isLoadingGeofences
                  ? 'Loading geofences...'
                  : 'No geofences yet',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (!isLoadingGeofences)
              Text(
                'Create your first safe zone by\ntapping the draw button',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            if (isLoadingGeofences)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String geofenceName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Geofence',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$geofenceName"? This action cannot be undone.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}