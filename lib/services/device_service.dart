import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static bool get isAuthenticated => _supabase.auth.currentUser != null;
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  // Get all devices for current user
  static Future<List<Device>> getUserDevices() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('devices')
          .select('*')
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Device.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch devices: $e');
    }
  }

  // Add a new device
  static Future<Device> addDevice({
    required String deviceId,
    required String deviceName,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Check if device_id already exists for this user
      final existing =
          await _supabase
              .from('devices')
              .select('id')
              .eq('user_id', currentUserId!)
              .eq('device_id', deviceId)
              .maybeSingle();

      if (existing != null) {
        throw Exception('Device ID already exists');
      }

      final response =
          await _supabase
              .from('devices')
              .insert({
                'user_id': currentUserId!,
                'device_id': deviceId,
                'device_name': deviceName,
              })
              .select()
              .single();

      return Device.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add device: $e');
    }
  }

  // Update device
  static Future<Device> updateDevice({
    required String deviceUuid,
    String? deviceName,
    bool? isActive,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (deviceName != null) updateData['device_name'] = deviceName;
      if (isActive != null) updateData['is_active'] = isActive;

      final response =
          await _supabase
              .from('devices')
              .update(updateData)
              .eq('id', deviceUuid)
              .eq('user_id', currentUserId!)
              .select()
              .single();

      return Device.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update device: $e');
    }
  }

  // Delete device
  static Future<void> deleteDevice(String deviceUuid) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('devices')
          .delete()
          .eq('id', deviceUuid)
          .eq('user_id', currentUserId!);
    } catch (e) {
      throw Exception('Failed to delete device: $e');
    }
  }

  // Get location history for a device
  static Future<List<LocationHistory>> getDeviceLocationHistory({
    required String deviceId,
    int limit = 100,
  }) async {
    try {
      final response = await _supabase
          .from('location_history')
          .select('*')
          .eq('child_id', deviceId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => LocationHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch location history: $e');
    }
  }

  // Add location data (this would be called by the tracked device)
  static Future<void> addLocationData({
    required String deviceId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _supabase.from('location_history').insert({
        'child_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      throw Exception('Failed to save location: $e');
    }
  }
}

// Data Models
class Device {
  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Device({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'] ?? 'Unknown Device',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'device_name': deviceName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class LocationHistory {
  final int id;
  final String childId;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  LocationHistory({
    required this.id,
    required this.childId,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) {
    return LocationHistory(
      id: json['id'],
      childId: json['child_id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
