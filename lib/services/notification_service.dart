// notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String? get currentUserId => _client.auth.currentUser?.id;
  static bool get isAuthenticated => currentUserId != null;

  // Get all notifications for current user
  static Future<List<AppNotification>> getUserNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _client
          .from('notifications')
          .select('''
            *,
            devices!notifications_device_id_fkey(device_name, device_id),
            geofences(name, color)
          ''')
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  // Get unread notifications count
  static Future<int> getUnreadCount() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _client.rpc('mark_all_notifications_read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', currentUserId!);
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Delete old notifications
  static Future<int> deleteOldNotifications({int daysOld = 30}) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final result = await _client.rpc(
        'delete_old_notifications',
        params: {'days_old': daysOld},
      );
      return result as int? ?? 0;
    } catch (e) {
      print('Error deleting old notifications: $e');
      return 0;
    }
  }

  // Subscribe to real-time notifications
  static Stream<List<AppNotification>> subscribeToNotifications() {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    return _client
        .from('notifications:user_id=eq.$currentUserId')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => AppNotification.fromJson(json)).toList());
  }

  // Get notifications by type
  static Future<List<AppNotification>> getNotificationsByType(
    String type, {
    int limit = 50,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _client
          .from('notifications')
          .select('''
            *,
            devices!notifications_device_id_fkey(device_name, device_id),
            geofences(name, color)
          ''')
          .eq('user_id', currentUserId!)
          .eq('notification_type', type)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications by type: $e');
      rethrow;
    }
  }

  // Get notifications for specific device
  static Future<List<AppNotification>> getDeviceNotifications(
    String deviceId, {
    int limit = 50,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _client
          .from('notifications')
          .select('''
            *,
            devices!notifications_device_id_fkey(device_name, device_id),
            geofences(name, color)
          ''')
          .eq('user_id', currentUserId!)
          .eq('device_id', deviceId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching device notifications: $e');
      rethrow;
    }
  }
}

extension on PostgrestList {
  get count => null;
}

// Notification model
class AppNotification {
  final String id;
  final String userId;
  final String deviceId;
  final String? geofenceId;
  final String notificationType;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  
  // Related data
  final String? deviceName;
  final String? geofenceName;
  final String? geofenceColor;

  AppNotification({
    required this.id,
    required this.userId,
    required this.deviceId,
    this.geofenceId,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.metadata,
    this.deviceName,
    this.geofenceName,
    this.geofenceColor,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      geofenceId: json['geofence_id']?.toString(),
      notificationType: json['notification_type'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'] ?? {},
      deviceName: json['devices']?['device_name'],
      geofenceName: json['geofences']?['name'],
      geofenceColor: json['geofences']?['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'geofence_id': geofenceId,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Helper method to get formatted time ago
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Get notification icon based on type
  String getIconEmoji() {
    switch (notificationType) {
      case 'geofence_entry':
        return '🟢';
      case 'geofence_exit':
        return '🔴';
      case 'device_offline':
        return '⚠️';
      case 'low_battery':
        return '🔋';
      default:
        return '📍';
    }
  }
}