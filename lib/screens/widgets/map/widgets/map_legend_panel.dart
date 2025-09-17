import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_spot/services/geofence_service.dart';

class MapLegendPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth > 400 ? 280 : constraints.maxWidth - 120,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendHeader(context),
                const SizedBox(height: 16),
                ..._buildLegendItems(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.map_outlined,
            size: 16,
            color: Colors.orange.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Map Legend',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLegendItems(BuildContext context) {
    List<Widget> items = [
      _buildLegendItem(
        Icons.radio_button_unchecked,
        'Historical points',
        Colors.blue.shade400,
        context,
      ),
      const SizedBox(height: 12),
      _buildLegendItem(
        Icons.smartphone,
        'Device location',
        Colors.green.shade500,
        context,
      ),
    ];

    if (currentPosition != null) {
      items.addAll([
        const SizedBox(height: 12),
        _buildLegendItem(
          Icons.my_location,
          'Your location',
          Colors.blue.shade600,
          context,
        ),
      ]);
    }

    if (geofences.isNotEmpty) {
      items.addAll([
        const SizedBox(height: 12),
        _buildLegendItem(
          Icons.layers_outlined,
          'Geofences',
          Colors.orange.shade500,
          context,
        ),
      ]);
    }

    items.addAll([
      const SizedBox(height: 12),
      _buildMovementPathLegend(context),
    ]);

    return items;
  }

  Widget _buildLegendItem(IconData icon, String label, Color color, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMovementPathLegend(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Movement path',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}