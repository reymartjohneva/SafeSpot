import 'package:flutter/material.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';

class NotificationEmptyState extends StatelessWidget {
  final String selectedFilter;

  const NotificationEmptyState({
    Key? key,
    required this.selectedFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NotificationColors.surfaceColor,
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
              color: NotificationColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getEmptyStateTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: NotificationColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll see important alerts here',
            style: TextStyle(
              fontSize: 16,
              color: NotificationColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateTitle() {
    if (selectedFilter == 'all') {
      return 'No notifications yet';
    }
    return 'No ${selectedFilter.replaceAll('_', ' ')} notifications';
  }
}