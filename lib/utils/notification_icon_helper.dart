import 'package:flutter/material.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';

class NotificationIconHelper {
  NotificationIconHelper._();

  static Widget getIcon(String type) {
    final iconData = _getIconData(type);
    
    return Icon(
      iconData.icon,
      color: iconData.color,
      size: 24,
    );
  }

  static _NotificationIconData _getIconData(String type) {
    switch (type) {
      case 'geofence_entry':
        return _NotificationIconData(
          icon: Icons.login,
          color: Colors.green,
        );
      case 'geofence_exit':
        return _NotificationIconData(
          icon: Icons.logout,
          color: Colors.red,
        );
      case 'device_offline':
        return _NotificationIconData(
          icon: Icons.signal_wifi_off,
          color: Colors.orange,
        );
      case 'low_battery':
        return _NotificationIconData(
          icon: Icons.battery_alert,
          color: Colors.yellow,
        );
      default:
        return _NotificationIconData(
          icon: Icons.notifications,
          color: NotificationColors.primaryOrange,
        );
    }
  }
}

class _NotificationIconData {
  final IconData icon;
  final Color color;

  _NotificationIconData({
    required this.icon,
    required this.color,
  });
}