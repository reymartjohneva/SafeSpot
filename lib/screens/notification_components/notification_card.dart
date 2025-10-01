import 'package:flutter/material.dart';
import 'package:safe_spot/services/notification_service.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';
import 'package:safe_spot/utils/notification_icon_helper.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  }) : super(key: key);

  Color? _getGeofenceColor() {
    if (notification.geofenceColor == null) return null;
    
    final hexString = notification.geofenceColor!.replaceFirst('#', '');
    return Color(int.parse('ff$hexString', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final geofenceColor = _getGeofenceColor();

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? NotificationColors.cardBackground
                : NotificationColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.transparent
                  : NotificationColors.primaryOrange.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: notification.isRead
                ? []
                : [
                    BoxShadow(
                      color: NotificationColors.primaryOrange.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconContainer(geofenceColor),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContent(geofenceColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(Color? geofenceColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: geofenceColor?.withOpacity(0.2) ??
            NotificationColors.primaryOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: NotificationIconHelper.getIcon(notification.notificationType),
      ),
    );
  }

  Widget _buildContent(Color? geofenceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 4),
        Text(
          notification.message,
          style: const TextStyle(
            color: NotificationColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetadata(geofenceColor),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            notification.title,
            style: TextStyle(
              color: NotificationColors.textPrimary,
              fontSize: 16,
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.w600,
            ),
          ),
        ),
        if (!notification.isRead)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: NotificationColors.primaryOrange,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildMetadata(Color? geofenceColor) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: NotificationColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          notification.getTimeAgo(),
          style: TextStyle(
            color: NotificationColors.textSecondary,
            fontSize: 12,
          ),
        ),
        if (notification.deviceName != null) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.phone_android,
            size: 12,
            color: NotificationColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            notification.deviceName!,
            style: TextStyle(
              color: NotificationColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        if (notification.geofenceName != null) ...[
          const SizedBox(width: 12),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: geofenceColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            notification.geofenceName!,
            style: TextStyle(
              color: NotificationColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}