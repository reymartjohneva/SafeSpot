// services/notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static bool get isAuthenticated => _supabase.auth.currentUser != null;
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  // Get all notifications for current user
  static Future<List<GeofenceNotification>> getUserNotifications({
    int limit = 50,
    bool? isRead,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      var query = _supabase
          .from('geofence_notifications')
          .select('*')
          .eq('user_id', currentUserId!);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((json) => GeofenceNotification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('geofence_notifications')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('geofence_notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('geofence_notifications')
          .update({'is_read': true})
          .eq('user_id', currentUserId!)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('geofence_notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications
  static Future<void> deleteAllNotifications() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('geofence_notifications')
          .delete()
          .eq('user_id', currentUserId!);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Get notifications by device
  static Future<List<GeofenceNotification>> getNotificationsByDevice(
    String deviceId, {
    int limit = 20,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('geofence_notifications')
          .select('*')
          .eq('user_id', currentUserId!)
          .eq('device_id', deviceId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => GeofenceNotification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch device notifications: $e');
    }
  }

  // Get notifications by geofence
  static Future<List<GeofenceNotification>> getNotificationsByGeofence(
    String geofenceId, {
    int limit = 20,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('geofence_notifications')
          .select('*')
          .eq('user_id', currentUserId!)
          .eq('geofence_id', geofenceId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => GeofenceNotification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch geofence notifications: $e');
    }
  }

  // Stream notifications for real-time updates
  static Stream<List<GeofenceNotification>> streamNotifications() {
    if (!isAuthenticated) {
      return Stream.error('User not authenticated');
    }

    return _supabase
        .from('geofence_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .map((json) => GeofenceNotification.fromJson(json))
            .toList());
  }

  // Create new notification (helper method for when geofence events occur)
  static Future<GeofenceNotification> createNotification({
    required String deviceId,
    required String geofenceId,
    required NotificationType notificationType,
    required double latitude,
    required double longitude,
    String? deviceName,
    String? geofenceName,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('geofence_notifications')
          .insert({
            'user_id': currentUserId!,
            'device_id': deviceId,
            'geofence_id': geofenceId,
            'notification_type': notificationType.toString(),
            'latitude': latitude,
            'longitude': longitude,
            'device_name': deviceName,
            'geofence_name': geofenceName,
          })
          .select()
          .single();

      return GeofenceNotification.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }
}

// Data Models
class GeofenceNotification {
  final String id;
  final String userId;
  final String deviceId;
  final String geofenceId;
  final NotificationType notificationType;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool isRead;
  final String? deviceName;
  final String? geofenceName;

  GeofenceNotification({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.geofenceId,
    required this.notificationType,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.isRead,
    this.deviceName,
    this.geofenceName,
  });

  factory GeofenceNotification.fromJson(Map<String, dynamic> json) {
    return GeofenceNotification(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      geofenceId: json['geofence_id'],
      notificationType: NotificationType.fromString(json['notification_type']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      deviceName: json['device_name'],
      geofenceName: json['geofence_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'geofence_id': geofenceId,
      'notification_type': notificationType.toString(),
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'device_name': deviceName,
      'geofence_name': geofenceName,
    };
  }

  // Helper method to get display title
  String get title {
    final deviceDisplayName = deviceName ?? 'Unknown Device';
    final geofenceDisplayName = geofenceName ?? 'Unknown Area';
    
    switch (notificationType) {
      case NotificationType.enter:
        return '$deviceDisplayName entered $geofenceDisplayName';
      case NotificationType.exit:
        return '$deviceDisplayName left $geofenceDisplayName';
    }
  }

  // Helper method to get display subtitle
  String get subtitle {
    final time = _formatTime(createdAt);
    return 'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)} • $time';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  GeofenceNotification copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? geofenceId,
    NotificationType? notificationType,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    bool? isRead,
    String? deviceName,
    String? geofenceName,
  }) {
    return GeofenceNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      geofenceId: geofenceId ?? this.geofenceId,
      notificationType: notificationType ?? this.notificationType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      deviceName: deviceName ?? this.deviceName,
      geofenceName: geofenceName ?? this.geofenceName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeofenceNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GeofenceNotification(id: $id, title: $title, isRead: $isRead)';
  }
}

enum NotificationType {
  enter,
  exit;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'enter':
        return NotificationType.enter;
      case 'exit':
        return NotificationType.exit;
      default:
        throw ArgumentError('Unknown notification type: $value');
    }
  }

  @override
  String toString() {
    switch (this) {
      case NotificationType.enter:
        return 'enter';
      case NotificationType.exit:
        return 'exit';
    }
  }
}