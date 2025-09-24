import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_spot/services/geofence_service.dart';

class MapLegendPanel extends StatefulWidget {
  final Position? currentPosition;
  final List<Geofence> geofences;
  final BoxConstraints constraints;

  const MapLegendPanel({
    Key? key,
    required this.currentPosition,
    required this.geofences,
    required this.constraints,
  }) : super(key: key);

  @override
  State<MapLegendPanel> createState() => _MapLegendPanelState();
}

class _MapLegendPanelState extends State<MapLegendPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 12,
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: widget.constraints.maxWidth > 300 ? 200 : widget.constraints.maxWidth - 100,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompactHeader(context),
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      ..._buildCompactLegendItems(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.map_outlined,
            size: 12,
            color: Colors.orange.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Legend',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 250),
          child: Icon(
            Icons.expand_more,
            size: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCompactLegendItems(BuildContext context) {
    List<Widget> items = [
      _buildCompactLegendItem(
        Icons.radio_button_unchecked,
        'History',
        Colors.blue.shade400,
        context,
      ),
      const SizedBox(height: 8),
      _buildCompactLegendItem(
        Icons.smartphone,
        'Device',
        Colors.green.shade500,
        context,
      ),
    ];

    if (widget.currentPosition != null) {
      items.addAll([
        const SizedBox(height: 8),
        _buildCompactLegendItem(
          Icons.my_location,
          'You',
          Colors.blue.shade600,
          context,
        ),
      ]);
    }

    if (widget.geofences.isNotEmpty) {
      items.addAll([
        const SizedBox(height: 8),
        _buildCompactLegendItem(
          Icons.layers_outlined,
          'Geofences',
          Colors.orange.shade500,
          context,
        ),
      ]);
    }

    items.addAll([
      const SizedBox(height: 8),
      _buildCompactPathLegend(context),
    ]);

    return items;
  }

  Widget _buildCompactLegendItem(IconData icon, String label, Color color, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 10,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPathLegend(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Path',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}