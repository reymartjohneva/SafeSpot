// notification_utils.dart
import 'package:flutter/material.dart';

class NotificationUtils {
  // Custom colors
  static const Color primaryOrange = Color(0xFFFF8A50);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: primaryOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Get notification type label
  static String getNotificationTypeLabel(String type) {
    switch (type) {
      case 'geofence_entry':
        return 'Geofence Entry';
      case 'geofence_exit':
        return 'Geofence Exit';
      case 'device_offline':
        return 'Device Offline';
      case 'low_battery':
        return 'Low Battery';
      default:
        return 'Notification';
    }
  }

  // Get notification type icon
  static IconData getNotificationTypeIcon(String type) {
    switch (type) {
      case 'geofence_entry':
        return Icons.login;
      case 'geofence_exit':
        return Icons.logout;
      case 'device_offline':
        return Icons.signal_wifi_off;
      case 'low_battery':
        return Icons.battery_alert;
      default:
        return Icons.notifications;
    }
  }

  // Get notification type color
  static Color getNotificationTypeColor(String type) {
    switch (type) {
      case 'geofence_entry':
        return Colors.green;
      case 'geofence_exit':
        return Colors.red;
      case 'device_offline':
        return Colors.orange;
      case 'low_battery':
        return Colors.yellow;
      default:
        return primaryOrange;
    }
  }

  // Format timestamp
  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  // Format full date time
  static String formatFullDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${_formatTime(dateTime)}';
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Show confirmation dialog
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Text(
          title,
          style: const TextStyle(color: textPrimary),
        ),
        content: Text(
          message,
          style: const TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: const TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? primaryOrange,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Show notification details dialog
  static void showNotificationDetailsDialog(
    BuildContext context, {
    required String title,
    required String message,
    required DateTime timestamp,
    required String notificationType,
    String? deviceName,
    String? geofenceName,
    Map<String, dynamic>? metadata,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: Row(
          children: [
            Icon(
              getNotificationTypeIcon(notificationType),
              color: getNotificationTypeColor(notificationType),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: textSecondary),
              const SizedBox(height: 16),
              _buildDetailRow('Type', getNotificationTypeLabel(notificationType)),
              if (deviceName != null)
                _buildDetailRow('Device', deviceName),
              if (geofenceName != null)
                _buildDetailRow('Geofence', geofenceName),
              _buildDetailRow('Time', formatFullDateTime(timestamp)),
              if (metadata != null && metadata.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Additional Info:',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...metadata.entries.map((entry) {
                  if (entry.key != 'device_name' && 
                      entry.key != 'geofence_name' &&
                      entry.value != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_formatKey(entry.key)}: ${entry.value}',
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Group notifications by date
  static Map<String, List<dynamic>> groupNotificationsByDate(List<dynamic> notifications) {
    final Map<String, List<dynamic>> grouped = {};
    final now = DateTime.now();
    
    for (var notification in notifications) {
      final createdAt = notification is Map 
          ? DateTime.parse(notification['created_at'])
          : (notification as dynamic).createdAt;
      
      String dateKey;
      final difference = now.difference(createdAt).inDays;
      
      if (difference == 0) {
        dateKey = 'Today';
      } else if (difference == 1) {
        dateKey = 'Yesterday';
      } else if (difference < 7) {
        dateKey = 'This Week';
      } else if (difference < 30) {
        dateKey = 'This Month';
      } else {
        dateKey = 'Older';
      }
      
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(notification);
    }
    
    return grouped;
  }
}