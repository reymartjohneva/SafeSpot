import 'package:flutter/material.dart';
import 'package:safe_spot/services/notification_service.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';
import 'package:safe_spot/utils/notification_icon_helper.dart';

class NotificationCard extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color? _getGeofenceColor() {
    if (widget.notification.geofenceColor == null) return null;
    
    final hexString = widget.notification.geofenceColor!.replaceFirst('#', '');
    return Color(int.parse('ff$hexString', radix: 16));
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final geofenceColor = _getGeofenceColor();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dismissible(
        key: Key(widget.notification.id),
        background: _buildDismissBackground(),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => widget.onDismissed(),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: widget.notification.isRead
                  ? null
                  : LinearGradient(
                      colors: [
                        NotificationColors.surfaceColor,
                        NotificationColors.cardBackground,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: widget.notification.isRead
                  ? NotificationColors.cardBackground
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.notification.isRead
                    ? const Color(0xFF404040)
                    : NotificationColors.primaryOrange.withOpacity(0.5),
                width: widget.notification.isRead ? 1 : 1.5,
              ),
              boxShadow: widget.notification.isRead
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: NotificationColors.primaryOrange.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIconContainer(geofenceColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildContent(geofenceColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900,
            Colors.red.shade700,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer(Color? geofenceColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (geofenceColor ?? NotificationColors.primaryOrange).withOpacity(0.3),
            (geofenceColor ?? NotificationColors.primaryOrange).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (geofenceColor ?? NotificationColors.primaryOrange).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (geofenceColor ?? NotificationColors.primaryOrange).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: NotificationIconHelper.getIcon(widget.notification.notificationType),
      ),
    );
  }

  Widget _buildContent(Color? geofenceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        Text(
          widget.notification.message,
          style: TextStyle(
            color: NotificationColors.textSecondary,
            fontSize: 14,
            height: 1.5,
            fontWeight: widget.notification.isRead ? FontWeight.normal : FontWeight.w500,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        _buildMetadata(geofenceColor),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.notification.title,
            style: TextStyle(
              color: NotificationColors.textPrimary,
              fontSize: 17,
              fontWeight: widget.notification.isRead
                  ? FontWeight.w600
                  : FontWeight.bold,
              letterSpacing: -0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!widget.notification.isRead) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFFF9800),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NotificationColors.primaryOrange.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadata(Color? geofenceColor) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildMetadataChip(
          icon: Icons.access_time_rounded,
          label: widget.notification.getTimeAgo(),
          color: NotificationColors.textSecondary,
        ),
        if (widget.notification.deviceName != null)
          _buildMetadataChip(
            icon: Icons.phone_android_rounded,
            label: widget.notification.deviceName!,
            color: NotificationColors.textSecondary,
          ),
        if (widget.notification.geofenceName != null)
          _buildGeofenceChip(
            label: widget.notification.geofenceName!,
            color: geofenceColor,
          ),
      ],
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NotificationColors.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF404040),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofenceChip({
    required String label,
    required Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (color ?? NotificationColors.primaryOrange).withOpacity(0.3),
            (color ?? NotificationColors.primaryOrange).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? NotificationColors.primaryOrange).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color ?? NotificationColors.primaryOrange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (color ?? NotificationColors.primaryOrange).withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color ?? NotificationColors.primaryOrange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}