import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../services/location_history_service.dart';
import '../widgets/history_date_filter.dart';

class LocationHistoryScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const LocationHistoryScreen({
    Key? key,
    required this.deviceId,
    required this.deviceName,
  }) : super(key: key);

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  final MapController _mapController = MapController();

  late DateTime _selectedDate;
  List<DateTime> _availableDates = [];
  List<Map<String, dynamic>> _historyPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // Load available dates
    final dates = await LocationHistoryService.getAvailableDates(
      widget.deviceId,
    );
    setState(() {
      _availableDates = dates;
      _isLoading = false;
    });

    // Select today's date if available, otherwise select the most recent date
    if (dates.isNotEmpty) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (dates.any(
        (d) =>
            d.year == todayDate.year &&
            d.month == todayDate.month &&
            d.day == todayDate.day,
      )) {
        await _loadHistory(todayDate);
      } else {
        await _loadHistory(dates.first);
      }
    }
  }

  Future<void> _loadHistory(DateTime date) async {
    setState(() => _isLoading = true);

    final history = await LocationHistoryService.getHistoryForDate(
      widget.deviceId,
      date,
    );

    setState(() {
      _historyPoints = history;
      _selectedDate = date;
      _isLoading = false;
    });

    // Center map on first point if available
    if (_historyPoints.isNotEmpty) {
      final firstPoint = _historyPoints.first;
      final lat = firstPoint['latitude'] as double;
      final long = firstPoint['longitude'] as double;
      _mapController.move(LatLng(lat, long), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.deviceName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Location History',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showStatsDialog(),
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date filter
          HistoryDateFilter(
            deviceId: widget.deviceId,
            selectedDate: _selectedDate,
            onDateSelected: _loadHistory,
            availableDates: _availableDates,
          ),

          // Stats bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.location_on_rounded,
                  label: 'Points',
                  value: '${_historyPoints.length}',
                  color: const Color(0xFF4CAF50),
                ),
                _buildStatItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Days',
                  value: '${_availableDates.length}',
                  color: const Color(0xFFFF9800),
                ),
                if (_historyPoints.isNotEmpty)
                  _buildStatItem(
                    icon: Icons.access_time_rounded,
                    label: 'Duration',
                    value: _calculateDuration(),
                    color: const Color(0xFF2196F3),
                  ),
              ],
            ),
          ),

          // Map
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _historyPoints.isEmpty
                    ? _buildEmptyState()
                    : _buildMap(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildMap() {
    // Create polyline points
    final polylinePoints =
        _historyPoints
            .map(
              (point) => LatLng(
                point['latitude'] as double,
                point['longitude'] as double,
              ),
            )
            .toList();

    // Create markers for significant points (first, last, and every 10th point)
    final markers = <Marker>[];
    for (int i = 0; i < _historyPoints.length; i++) {
      final point = _historyPoints[i];
      final isFirst = i == 0;
      final isLast = i == _historyPoints.length - 1;
      final isSignificant = i % 10 == 0;

      if (isFirst || isLast || isSignificant) {
        markers.add(
          Marker(
            point: LatLng(
              point['latitude'] as double,
              point['longitude'] as double,
            ),
            width: isFirst || isLast ? 40 : 30,
            height: isFirst || isLast ? 40 : 30,
            builder:
                (context) => GestureDetector(
                  onTap: () => _showPointDetails(point, isFirst, isLast),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isFirst
                              ? Colors.green
                              : isLast
                              ? Colors.red
                              : Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isFirst
                          ? Icons.play_arrow_rounded
                          : isLast
                          ? Icons.flag_rounded
                          : Icons.circle,
                      color: Colors.white,
                      size: isFirst || isLast ? 20 : 12,
                    ),
                  ),
                ),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center:
                polylinePoints.isNotEmpty ? polylinePoints.first : LatLng(0, 0),
            zoom: 15,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.safespot.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polylinePoints,
                  strokeWidth: 3,
                  color: const Color(0xFF2196F3),
                  gradientColors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF2196F3),
                    const Color(0xFFFF9800),
                  ],
                ),
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No history points',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No history for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    if (_historyPoints.length < 2) return '0h';

    final first = DateTime.parse(_historyPoints.last['timestamp'] as String);
    final last = DateTime.parse(_historyPoints.first['timestamp'] as String);
    final duration = last.difference(first);

    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  void _showPointDetails(
    Map<String, dynamic> point,
    bool isFirst,
    bool isLast,
  ) {
    final timestamp = DateTime.parse(point['timestamp'] as String);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            isFirst
                                ? Colors.green.withOpacity(0.1)
                                : isLast
                                ? Colors.red.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isFirst
                            ? Icons.play_arrow_rounded
                            : isLast
                            ? Icons.flag_rounded
                            : Icons.location_on_rounded,
                        color:
                            isFirst
                                ? Colors.green
                                : isLast
                                ? Colors.red
                                : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFirst
                                ? 'Start Point'
                                : isLast
                                ? 'End Point'
                                : 'Waypoint',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • HH:mm:ss',
                            ).format(timestamp),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.map_rounded,
                  'Latitude',
                  '${point['latitude'].toStringAsFixed(6)}°',
                ),
                _buildDetailRow(
                  Icons.map_rounded,
                  'Longitude',
                  '${point['longitude'].toStringAsFixed(6)}°',
                ),
                if (point['accuracy'] != null)
                  _buildDetailRow(
                    Icons.gps_fixed_rounded,
                    'Accuracy',
                    '±${point['accuracy']}m',
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showStatsDialog() async {
    final stats = await LocationHistoryService.getDateRangeStats(
      widget.deviceId,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.insights_rounded, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text('History Statistics'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Total Points', '${_historyPoints.length}'),
                _buildStatRow('Available Days', '${_availableDates.length}'),
                if (stats['oldest'] != null)
                  _buildStatRow(
                    'First Record',
                    DateFormat('MMM dd, yyyy').format(stats['oldest']),
                  ),
                if (stats['newest'] != null)
                  _buildStatRow(
                    'Last Record',
                    DateFormat('MMM dd, yyyy').format(stats['newest']),
                  ),
                if (stats['totalDays'] > 0)
                  _buildStatRow('Total Days Tracked', '${stats['totalDays']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
