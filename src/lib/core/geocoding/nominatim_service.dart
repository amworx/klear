import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// A single geocoding result from Nominatim (OSM).
class GeoPlace {
  const GeoPlace({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  final String displayName;
  final double lat;
  final double lng;
}

/// Geocoding service backed by the free OSM Nominatim API.
///
/// Complies with Nominatim's usage policy:
/// - a valid identifying User-Agent,
/// - at most 1 request/second,
/// - no bulk usage.
class NominatimService {
  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'KlearApp/1.0 (contact: amworxx@gmail.com)';

  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  Future<Map<String, String>> _headers() async {
    // Throttle to 1 req/sec as required by Nominatim.
    final elapsed = DateTime.now().difference(_lastRequest);
    if (elapsed < const Duration(seconds: 1)) {
      await Future.delayed(const Duration(seconds: 1) - elapsed);
    }
    _lastRequest = DateTime.now();
    return {
      'User-Agent': _userAgent,
      'Accept-Language': 'ar,en',
    };
  }

  /// Search for places matching [query].
  Future<List<GeoPlace>> search(String query, {int limit = 5}) async {
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': query.trim(),
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '$limit',
    });
    final response =
        await _client.get(uri, headers: await _headers()).timeout(
              const Duration(seconds: 15),
            );
    if (response.statusCode != 200) {
      throw StateError('Nominatim search failed (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return GeoPlace(
            displayName: map['display_name']?.toString() ?? '',
            lat: double.tryParse(map['lat']?.toString() ?? '') ?? 0,
            lng: double.tryParse(map['lon']?.toString() ?? '') ?? 0,
          );
        })
        .where((p) => p.displayName.isNotEmpty)
        .toList();
  }

  /// Reverse-geocode a coordinate into a human-readable address.
  Future<String?> reverse(double lat, double lng) async {
    final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
      'lat': lat.toStringAsFixed(6),
      'lon': lng.toStringAsFixed(6),
      'format': 'jsonv2',
      'addressdetails': '1',
    });
    final response =
        await _client.get(uri, headers: await _headers()).timeout(
              const Duration(seconds: 15),
            );
    if (response.statusCode != 200) return null;
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return map['display_name']?.toString();
  }
}

/// Provider for the Nominatim geocoding service.
final nominatimServiceProvider = Provider<NominatimService>((ref) {
  return NominatimService();
});