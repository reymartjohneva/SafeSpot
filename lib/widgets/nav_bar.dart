import 'package:flutter/material.dart';

class ModernNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Row(
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.home_filled,
              label: 'Home',
              index: 0,
              isActive: currentIndex == 0,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.info_rounded,
              label: 'Information',
              index: 1,
              isActive: currentIndex == 1,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.notifications_rounded,
              label: 'Notification',
              index: 2,
              isActive: currentIndex == 2,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.person_rounded,
              label: 'Profile',
              index: 3,
              isActive: currentIndex == 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Active background circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: isActive ? 50 : 0,
                    height: isActive ? 50 : 0,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Icon with bounce animation
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isActive ? 1.1 : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isActive ? primaryColor : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Label with fade animation
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isActive ? 12 : 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? primaryColor : Colors.grey.shade600,
                ),
                child: Text(label),
              ),
              // Active indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                margin: const EdgeInsets.only(top: 2),
                width: isActive ? 6 : 0,
                height: isActive ? 6 : 0,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}