// geofence_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class GeofenceService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get current user ID from your existing auth service
  // You'll need to replace this with your actual auth service method
  static String? get currentUserId {
    // Replace with your auth service's current user ID getter
    return _client.auth.currentUser?.id;
  }

  // Check if user is authenticated
  static bool get isAuthenticated => currentUserId != null;

  // Get all geofences for the current user
  static Future<List<Map<String, dynamic>>> getUserGeofences() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _client
          .from('geofences')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching geofences: $e');
      rethrow;
    }
  }

  // Create a new geofence
  static Future<Map<String, dynamic>> createGeofence({
    required String name,
    required List<Map<String, double>> points,
    required String color,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response =
          await _client
              .from('geofences')
              .insert({
                'user_id': currentUserId!,
                'name': name,
                'points': points,
                'color': color,
                'is_active': true,
              })
              .select()
              .single();

      return response;
    } catch (e) {
      print('Error creating geofence: $e');
      rethrow;
    }
  }

  // Update an existing geofence
  static Future<void> updateGeofence(
    String geofenceId,
    Map<String, dynamic> updates,
  ) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _client
          .from('geofences')
          .update(updates)
          .eq('id', geofenceId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error updating geofence: $e');
      rethrow;
    }
  }

  // Delete a geofence
  static Future<void> deleteGeofence(String geofenceId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _client
          .from('geofences')
          .delete()
          .eq('id', geofenceId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error deleting geofence: $e');
      rethrow;
    }
  }

  // Toggle geofence active status
  static Future<void> toggleGeofenceStatus(
    String geofenceId,
    bool isActive,
  ) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _client
          .from('geofences')
          .update({'is_active': isActive})
          .eq('id', geofenceId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error toggling geofence status: $e');
      rethrow;
    }
  }
}

// Updated Geofence model
class Geofence {
  final String id;
  final String name;
  final List<LatLng> points;
  final Color color;
  final DateTime createdAt;
  bool isActive;
  final String? userId;

  Geofence({
    required this.id,
    required this.name,
    required this.points,
    required this.color,
    required this.createdAt,
    this.isActive = true,
    this.userId,
  });

  // Convert from Supabase data
  factory Geofence.fromSupabase(Map<String, dynamic> data) {
    final pointsList = List<Map<String, dynamic>>.from(data['points']);
    final points =
        pointsList
            .map(
              (point) =>
                  LatLng(point['lat'].toDouble(), point['lng'].toDouble()),
            )
            .toList();

    return Geofence(
      id: data['id'].toString(),
      name: data['name'],
      points: points,
      color: _colorFromHex(data['color']),
      createdAt: DateTime.parse(data['created_at']),
      isActive: data['is_active'] ?? true,
      userId: data['user_id'],
    );
  }

  // Convert to Supabase format for creating/updating
  Map<String, dynamic> toSupabaseInsert() {
    final pointsList =
        points
            .map((point) => {'lat': point.latitude, 'lng': point.longitude})
            .toList();

    return {
      'name': name,
      'points': pointsList,
      'color': _colorToHex(color),
      'is_active': isActive,
    };
  }

  // Helper methods for color conversion
  static Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  // Create a copy with updated values
  Geofence copyWith({
    String? id,
    String? name,
    List<LatLng>? points,
    Color? color,
    DateTime? createdAt,
    bool? isActive,
    String? userId,
  }) {
    return Geofence(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
    );
  }
}

// Utility class for geofence operations
class GeofenceUtils {
  // Check if a point is inside a polygon (geofence)
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    int intersectCount = 0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;

      if (((polygon[i].latitude <= point.latitude &&
                  point.latitude < polygon[j].latitude) ||
              (polygon[j].latitude <= point.latitude &&
                  point.latitude < polygon[i].latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        intersectCount++;
      }
    }

    return (intersectCount % 2) == 1;
  }

  // Calculate distance between two points (for finding closest point)
  static double calculateDistance(LatLng point1, LatLng point2) {
    double dx = point1.latitude - point2.latitude;
    double dy = point1.longitude - point2.longitude;
    return dx * dx + dy * dy;
  }

  // Find closest point in a list to a target point
  static int findClosestPointIndex(LatLng targetPoint, List<LatLng> points) {
    if (points.isEmpty) return -1;

    double minDistance = double.infinity;
    int closestIndex = -1;

    for (int i = 0; i < points.length; i++) {
      double distance = calculateDistance(targetPoint, points[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Only return the index if the point is reasonably close
    if (minDistance < 0.0005) {
      // Roughly 50 meters at typical zoom levels
      return closestIndex;
    }

    return -1;
  }

  // Generate a random color for new geofences
  static Color getRandomColor(int index) {
    return Colors.primaries[index % Colors.primaries.length];
  }

  // Validate geofence data
  static String? validateGeofence(String name, List<LatLng> points) {
    if (name.trim().isEmpty) {
      return 'Geofence name cannot be empty';
    }

    if (name.length > 50) {
      return 'Geofence name must be less than 50 characters';
    }

    if (points.length < 3) {
      return 'Geofence must have at least 3 points';
    }

    if (points.length > 100) {
      return 'Geofence cannot have more than 100 points';
    }

    return null; // Valid
  }
}
