import 'package:flutter/material.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';

class NotificationEmptyState extends StatefulWidget {
  final String selectedFilter;

  const NotificationEmptyState({
    Key? key,
    required this.selectedFilter,
  }) : super(key: key);

  @override
  State<NotificationEmptyState> createState() => _NotificationEmptyStateState();
}

class _NotificationEmptyStateState extends State<NotificationEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getEmptyStateIcon() {
    switch (widget.selectedFilter) {
      case 'geofence_entry':
        return Icons.login_rounded;
      case 'geofence_exit':
        return Icons.logout_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _getEmptyStateTitle() {
    if (widget.selectedFilter == 'all') {
      return 'No notifications yet';
    }
    final filterName = widget.selectedFilter.replaceAll('_', ' ');
    return 'No $filterName notifications';
  }

  String _getEmptyStateSubtitle() {
    switch (widget.selectedFilter) {
      case 'geofence_entry':
        return 'Entry notifications will appear here';
      case 'geofence_exit':
        return 'Exit notifications will appear here';
      default:
        return 'You\'ll see important alerts here';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.all(40),
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
                    border: Border.all(
                      color: const Color(0xFF404040),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: NotificationColors.primaryOrange.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 2),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 0.1 * 3.14159,
                        child: child,
                      );
                    },
                    onEnd: () {
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: Icon(
                      _getEmptyStateIcon(),
                      size: 72,
                      color: NotificationColors.primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _getEmptyStateTitle(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: NotificationColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: NotificationColors.surfaceColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF404040),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getEmptyStateSubtitle(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: NotificationColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                _buildFeaturesList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NotificationColors.surfaceColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF404040),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildFeatureItem(
            icon: Icons.notifications_active_rounded,
            text: 'Get real-time alerts',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.location_on_rounded,
            text: 'Track geofence activities',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            icon: Icons.security_rounded,
            text: 'Stay informed and secure',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NotificationColors.primaryOrange.withOpacity(0.3),
                NotificationColors.primaryOrange.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: NotificationColors.primaryOrange,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: NotificationColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}