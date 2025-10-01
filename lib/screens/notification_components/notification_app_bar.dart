import 'package:flutter/material.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';

class NotificationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int unreadCount;
  final VoidCallback onMarkAllAsRead;
  final VoidCallback onDeleteOld;

  const NotificationAppBar({
    Key? key,
    required this.unreadCount,
    required this.onMarkAllAsRead,
    required this.onDeleteOld,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: NotificationColors.darkBackground,
      surfaceTintColor: NotificationColors.darkBackground,
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
              color: NotificationColors.textPrimary,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NotificationColors.primaryOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
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
          icon: const Icon(
            Icons.more_vert,
            color: NotificationColors.textPrimary,
          ),
          color: NotificationColors.cardBackground,
          onSelected: (value) {
            if (value == 'mark_all_read') {
              onMarkAllAsRead();
            } else if (value == 'delete_old') {
              onDeleteOld();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mark_all_read',
              child: Row(
                children: [
                  Icon(Icons.done_all, color: NotificationColors.textPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Mark all as read',
                    style: TextStyle(color: NotificationColors.textPrimary),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete_old',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, color: NotificationColors.textPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Delete old',
                    style: TextStyle(color: NotificationColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}