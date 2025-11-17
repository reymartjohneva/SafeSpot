import 'package:flutter/material.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';

class NotificationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int unreadCount;
  final VoidCallback onMarkAllAsRead;
  final VoidCallback onDeleteOld;
  final VoidCallback? onDebug;
  final VoidCallback? onForceCheck;

  const NotificationAppBar({
    Key? key,
    required this.unreadCount,
    required this.onMarkAllAsRead,
    required this.onDeleteOld,
    this.onDebug,
    this.onForceCheck,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: NotificationColors.darkBackground,
      surfaceTintColor: NotificationColors.darkBackground,
      toolbarHeight: 80,
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Logo container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/app1_icon.png',
                height: 40,
                width: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 40,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),

            // Title and badge
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ShaderMask(
                          shaderCallback:
                              (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFFFF9800)],
                              ).createShader(bounds),
                          child: const Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: NotificationColors.textPrimary,
              size: 24,
            ),
            color: NotificationColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: const Color(0xFF404040), width: 1),
            ),
            elevation: 8,
            offset: const Offset(0, 8),
            onSelected: (value) {
              if (value == 'mark_all_read') {
                onMarkAllAsRead();
              } else if (value == 'delete_old') {
                onDeleteOld();
              } else if (value == 'debug' && onDebug != null) {
                onDebug!();
              } else if (value == 'force_check' && onForceCheck != null) {
                onForceCheck!();
              }
            },
            itemBuilder:
                (context) => [
                  if (onForceCheck != null)
                    PopupMenuItem(
                      value: 'force_check',
                      height: 48,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  if (onDebug != null)
                    PopupMenuItem(
                      value: 'debug',
                      height: 48,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bug_report_rounded,
                              color: Colors.purple,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  if (onDebug != null || onForceCheck != null)
                    const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'mark_all_read',
                    height: 48,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: NotificationColors.primaryOrange.withOpacity(
                              0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.done_all_rounded,
                            color: NotificationColors.primaryOrange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Mark all as read',
                          style: TextStyle(
                            color: NotificationColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'delete_old',
                    height: 48,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Delete old',
                          style: TextStyle(
                            color: NotificationColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ),
      ],
    );
  }
}
