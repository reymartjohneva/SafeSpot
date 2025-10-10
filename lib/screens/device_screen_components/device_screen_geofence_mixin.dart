import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:safe_spot/services/geofence_service.dart';
import 'device_screen_state.dart';

mixin DeviceScreenGeofenceMixin<T extends StatefulWidget> on State<T> {
  DeviceScreenStateData get state;

  Future<void> loadGeofences() async {
    if (!GeofenceService.isAuthenticated) {
      print('User not authenticated, skipping geofence loading');
      return;
    }

    setState(() {
      state.isLoadingGeofences = true;
    });

    try {
      final geofenceData = await GeofenceService.getUserGeofences();
      final geofences =
          geofenceData.map((data) => Geofence.fromSupabase(data)).toList();

      if (mounted) {
        setState(() {
          state.geofences = geofences;
          state.isLoadingGeofences = false;
        });
      }
    } catch (e) {
      print('Error loading geofences: $e');
      if (mounted) {
        setState(() {
          state.isLoadingGeofences = false;
        });
        _showErrorSnackBar('Failed to load geofences: ${e.toString()}');
      }
    }
  }

  void startDrawingGeofence() {
    setState(() {
      state.isDrawingGeofence = true;
      state.currentGeofencePoints.clear();
      state.isDragging = false;
      state.draggedPointIndex = null;
    });

    // Show welcome message with instructions
    _showInfoSnackBar(
      'Tap on the map to add points to your geofence',
      duration: const Duration(seconds: 3),
      icon: Icons.touch_app,
    );
  }

  void stopDrawingGeofence() {
    if (state.currentGeofencePoints.length >= 3) {
      _showCreateGeofenceDialog();
    } else {
      setState(() {
        state.isDrawingGeofence = false;
        state.currentGeofencePoints.clear();
        state.isDragging = false;
        state.draggedPointIndex = null;
      });
      _showWarningSnackBar(
        'Geofence needs at least 3 points',
        icon: Icons.warning_amber_rounded,
      );
    }
  }

  void _showCreateGeofenceDialog() {
    state.geofenceNameController.clear();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: DeviceScreenColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DeviceScreenColors.primaryOrange,
                      DeviceScreenColors.primaryOrange.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_location_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Geofence',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Name your safe zone',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name input with improved styling
                    Container(
                      decoration: BoxDecoration(
                        color: DeviceScreenColors.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DeviceScreenColors.primaryOrange.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: state.geofenceNameController,
                        autofocus: true,
                        style: const TextStyle(
                          color: DeviceScreenColors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Geofence Name',
                          labelStyle: TextStyle(
                            color: DeviceScreenColors.textSecondary,
                            fontSize: 14,
                          ),
                          hintText: 'e.g., Home, Office, School',
                          hintStyle: TextStyle(
                            color: DeviceScreenColors.textSecondary.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.edit_location_alt,
                            color: DeviceScreenColors.primaryOrange,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Info cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.location_on,
                            label: 'Points',
                            value: '${state.currentGeofencePoints.length}',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.area_chart,
                            label: 'Area',
                            value: _calculateArea(),
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tips section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You can adjust points by long-pressing on the map',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade200,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DeviceScreenColors.surfaceColor.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            state.isDrawingGeofence = false;
                            state.currentGeofencePoints.clear();
                            state.isDragging = false;
                            state.draggedPointIndex = null;
                          });
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: DeviceScreenColors.textSecondary.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: DeviceScreenColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.isSavingGeofence
                            ? null
                            : () async {
                                final name = state.geofenceNameController.text.trim();
                                final validationError = GeofenceUtils.validateGeofence(
                                  name,
                                  state.currentGeofencePoints,
                                );

                                if (validationError != null) {
                                  _showErrorSnackBar(validationError);
                                  return;
                                }

                                await createGeofence(name);
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: DeviceScreenColors.primaryOrange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: DeviceScreenColors.primaryOrange.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: state.isSavingGeofence
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Create',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: DeviceScreenColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: DeviceScreenColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateArea() {
    if (state.currentGeofencePoints.length < 3) return 'N/A';
    // Simple approximation - you can improve this with proper area calculation
    return '~${(state.currentGeofencePoints.length * 100).toStringAsFixed(0)}m²';
  }

  Future<void> createGeofence(String name) async {
    if (!GeofenceService.isAuthenticated) {
      _showErrorSnackBar('Please log in to create geofences');
      return;
    }

    setState(() {
      state.isSavingGeofence = true;
    });

    try {
      final points = state.currentGeofencePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList();

      final color = GeofenceUtils.getRandomColor(state.geofences.length);
      final colorHex = '#${color.value.toRadixString(16).substring(2)}';

      final geofenceData = await GeofenceService.createGeofence(
        name: name,
        points: points,
        color: colorHex,
      );

      final geofence = Geofence.fromSupabase(geofenceData);

      setState(() {
        state.geofences.add(geofence);
        state.isDrawingGeofence = false;
        state.currentGeofencePoints.clear();
        state.isDragging = false;
        state.draggedPointIndex = null;
        state.isSavingGeofence = false;
      });

      _showSuccessSnackBar(
        'Geofence "$name" created successfully!',
        icon: Icons.check_circle,
      );
    } catch (e) {
      setState(() {
        state.isSavingGeofence = false;
      });

      _showErrorSnackBar('Failed to create geofence: ${e.toString()}');
    }
  }

  void onMapTap(TapPosition tapPosition, LatLng point) {
    if (state.isDrawingGeofence) {
      if (state.isDragging && state.draggedPointIndex != null) {
        setState(() {
          state.currentGeofencePoints[state.draggedPointIndex!] = point;
          state.isDragging = false;
        });

        _showSuccessSnackBar(
          'Point ${state.draggedPointIndex! + 1} moved successfully',
          icon: Icons.check_circle_outline,
          duration: const Duration(seconds: 2),
        );

        state.draggedPointIndex = null;
        state.draggedPointOriginalPosition = null;
      } else {
        setState(() {
          state.currentGeofencePoints.add(point);
        });

        final pointNumber = state.currentGeofencePoints.length;
        final message = pointNumber < 3
            ? 'Point $pointNumber added. Need ${3 - pointNumber} more.'
            : 'Point $pointNumber added. Tap "Stop" when ready.';

        _showSuccessSnackBar(
          message,
          icon: Icons.add_location_alt,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void onMapLongPress(TapPosition tapPosition, LatLng point) {
    if (state.isDrawingGeofence && state.currentGeofencePoints.isNotEmpty) {
      int closestPointIndex = GeofenceUtils.findClosestPointIndex(
        point,
        state.currentGeofencePoints,
      );
      
      if (closestPointIndex != -1) {
        setState(() {
          state.isDragging = true;
          state.draggedPointIndex = closestPointIndex;
          state.draggedPointOriginalPosition =
              state.currentGeofencePoints[closestPointIndex];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap anywhere to move point ${closestPointIndex + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Cancel',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  state.isDragging = false;
                  state.draggedPointIndex = null;
                  if (state.draggedPointOriginalPosition != null) {
                    state.currentGeofencePoints[closestPointIndex] =
                        state.draggedPointOriginalPosition!;
                  }
                });
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> toggleGeofenceStatus(String geofenceId, bool isActive) async {
    try {
      await GeofenceService.toggleGeofenceStatus(geofenceId, isActive);

      setState(() {
        final index = state.geofences.indexWhere((g) => g.id == geofenceId);
        if (index != -1) {
          state.geofences[index].isActive = isActive;
        }
      });

      _showSuccessSnackBar(
        'Geofence ${isActive ? "activated" : "deactivated"}',
        icon: isActive ? Icons.check_circle : Icons.pause_circle_outline,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update geofence: ${e.toString()}');
    }
  }

  Future<void> deleteGeofence(String geofenceId, int index) async {
    try {
      await GeofenceService.deleteGeofence(geofenceId);

      setState(() {
        state.geofences.removeAt(index);
      });

      _showSuccessSnackBar(
        'Geofence deleted successfully',
        icon: Icons.delete_outline,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to delete geofence: ${e.toString()}');
    }
  }

  // Enhanced SnackBar helpers
  void _showSuccessSnackBar(
    String message, {
    IconData icon = Icons.check_circle,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        duration: duration,
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showWarningSnackBar(
    String message, {
    IconData icon = Icons.warning_amber_rounded,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoSnackBar(
    String message, {
    IconData icon = Icons.info_outline,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        duration: duration,
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}