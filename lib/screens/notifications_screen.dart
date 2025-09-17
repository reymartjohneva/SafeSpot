// screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/notification_service.dart';
import '../utils/device_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GeofenceNotification> _allNotifications = [];
  List<GeofenceNotification> _unreadNotifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _unreadCount = 0;
  StreamSubscription? _notificationStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadNotifications();
    _loadUnreadCount();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _notificationStream?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    if (!NotificationService.isAuthenticated) return;

    setState(() => _isLoading = true);
    
    try {
      final notifications = await NotificationService.getUserNotifications(
        limit: 50,
      );
      final unreadNotifications = await NotificationService.getUserNotifications(
        limit: 50,
        isRead: false,
      );

      if (mounted) {
        setState(() {
          _allNotifications = notifications;
          _unreadNotifications = unreadNotifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        DeviceUtils.showErrorSnackBar(
          context, 
          'Failed to load notifications: $e'
        );
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !NotificationService.isAuthenticated) return;

    setState(() => _isLoadingMore = true);

    try {
      final notifications = await NotificationService.getUserNotifications(
        limit: 20,
      );

      if (mounted) {
        setState(() {
          // Add only new notifications that aren't already in the list
          for (var notification in notifications) {
            if (!_allNotifications.any((n) => n.id == notification.id)) {
              _allNotifications.add(notification);
            }
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    if (!NotificationService.isAuthenticated) return;

    try {
      final count = await NotificationService.getUnreadNotificationCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  void _setupRealtimeUpdates() {
    if (!NotificationService.isAuthenticated) return;

    _notificationStream = NotificationService.streamNotifications().listen(
      (notifications) {
        if (mounted) {
          setState(() {
            _allNotifications = notifications;
            _unreadNotifications = notifications.where((n) => !n.isRead).toList();
          });
          _loadUnreadCount();
        }
      },
      onError: (error) {
        print('Notification stream error: $error');
      },
    );
  }

  Future<void> _markAsRead(GeofenceNotification notification) async {
    if (notification.isRead) return;

    try {
      await NotificationService.markNotificationAsRead(notification.id);
      await _loadNotifications();
      await _loadUnreadCount();
    } catch (e) {
      DeviceUtils.showErrorSnackBar(
        context, 
        'Failed to mark as read: $e'
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllNotificationsAsRead();
      await _loadNotifications();
      await _loadUnreadCount();
      DeviceUtils.showSuccessSnackBar(
        context, 
        'All notifications marked as read'
      );
    } catch (e) {
      DeviceUtils.showErrorSnackBar(
        context, 
        'Failed to mark all as read: $e'
      );
    }
  }

  Future<void> _deleteNotification(GeofenceNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NotificationService.deleteNotification(notification.id);
        await _loadNotifications();
        await _loadUnreadCount();
        DeviceUtils.showSuccessSnackBar(
          context, 
          'Notification deleted'
        );
      } catch (e) {
        DeviceUtils.showErrorSnackBar(
          context, 
          'Failed to delete notification: $e'
        );
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NotificationService.deleteAllNotifications();
        await _loadNotifications();
        await _loadUnreadCount();
        DeviceUtils.showSuccessSnackBar(
          context, 
          'All notifications deleted'
        );
      } catch (e) {
        DeviceUtils.showErrorSnackBar(
          context, 
          'Failed to delete notifications: $e'
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!NotificationService.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 24),
              Text(
                'Authentication Required',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in to view notifications',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_unreadCount new',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'mark_all_read':
                            _markAllAsRead();
                            break;
                          case 'delete_all':
                            _deleteAllNotifications();
                            break;
                          case 'refresh':
                            _loadNotifications();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (_unreadCount > 0)
                          const PopupMenuItem(
                            value: 'mark_all_read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Mark all as read'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'refresh',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Refresh'),
                            ],
                          ),
                        ),
                        if (_allNotifications.isNotEmpty)
                          const PopupMenuItem(
                            value: 'delete_all',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete all'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    tabs: [
                      Tab(
                        text: 'All (${_allNotifications.length})',
                        icon: const Icon(Icons.notifications),
                      ),
                      Tab(
                        text: 'Unread (${_unreadNotifications.length})',
                        icon: const Icon(Icons.notifications_active),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(_allNotifications),
                _buildNotificationsList(_unreadNotifications),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<GeofenceNotification> notifications) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= notifications.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(GeofenceNotification notification) {
    final theme = Theme.of(context);
    final isEnter = notification.notificationType == NotificationType.enter;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: notification.isRead ? 0 : 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
        child: InkWell(
          onTap: () => _markAsRead(notification),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: notification.isRead 
                  ? theme.colorScheme.surface
                  : theme.colorScheme.primary.withOpacity(0.05),
              border: Border.all(
                color: notification.isRead
                    ? theme.colorScheme.outline.withOpacity(0.1)
                    : theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isEnter 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEnter ? Colors.green : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isEnter ? Icons.login : Icons.logout,
                      color: isEnter ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: notification.isRead 
                                      ? FontWeight.w500 
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isEnter 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isEnter ? 'ENTERED' : 'EXITED',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isEnter ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDateTime(notification.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'mark_read':
                          _markAsRead(notification);
                          break;
                        case 'delete':
                          _deleteNotification(notification);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(Icons.mark_email_read, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Mark as read'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isUnreadTab = _tabController.index == 1;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnreadTab ? Icons.mark_email_read : Icons.notifications_none,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isUnreadTab ? 'All caught up!' : 'No notifications yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUnreadTab
                ? 'You have no unread notifications'
                : 'Geofence alerts will appear here when\nyour devices enter or exit defined areas',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isUnreadTab) ...[
            const SizedBox(height: 24),
            Text(
              'Set up geofences in the Map View to start\nreceiving location-based notifications',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';

    if (notificationDate == today) {
      return timeStr;
    } else if (notificationDate == yesterday) {
      return 'Yesterday $timeStr';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} $timeStr';
    }
  }
}