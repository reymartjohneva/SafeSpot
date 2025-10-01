import 'package:flutter/material.dart';
import 'package:safe_spot/screens/notification_components/notification_colors.dart';

class NotificationFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const NotificationFilterChips({
    Key? key,
    required this.selectedFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  static final List<Map<String, dynamic>> filters = [
    {'label': 'All', 'value': 'all', 'icon': Icons.inbox},
    {'label': 'Entry', 'value': 'geofence_entry', 'icon': Icons.login},
    {'label': 'Exit', 'value': 'geofence_exit', 'icon': Icons.logout},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : NotificationColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(filter['label'] as String),
                  ],
                ),
                onSelected: (selected) {
                  if (selected) onFilterChanged(filter['value'] as String);
                },
                backgroundColor: NotificationColors.surfaceColor,
                selectedColor: NotificationColors.primaryOrange,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : NotificationColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}