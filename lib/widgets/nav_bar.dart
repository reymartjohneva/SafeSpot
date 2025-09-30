import 'package:flutter/material.dart';
import 'package:safe_spot/services/notification_service.dart';
import 'dart:async';

class ModernNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ModernNavBar> createState() => _ModernNavBarState();
}

class _ModernNavBarState extends State<ModernNavBar> {
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main navigation bar with curve cutout
        Container(
          height: 80,
          decoration: const BoxDecoration(
            color: Colors.black87,
          ),
          child: CustomPaint(
            painter: NavBarPainter(
              currentIndex: widget.currentIndex,
              itemCount: 4,
            ),
            child: Row(
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home_filled,
                  label: 'Home',
                  index: 0,
                  isActive: widget.currentIndex == 0,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.info_rounded,
                  label: 'Information',
                  index: 1,
                  isActive: widget.currentIndex == 1,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.notifications_rounded,
                  label: 'Notification',
                  index: 2,
                  isActive: widget.currentIndex == 2,
                  showBadge: _unreadCount > 0,
                  badgeCount: _unreadCount,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 3,
                  isActive: widget.currentIndex == 3,
                ),
              ],
            ),
          ),
        ),
        // Floating bubble
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutBack,
          left: _getBubblePosition(context),
          top: -10,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A50), // Orange color
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A50).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getActiveIcon(),
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                // Show badge on floating bubble when notifications tab is active
                if (widget.currentIndex == 2 && _unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
          ),
        ),
      ],
    );
  }

  double _getBubblePosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 4;
    final bubbleWidth = 60.0;
    
    return (widget.currentIndex * itemWidth) + (itemWidth / 2) - (bubbleWidth / 2);
  }

  IconData _getActiveIcon() {
    switch (widget.currentIndex) {
      case 0:
        return Icons.home_filled;
      case 1:
        return Icons.info_rounded;
      case 2:
        return Icons.notifications_rounded;
      case 3:
        return Icons.person_rounded;
      default:
        return Icons.home_filled;
    }
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        child: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // Only show icon if not active (active icon is in floating bubble)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isActive ? 0.0 : 1.0,
                    child: Icon(
                      icon,
                      size: 24,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  // Badge on inactive notification icon
                  if (showBadge && !isActive)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black87,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isActive ? const Color(0xFFFF8A50) : Colors.grey.shade400,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavBarPainter extends CustomPainter {
  final int currentIndex;
  final int itemCount;

  NavBarPainter({
    required this.currentIndex,
    required this.itemCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final path = Path();
    
    final itemWidth = size.width / itemCount;
    final curveStart = currentIndex * itemWidth + (itemWidth * 0.2);
    final curveEnd = currentIndex * itemWidth + (itemWidth * 0.8);
    final curveDepth = 25.0;

    // Start from top-left with border radius
    path.moveTo(0, 24);
    path.quadraticBezierTo(0, 0, 24, 0);

    // Draw line to curve start
    path.lineTo(curveStart, 0);
    
    // Create the curve cutout for floating bubble
    path.quadraticBezierTo(
      curveStart + (curveEnd - curveStart) * 0.5, 
      -curveDepth, 
      curveEnd, 
      0
    );

    // Continue to top-right corner with border radius
    path.lineTo(size.width - 24, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 24);
    
    // Complete the rectangle
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is NavBarPainter && 
           oldDelegate.currentIndex != currentIndex;
  }
}