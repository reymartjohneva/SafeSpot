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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load geofences: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
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
  }

  void stopDrawingGeofence() {
    if (state.currentGeofencePoints.length >= 3) {
      showCreateGeofenceDialog();
    } else {
      setState(() {
        state.isDrawingGeofence = false;
        state.currentGeofencePoints.clear();
        state.isDragging = false;
        state.draggedPointIndex = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geofence needs at least 3 points'),
          backgroundColor: DeviceScreenColors.primaryOrange,
        ),
      );
    }
  }

  void showCreateGeofenceDialog() {
    state.geofenceNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DeviceScreenColors.cardBackground,
        title: const Text(
          'Create Geofence',
          style: TextStyle(color: DeviceScreenColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: state.geofenceNameController,
              style: const TextStyle(color: DeviceScreenColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Geofence Name',
                labelStyle: TextStyle(color: DeviceScreenColors.textSecondary),
                hintText: 'Enter a name for this geofence',
                hintStyle: TextStyle(color: DeviceScreenColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: DeviceScreenColors.textSecondary),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: DeviceScreenColors.primaryOrange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Points: ${state.currentGeofencePoints.length}',
              style: const TextStyle(color: DeviceScreenColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: You can drag points to adjust the geofence shape',
              style: TextStyle(fontSize: 12, color: DeviceScreenColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                state.isDrawingGeofence = false;
                state.currentGeofencePoints.clear();
                state.isDragging = false;
                state.draggedPointIndex = null;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: DeviceScreenColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: state.isSavingGeofence
                ? null
                : () async {
                    final name = state.geofenceNameController.text.trim();
                    final validationError = GeofenceUtils.validateGeofence(
                      name,
                      state.currentGeofencePoints,
                    );

                    if (validationError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(validationError),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                      return;
                    }

                    await createGeofence(name);
                    Navigator.pop(context);
                  },
            child: state.isSavingGeofence
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(DeviceScreenColors.primaryOrange),
                    ),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(color: DeviceScreenColors.primaryOrange),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> createGeofence(String name) async {
    if (!GeofenceService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to create geofences'),
          backgroundColor: Colors.red.shade700,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geofence "$name" created successfully'),
          backgroundColor: DeviceScreenColors.primaryOrange,
        ),
      );
    } catch (e) {
      setState(() {
        state.isSavingGeofence = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create geofence: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void onMapTap(TapPosition tapPosition, LatLng point) {
    if (state.isDrawingGeofence) {
      if (state.isDragging && state.draggedPointIndex != null) {
        setState(() {
          state.currentGeofencePoints[state.draggedPointIndex!] = point;
          state.isDragging = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Point ${state.draggedPointIndex! + 1} moved to new position',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: DeviceScreenColors.primaryOrange,
          ),
        );

        state.draggedPointIndex = null;
        state.draggedPointOriginalPosition = null;
      } else {
        setState(() {
          state.currentGeofencePoints.add(point);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Point ${state.currentGeofencePoints.length} added. Long press on any point to move it.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade700,
          ),
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
            content: Text(
              'Tap on map to move point ${closestPointIndex + 1} to new position.',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange.shade700,
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update geofence: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> deleteGeofence(String geofenceId, int index) async {
    try {
      await GeofenceService.deleteGeofence(geofenceId);

      setState(() {
        state.geofences.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geofence deleted successfully'),
          backgroundColor: DeviceScreenColors.primaryOrange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete geofence: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}