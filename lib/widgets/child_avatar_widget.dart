import 'package:flutter/material.dart';

class ChildAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String childName;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const ChildAvatarWidget({
    Key? key,
    this.avatarUrl,
    required this.childName,
    this.size = 50,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? const Color(0xFFFF8A50),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(child: _buildAvatarContent()),
    );
  }

  Widget _buildAvatarContent() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAvatar();
        },
      );
    } else {
      return _buildFallbackAvatar();
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: backgroundColor ?? const Color(0xFF404040),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A50)),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    // Use initials or default icon
    final String initials = _getInitials(childName);

    if (initials.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        color: backgroundColor ?? _generateColorFromName(childName),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: size * 0.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        color: backgroundColor ?? const Color(0xFF404040),
        child: Icon(
          Icons.child_care,
          color: textColor ?? const Color(0xFFB0B0B0),
          size: size * 0.5,
        ),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';

    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0].substring(0, 1).toUpperCase() : '';
    } else {
      String first = parts[0].isNotEmpty ? parts[0].substring(0, 1) : '';
      String second = parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
      return (first + second).toUpperCase();
    }
  }

  Color _generateColorFromName(String name) {
    // Generate a consistent color based on the name
    final colors = [
      const Color(0xFFFF8A50), // Orange
      const Color(0xFF50C878), // Green
      const Color(0xFF4FC3F7), // Light Blue
      const Color(0xFFBA68C8), // Purple
      const Color(0xFFFFB74D), // Amber
      const Color(0xFF81C784), // Light Green
      const Color(0xFF64B5F6), // Blue
      const Color(0xFFE57373), // Light Red
      const Color(0xFFFFD54F), // Yellow
      const Color(0xFF9575CD), // Deep Purple
      const Color(0xFFFF6B9D), // Pink
      const Color(0xFF4DB6AC), // Teal
      const Color(0xFFAED581), // Lime
      const Color(0xFFFFB300), // Amber
      const Color(0xFF7986CB), // Indigo
    ];

    int hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
}
