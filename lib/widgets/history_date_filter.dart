import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryDateFilter extends StatefulWidget {
  final String deviceId;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final List<DateTime> availableDates;

  const HistoryDateFilter({
    Key? key,
    required this.deviceId,
    required this.selectedDate,
    required this.onDateSelected,
    required this.availableDates,
  }) : super(key: key);

  @override
  State<HistoryDateFilter> createState() => _HistoryDateFilterState();
}

class _HistoryDateFilterState extends State<HistoryDateFilter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.1),
            const Color(0xFFFF9800).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(widget.selectedDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Available dates horizontal scroll
          if (widget.availableDates.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.availableDates.length,
                itemBuilder: (context, index) {
                  final date = widget.availableDates[index];
                  final isSelected = _isSameDay(widget.selectedDate, date);
                  final isToday = _isSameDay(DateTime.now(), date);

                  return _buildDateChip(
                    label: DateFormat('MMM dd').format(date),
                    subtitle:
                        isToday ? 'Today' : DateFormat('EEEE').format(date),
                    isSelected: isSelected,
                    onTap: () => widget.onDateSelected(date),
                    isToday: isToday,
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No history points available',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    bool isToday = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF4CAF50)
                    : isToday
                    ? const Color(0xFFFF9800)
                    : Colors.grey.shade300,
            width: isSelected || isToday ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                size: 24,
              )
            else
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected
                          ? Colors.white
                          : isToday
                          ? const Color(0xFFFF9800)
                          : const Color(0xFF1A1A1A),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.9)
                        : Colors.grey.shade600,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
