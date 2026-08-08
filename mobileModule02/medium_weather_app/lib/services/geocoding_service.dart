import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:weather_app/models/place.dart';

abstract interface class GeocodingService {
  Future<List<Place>> search(String query);

  Future<Place?> reverseGeocode({
    required double latitude,
    required double longitude,
  });
}

class OpenMeteoGeocodingService implements GeocodingService {
  OpenMeteoGeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _searchBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  Future<List<Place>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return const [];
    }

    final uri = Uri.parse(_searchBaseUrl).replace(
      queryParameters: {
        'name': trimmedQuery,
        'count': '10',
        'language': 'en',
        'format': 'json',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return const [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'];
    if (results is! List) {
      return const [];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(Place.fromJson)
        .where((place) => place.name.isNotEmpty)
        .toList();
  }

  @override
  Future<Place?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final timezone = await _fetchTimezone(latitude, longitude);
    if (timezone == null) {
      return null;
    }

    final cityHint = timezone.split('/').last.replaceAll('_', ' ');
    final candidates = await search(cityHint);
    if (candidates.isEmpty) {
      return null;
    }

    return candidates.reduce(
      (closest, candidate) =>
          _distance(latitude, longitude, candidate.latitude, candidate.longitude) <
                  _distance(
                    latitude,
                    longitude,
                    closest.latitude,
                    closest.longitude,
                  )
              ? candidate
              : closest,
    );
  }

  Future<String?> _fetchTimezone(double latitude, double longitude) async {
    final uri = Uri.parse(_forecastBaseUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m',
        'timezone': 'auto',
        'forecast_days': '1',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['timezone'] as String?;
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRadians(double value) => value * pi / 180;
}

GeocodingService createDefaultGeocodingService() => OpenMeteoGeocodingService();
