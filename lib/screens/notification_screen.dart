import 'package:flutter/material.dart';
import 'package:safe_spot/services/notification_service.dart';
import 'package:safe_spot/services/geofence_monitor_service.dart';
import 'package:safe_spot/screens/notification_components/notification_app_bar.dart';
import 'package:safe_spot/screens/notification_components/notification_filter_chips.dart';
import 'package:safe_spot/screens/notification_components/notification_card.dart';
import 'package:safe_spot/screens/notification_components/notification_empty_state.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';
import 'package:safe_spot/screens/geofence_debug_screen.dart';
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';
  StreamSubscription? _notificationSubscription;
  int _unreadCount = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _loadNotifications();
    _loadUnreadCount();
    _subscribeToNotifications();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _subscribeToNotifications() {
    try {
      _notificationSubscription = NotificationService.subscribeToNotifications()
          .listen((notifications) {
        print('📱 Notification stream received: ${notifications.length} notifications');
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

      print('📱 Loaded ${notifications.length} notifications from database');

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: Color(0xFF404040),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Old',
              style: TextStyle(
                color: NotificationColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Delete all notifications older than 30 days? This action cannot be undone.',
          style: TextStyle(
            color: NotificationColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: NotificationColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: NotificationColors.primaryOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
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
        onDebug: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GeofenceDebugScreen(),
            ),
          );
        },
        onForceCheck: _forceCheckGeofences,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
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
                strokeWidth: 3,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTestNotification() async {
    try {
      await GeofenceMonitorService.createTestNotification();
      _showSuccessSnackBar('Test notification created!');
      await Future.delayed(const Duration(milliseconds: 500));
      _loadNotifications();
    } catch (e) {
      _showErrorSnackBar('Failed to create test notification: $e');
    }
  }

  Future<void> _forceCheckGeofences() async {
    try {
      _showSuccessSnackBar('Checking all devices...');
      await GeofenceMonitorService.recheckAllDevices();
      _showSuccessSnackBar('Check completed! See console for details.');
      await Future.delayed(const Duration(seconds: 1));
      _loadNotifications();
    } catch (e) {
      _showErrorSnackBar('Failed to check geofences: $e');
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NotificationColors.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NotificationColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NotificationColors.primaryOrange),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading notifications...',
              style: TextStyle(
                color: NotificationColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: NotificationCard(
            notification: notification,
            onTap: () => _markAsRead(notification),
            onDismissed: () => _deleteNotification(notification.id),
          ),
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
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    NotificationColors.surfaceColor,
                    NotificationColors.cardBackground,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 80,
                color: NotificationColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Authentication Required',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: NotificationColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Please log in to view your notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: NotificationColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}