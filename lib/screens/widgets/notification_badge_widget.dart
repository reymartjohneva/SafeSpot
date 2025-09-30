// notification_badge_widget.dart
import 'package:flutter/material.dart';
import 'package:safe_spot/services/notification_service.dart';
import 'dart:async';

class NotificationBadgeWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    Key? key,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  State<NotificationBadgeWidget> createState() => _NotificationBadgeWidgetState();
}

class _NotificationBadgeWidgetState extends State<NotificationBadgeWidget> {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_unreadCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}