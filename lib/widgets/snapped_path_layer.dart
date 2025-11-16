/// Road-Snapped Path Layer for flutter_map
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Renders a road-snapped path on the map
class SnappedPathLayer extends StatelessWidget {
  final List<LatLng> path;
  final Color color;
  final double width;
  final bool showDirectionArrows;

  const SnappedPathLayer({
    Key? key,
    required this.path,
    this.color = const Color(0xFF7E57C2),
    this.width = 4.0,
    this.showDirectionArrows = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (path.length < 2) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Main path line
        PolylineLayer(
          polylines: [
            Polyline(
              points: path,
              color: color,
              strokeWidth: width,
              borderStrokeWidth: 2,
              borderColor: Colors.white.withOpacity(0.8),
            ),
          ],
        ),

        // Direction arrows (optional)
        if (showDirectionArrows && path.length >= 10)
          MarkerLayer(markers: _buildDirectionArrows()),
      ],
    );
  }

  /// Build directional arrow markers along the path
  List<Marker> _buildDirectionArrows() {
    final markers = <Marker>[];

    // Place arrows every ~10 points
    for (var i = 10; i < path.length - 10; i += 10) {
      final current = path[i];
      final next = path[i + 5]; // Look ahead a bit for smoother direction

      final bearing = _calculateBearing(current, next);

      markers.add(
        Marker(
          point: current,
          width: 20,
          height: 20,
          builder:
              (context) => Transform.rotate(
                angle: bearing * (3.14159 / 180), // Convert to radians
                child: Icon(
                  Icons.arrow_upward,
                  size: 16,
                  color: color.withOpacity(0.7),
                ),
              ),
        ),
      );
    }

    return markers;
  }

  /// Calculate bearing between two points (in degrees)
  double _calculateBearing(LatLng from, LatLng to) {
    final dLon = _degreesToRadians(to.longitude - from.longitude);
    final lat1 = _degreesToRadians(from.latitude);
    final lat2 = _degreesToRadians(to.latitude);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x);
    return (_radiansToDegrees(bearing) + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * (3.14159 / 180);
  double _radiansToDegrees(double radians) => radians * (180 / 3.14159);
}

/// Multi-path layer for rendering multiple device paths
class MultiPathLayer extends StatelessWidget {
  final Map<String, List<LatLng>> devicePaths;
  final Map<String, Color> deviceColors;
  final String? selectedDeviceId;
  final double pathWidth;
  final bool showDirectionArrows;

  const MultiPathLayer({
    Key? key,
    required this.devicePaths,
    required this.deviceColors,
    this.selectedDeviceId,
    this.pathWidth = 4.0,
    this.showDirectionArrows = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final layers = <Widget>[];

    // Render non-selected paths first (dimmed)
    for (final entry in devicePaths.entries) {
      final deviceId = entry.key;
      final path = entry.value;

      if (path.length < 2) continue;

      final isSelected =
          selectedDeviceId == null || selectedDeviceId == deviceId;
      final color = deviceColors[deviceId] ?? Colors.purple;

      if (!isSelected) {
        layers.add(
          SnappedPathLayer(
            path: path,
            color: color.withOpacity(0.3),
            width: pathWidth * 0.7,
            showDirectionArrows: false,
          ),
        );
      }
    }

    // Render selected path on top (bright)
    if (selectedDeviceId != null && devicePaths.containsKey(selectedDeviceId)) {
      final path = devicePaths[selectedDeviceId]!;
      final color = deviceColors[selectedDeviceId] ?? Colors.purple;

      if (path.length >= 2) {
        layers.add(
          SnappedPathLayer(
            path: path,
            color: color,
            width: pathWidth,
            showDirectionArrows: showDirectionArrows,
          ),
        );
      }
    }

    return Stack(children: layers);
  }
}
