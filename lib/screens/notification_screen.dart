// notification_screen.dart
import 'package:flutter/material.dart';
import 'package:safe_spot/services/notification_service.dart';
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Custom colors matching your app theme
  static const Color primaryOrange = Color(0xFFFF8A50);
  static const Color darkBackground = Colors.black87;
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF2D2D2D);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';
  StreamSubscription? _notificationSubscription;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToNotifications() {
    try {
      _notificationSubscription = NotificationService.subscribeToNotifications()
          .listen((notifications) {
        if (mounted) {
          setState(() {
            _notifications = notifications;
          });
          _loadUnreadCount();
        }
      });
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  Future<void> _loadNotifications() async {
    if (!NotificationService.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      List<AppNotification> notifications;
      
      if (_selectedFilter == 'all') {
        notifications = await NotificationService.getUserNotifications();
      } else {
        notifications = await NotificationService.getNotificationsByType(_selectedFilter);
      }

      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await NotificationService.markAsRead(notification.id);
      await _loadNotifications();
      await _loadUnreadCount();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      await _loadNotifications();
      await _loadUnreadCount();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: primaryOrange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
      await _loadNotifications();
      await _loadUnreadCount();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: primaryOrange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _deleteOldNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        title: const Text(
          'Delete Old Notifications',
          style: TextStyle(color: textPrimary),
        ),
        content: const Text(
          'Delete all notifications older than 30 days?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final count = await NotificationService.deleteOldNotifications();
        await _loadNotifications();
        await _loadUnreadCount();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted $count old notification${count != 1 ? 's' : ''}'),
              backgroundColor: primaryOrange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete old notifications: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    if (!NotificationService.isAuthenticated) {
      return Scaffold(
        backgroundColor: darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: textSecondary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Authentication Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please log in to view notifications',
                style: TextStyle(fontSize: 16, color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: darkBackground,
        surfaceTintColor: darkBackground,
        title: Row(
          children: [
            Image.asset(
              'assets/app1_icon.png',
              height: 50,
              width: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: textPrimary),
            color: cardBackground,
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              } else if (value == 'delete_old') {
                _deleteOldNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: textPrimary),
                    SizedBox(width: 8),
                    Text('Mark all as read', style: TextStyle(color: textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_old',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: textPrimary),
                    SizedBox(width: 8),
                    Text('Delete old', style: TextStyle(color: textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              color: primaryOrange,
              backgroundColor: cardBackground,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                      ),
                    )
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': 'all', 'icon': Icons.inbox},
      {'label': 'Entry', 'value': 'geofence_entry', 'icon': Icons.login},
      {'label': 'Exit', 'value': 'geofence_exit', 'icon': Icons.logout},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(filter['label'] as String),
                  ],
                ),
                onSelected: (selected) {
                  if (selected) _changeFilter(filter['value'] as String);
                },
                backgroundColor: surfaceColor,
                selectedColor: primaryOrange,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    Color? geofenceColor;
    if (notification.geofenceColor != null) {
      final hexString = notification.geofenceColor!.replaceFirst('#', '');
      geofenceColor = Color(int.parse('ff$hexString', radix: 16));
    }

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
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () => _markAsRead(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? cardBackground : surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.transparent
                  : primaryOrange.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: notification.isRead
                ? []
                : [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.1),
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
                // Icon/Indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: geofenceColor?.withOpacity(0.2) ?? 
                           primaryOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _getNotificationIcon(notification.notificationType),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: textPrimary,
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
                                color: primaryOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.getTimeAgo(),
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (notification.deviceName != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.phone_android,
                              size: 12,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.deviceName!,
                              style: TextStyle(
                                color: textSecondary,
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
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'geofence_entry':
        icon = Icons.login;
        color = Colors.green;
        break;
      case 'geofence_exit':
        icon = Icons.logout;
        color = Colors.red;
        break;
      case 'device_offline':
        icon = Icons.signal_wifi_off;
        color = Colors.orange;
        break;
      case 'low_battery':
        icon = Icons.battery_alert;
        color = Colors.yellow;
        break;
      default:
        icon = Icons.notifications;
        color = primaryOrange;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'all'
                ? 'No notifications yet'
                : 'No ${_selectedFilter.replaceAll('_', ' ')} notifications',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll see important alerts here',
            style: TextStyle(fontSize: 16, color: textSecondary),
          ),
        ],
      ),
    );
  }
}