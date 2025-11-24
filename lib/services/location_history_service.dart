import 'package:supabase_flutter/supabase_flutter.dart';

class LocationHistoryService {
  static final _supabase = Supabase.instance.client;

  /// Get all unique dates that have location history for a device
  static Future<List<DateTime>> getAvailableDates(String deviceId) async {
    try {
      final response = await _supabase
          .from('location_history')
          .select('timestamp')
          .eq('device_id', deviceId)
          .order('timestamp', ascending: false);

      if (response == null) return [];

      // Extract unique dates (ignoring time)
      final Set<String> uniqueDates = {};
      final List<DateTime> dates = [];

      for (var item in response) {
        final timestamp = DateTime.parse(item['timestamp'] as String);
        final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';

        if (!uniqueDates.contains(dateKey)) {
          uniqueDates.add(dateKey);
          dates.add(DateTime(timestamp.year, timestamp.month, timestamp.day));
        }
      }

      return dates;
    } catch (e) {
      print('❌ Error fetching available dates: $e');
      return [];
    }
  }

  /// Get location history for a specific date
  static Future<List<Map<String, dynamic>>> getHistoryForDate(
    String deviceId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('location_history')
          .select('*')
          .eq('device_id', deviceId)
          .gte('timestamp', startOfDay.toIso8601String())
          .lt('timestamp', endOfDay.toIso8601String())
          .order('timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('❌ Error fetching history for date: $e');
      return [];
    }
  }

  /// Get all location history (no date filter)
  static Future<List<Map<String, dynamic>>> getAllHistory(
    String deviceId, {
    int limit = 2000,
  }) async {
    try {
      final response = await _supabase
          .from('location_history')
          .select('*')
          .eq('device_id', deviceId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('❌ Error fetching all history: $e');
      return [];
    }
  }

  /// Get date range statistics
  static Future<Map<String, dynamic>> getDateRangeStats(String deviceId) async {
    try {
      final response = await _supabase
          .from('location_history')
          .select('timestamp')
          .eq('device_id', deviceId)
          .order('timestamp', ascending: true)
          .limit(1);

      final responseLatest = await _supabase
          .from('location_history')
          .select('timestamp')
          .eq('device_id', deviceId)
          .order('timestamp', ascending: false)
          .limit(1);

      if (response.isEmpty || responseLatest.isEmpty) {
        return {'oldest': null, 'newest': null, 'totalDays': 0};
      }

      final oldest = DateTime.parse(response.first['timestamp'] as String);
      final newest = DateTime.parse(
        responseLatest.first['timestamp'] as String,
      );
      final totalDays = newest.difference(oldest).inDays + 1;

      return {'oldest': oldest, 'newest': newest, 'totalDays': totalDays};
    } catch (e) {
      print('❌ Error fetching date range stats: $e');
      return {'oldest': null, 'newest': null, 'totalDays': 0};
    }
  }
}
