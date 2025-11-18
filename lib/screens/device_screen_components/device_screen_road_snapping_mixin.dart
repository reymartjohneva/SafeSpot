/// Road Snapping Mixin for DeviceScreen
/// Handles snapping location history to roads
library;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'device_screen_state.dart';
import '../../services/road_snapping_service.dart';
import '../../services/device_service.dart';

mixin DeviceScreenRoadSnappingMixin<T extends StatefulWidget> on State<T> {
  final RoadSnappingService _roadService = RoadSnappingService();
  final SnappedPathCache _cache = SnappedPathCache();

  // Must be implemented by the class using this mixin
  DeviceScreenStateData get state;

  /// Snap location history to roads for selected device
  Future<void> snapDevicePathToRoad(String deviceId) async {
    if (!state.deviceLocations.containsKey(deviceId)) {
      print('⚠️ No location history for device $deviceId');
      return;
    }

    final locations = state.deviceLocations[deviceId]!;
    if (locations.length < 2) {
      print('⚠️ Need at least 2 location points to create path');
      return;
    }

    setState(() {
      state.isSnappingToRoads = true;
    });

    try {
      // Sort locations by timestamp to ensure correct chronological order
      final sortedLocations = List<LocationHistory>.from(locations)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Convert LocationHistory to LatLng in chronological order
      final points =
          sortedLocations.map((loc) {
            return LatLng(loc.latitude, loc.longitude);
          }).toList();

      print('📍 Processing ${points.length} points in chronological order');
      print('   First: ${sortedLocations.first.timestamp}');
      print('   Last: ${sortedLocations.last.timestamp}');

      // Check cache first
      final cacheKey = SnappedPathCache.generateKey(points, 'walking');
      var snappedPath = _cache.get(cacheKey);

      if (snappedPath == null) {
        print('🗺️ Snapping device $deviceId path to roads...');

        // Snap to roads
        snappedPath = await _roadService.snapToRoad(
          points: points,
          profile: 'walking', // Can be 'walking', 'driving', or 'cycling'
        );

        // Cache the result
        _cache.set(cacheKey, snappedPath);
      } else {
        print('📦 Using cached snapped path for device $deviceId');
      }

      setState(() {
        state.snappedPaths[deviceId] = snappedPath!;
        state.isSnappingToRoads = false;
      });

      print('✅ Path snapped successfully: ${snappedPath.length} points');
    } catch (e) {
      print('❌ Failed to snap path: $e');
      setState(() {
        state.isSnappingToRoads = false;
      });

      // Fallback: use raw points (sorted by timestamp)
      final sortedLocations = List<LocationHistory>.from(locations)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final rawPoints =
          sortedLocations.map((loc) {
            return LatLng(loc.latitude, loc.longitude);
          }).toList();

      setState(() {
        state.snappedPaths[deviceId] = rawPoints;
      });
    }
  }

  /// Snap paths for all devices with location history
  Future<void> snapAllDevicePaths() async {
    for (final deviceId in state.deviceLocations.keys) {
      if (state.deviceLocations[deviceId]!.length >= 2) {
        await snapDevicePathToRoad(deviceId);
      }
    }
  }

  /// Toggle road-snapped path visibility
  void toggleSnappedPathVisibility() {
    setState(() {
      state.showSnappedPaths = !state.showSnappedPaths;
    });
  }

  /// Clear snapped paths
  void clearSnappedPaths() {
    setState(() {
      state.snappedPaths.clear();
    });
    _cache.clear();
  }

  /// Clear snapped path for specific device
  void clearDeviceSnappedPath(String deviceId) {
    setState(() {
      state.snappedPaths.remove(deviceId);
    });
  }

  /// Dispose road snapping resources
  void disposeRoadSnapping() {
    _cache.clear();
  }
}
