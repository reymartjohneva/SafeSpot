// notification_icon_button.dart
import 'package:flutter/material.dart';
import 'package:safe_spot/services/notification_service.dart';
import 'package:safe_spot/screens/notification_screen.dart';
import 'dart:async';

class NotificationIconButton extends StatefulWidget {
  final Color iconColor;
  final double iconSize;

  const NotificationIconButton({
    Key? key,
    this.iconColor = Colors.white,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton> {
  int _unreadCount = 0;
  Timer? _refreshTimer;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _startPeriodicRefresh();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToNotifications() {
    if (!NotificationService.isAuthenticated) return;

    try {
      _notificationSubscription = NotificationService.subscribeToNotifications()
          .listen((notifications) {
        _loadUnreadCount();
      });
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && NotificationService.isAuthenticated) {
        _loadUnreadCount();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    if (!NotificationService.isAuthenticated) return;

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

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    ).then((_) {
      // Refresh count when returning from notification screen
      _loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: widget.iconColor,
            size: widget.iconSize,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: _openNotifications,
      tooltip: 'Notifications',
    );
  }
}