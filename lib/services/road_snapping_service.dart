/// Road Snapping Service
/// Snaps GPS coordinates to actual roads using OSRM Map Matching API
library;

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Service for snapping GPS coordinates to road networks
class RoadSnappingService {
  final String baseUrl;

  /// OSRM public demo server (for production, host your own or use Mapbox/Google)
  RoadSnappingService({this.baseUrl = 'https://router.project-osrm.org'});

  /// Snap location history points to roads
  ///
  /// [points] - List of GPS coordinates to snap
  /// [profile] - Travel mode: 'walking', 'driving', or 'cycling'
  /// Returns list of coordinates snapped to roads
  Future<List<LatLng>> snapToRoad({
    required List<LatLng> points,
    String profile = 'walking',
  }) async {
    if (points.length < 2) {
      print('⚠️ Need at least 2 points for road snapping');
      return points;
    }

    print('🗺️ Snapping ${points.length} points to roads ($profile)...');

    // OSRM accepts up to ~100 coordinates per request
    const maxPerRequest = 100;
    final chunks = <List<LatLng>>[];

    for (var i = 0; i < points.length; i += maxPerRequest) {
      final end =
          (i + maxPerRequest < points.length)
              ? i + maxPerRequest
              : points.length;
      chunks.add(points.sublist(i, end));
    }

    final matchedAll = <LatLng>[];

    for (var c = 0; c < chunks.length; c++) {
      final chunk = chunks[c];

      try {
        final matched = await _snapChunk(chunk, profile);

        // Avoid duplicate points at chunk boundaries
        if (matchedAll.isNotEmpty && matched.isNotEmpty) {
          if (_distance(matchedAll.last, matched.first) < 1.0) {
            matched.removeAt(0);
          }
        }

        matchedAll.addAll(matched);
      } catch (e) {
        print('⚠️ Failed to snap chunk $c: $e');
        // Fallback to raw coordinates
        matchedAll.addAll(chunk);
      }
    }

    print('✅ Snapped to ${matchedAll.length} road points');
    return matchedAll;
  }

  /// Snap a single chunk of coordinates
  Future<List<LatLng>> _snapChunk(List<LatLng> chunk, String profile) async {
    // Build coordinate string: "lon,lat;lon,lat;..."
    final coords = chunk.map((p) => '${p.longitude},${p.latitude}').join(';');

    final url = Uri.parse(
      '$baseUrl/match/v1/$profile/$coords'
      '?geometries=polyline6&overview=full&tidy=true',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('OSRM API returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final matchings = (data['matchings'] as List?) ?? [];

    if (matchings.isEmpty) {
      throw Exception('No road matches found');
    }

    // Sort by confidence (highest first)
    matchings.sort((a, b) {
      final confA = (a['confidence'] ?? 0) as num;
      final confB = (b['confidence'] ?? 0) as num;
      return confB.compareTo(confA);
    });

    // Use best match
    final geometry = matchings.first['geometry'] as String;
    final confidence = (matchings.first['confidence'] ?? 0) as num;

    print(
      '   📍 Matched ${chunk.length} → road (confidence: ${(confidence * 100).toStringAsFixed(1)}%)',
    );

    return _decodePolyline6(geometry);
  }

  /// Decode Google Polyline6 format (precision 1e-6)
  List<LatLng> _decodePolyline6(String encoded) {
    final result = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int resultLat = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        resultLat |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dLat =
          ((resultLat & 1) != 0) ? ~(resultLat >> 1) : (resultLat >> 1);
      lat += dLat;

      shift = 0;
      int resultLng = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        resultLng |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dLng =
          ((resultLng & 1) != 0) ? ~(resultLng >> 1) : (resultLng >> 1);
      lng += dLng;

      result.add(LatLng(lat / 1e6, lng / 1e6));
    }

    return result;
  }

  /// Calculate distance between two points (meters)
  double _distance(LatLng a, LatLng b) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final h =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2));

    return 2 * R * asin(min(1.0, sqrt(h)));
  }

  double _deg2rad(double degrees) => degrees * (pi / 180.0);
}

/// Cache for snapped paths to avoid re-snapping
class SnappedPathCache {
  final Map<String, List<LatLng>> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  final Duration _ttl = const Duration(hours: 24);

  /// Get cached path or return null
  List<LatLng>? get(String key) {
    if (!_cache.containsKey(key)) return null;

    final timestamp = _timestamps[key]!;
    if (DateTime.now().difference(timestamp) > _ttl) {
      _cache.remove(key);
      _timestamps.remove(key);
      return null;
    }

    return _cache[key];
  }

  /// Store path in cache
  void set(String key, List<LatLng> path) {
    _cache[key] = path;
    _timestamps[key] = DateTime.now();
  }

  /// Clear cache
  void clear() {
    _cache.clear();
    _timestamps.clear();
  }

  /// Generate cache key from points
  static String generateKey(List<LatLng> points, String profile) {
    if (points.isEmpty) return '';

    // Use first, middle, and last points + profile as key
    final first = points.first;
    final last = points.last;
    final middle = points[points.length ~/ 2];

    return '$profile:${first.latitude},${first.longitude}:'
        '${middle.latitude},${middle.longitude}:'
        '${last.latitude},${last.longitude}:${points.length}';
  }
}
