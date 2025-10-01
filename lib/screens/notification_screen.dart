import 'package:flutter/material.dart';
import 'package:safe_spot/services/notification_service.dart';
import 'package:safe_spot/screens/notification_components/notification_app_bar.dart';
import 'package:safe_spot/screens/notification_components/notification_filter_chips.dart';
import 'package:safe_spot/screens/notification_components/notification_card.dart';
import 'package:safe_spot/screens/notification_components/notification_empty_state.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
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
        _showErrorSnackBar('Failed to load notifications: $e');
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
        _showSuccessSnackBar('All notifications marked as read');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to mark all as read: $e');
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
      await _loadNotifications();
      await _loadUnreadCount();
      
      if (mounted) {
        _showSuccessSnackBar('Notification deleted');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete notification: $e');
      }
    }
  }

  Future<void> _deleteOldNotifications() async {
    final confirmed = await _showDeleteConfirmationDialog();

    if (confirmed == true) {
      try {
        final count = await NotificationService.deleteOldNotifications();
        await _loadNotifications();
        await _loadUnreadCount();
        
        if (mounted) {
          _showSuccessSnackBar('Deleted $count old notification${count != 1 ? 's' : ''}');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to delete old notifications: $e');
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NotificationColors.cardBackground,
        title: const Text(
          'Delete Old Notifications',
          style: TextStyle(color: NotificationColors.textPrimary),
        ),
        content: const Text(
          'Delete all notifications older than 30 days?',
          style: TextStyle(color: NotificationColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: NotificationColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NotificationColors.primaryOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
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
      return _buildUnauthenticatedView();
    }

    return Scaffold(
      backgroundColor: NotificationColors.darkBackground,
      appBar: NotificationAppBar(
        unreadCount: _unreadCount,
        onMarkAllAsRead: _markAllAsRead,
        onDeleteOld: _deleteOldNotifications,
      ),
      body: Column(
        children: [
          NotificationFilterChips(
            selectedFilter: _selectedFilter,
            onFilterChanged: _changeFilter,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              color: NotificationColors.primaryOrange,
              backgroundColor: NotificationColors.cardBackground,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(NotificationColors.primaryOrange),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return NotificationEmptyState(selectedFilter: _selectedFilter);
    }

    return _buildNotificationList();
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () => _markAsRead(notification),
          onDismissed: () => _deleteNotification(notification.id),
        );
      },
    );
  }

  Widget _buildUnauthenticatedView() {
    return Scaffold(
      backgroundColor: NotificationColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: NotificationColors.textSecondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Authentication Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: NotificationColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to view notifications',
              style: TextStyle(
                fontSize: 16,
                color: NotificationColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}