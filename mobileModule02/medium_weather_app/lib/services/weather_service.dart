import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:weather_app/models/current_weather.dart';
import 'package:weather_app/models/daily_weather.dart';
import 'package:weather_app/models/hourly_weather.dart';
import 'package:weather_app/models/place.dart';
import 'package:weather_app/models/weather_forecast.dart';
import 'package:weather_app/utils/weather_code.dart';

abstract interface class WeatherService {
  Future<WeatherForecast?> fetchForecast(Place place);
}

class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  Future<WeatherForecast?> fetchForecast(Place place) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': place.latitude.toString(),
        'longitude': place.longitude.toString(),
        'current': 'temperature_2m,weather_code,wind_speed_10m',
        'hourly': 'temperature_2m,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
        'forecast_days': '7',
        'wind_speed_unit': 'kmh',
        'temperature_unit': 'celsius',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['error'] == true) {
      return null;
    }

    return _parseForecast(place, data);
  }

  WeatherForecast _parseForecast(Place place, Map<String, dynamic> data) {
    final currentData = data['current'] as Map<String, dynamic>;
    final currentTime = DateTime.parse(currentData['time'] as String);
    final current = CurrentWeather(
      temperatureCelsius: (currentData['temperature_2m'] as num).toDouble(),
      description: weatherDescription(currentData['weather_code'] as int),
      windSpeedKmh: (currentData['wind_speed_10m'] as num).toDouble(),
    );

    final hourlyData = data['hourly'] as Map<String, dynamic>;
    final hourlyTimes = (hourlyData['time'] as List).cast<String>();
    final hourlyTemperatures =
        (hourlyData['temperature_2m'] as List).cast<num>();
    final hourlyCodes = (hourlyData['weather_code'] as List).cast<int>();
    final hourlyWind =
        (hourlyData['wind_speed_10m'] as List).cast<num>();

    final todayHourly = <HourlyWeather>[];
    for (var i = 0; i < hourlyTimes.length; i++) {
      final time = DateTime.parse(hourlyTimes[i]);
      if (!_isSameDay(time, currentTime)) {
        continue;
      }

      todayHourly.add(
        HourlyWeather(
          time: time,
          temperatureCelsius: hourlyTemperatures[i].toDouble(),
          description: weatherDescription(hourlyCodes[i]),
          windSpeedKmh: hourlyWind[i].toDouble(),
        ),
      );
    }

    final dailyData = data['daily'] as Map<String, dynamic>;
    final dailyTimes = (dailyData['time'] as List).cast<String>();
    final dailyMin = (dailyData['temperature_2m_min'] as List).cast<num>();
    final dailyMax = (dailyData['temperature_2m_max'] as List).cast<num>();
    final dailyCodes = (dailyData['weather_code'] as List).cast<int>();

    final weekly = <DailyWeather>[];
    for (var i = 0; i < dailyTimes.length; i++) {
      weekly.add(
        DailyWeather(
          date: DateTime.parse(dailyTimes[i]),
          minTemperatureCelsius: dailyMin[i].toDouble(),
          maxTemperatureCelsius: dailyMax[i].toDouble(),
          description: weatherDescription(dailyCodes[i]),
        ),
      );
    }

    return WeatherForecast(
      place: place,
      current: current,
      todayHourly: todayHourly,
      weekly: weekly,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

WeatherService createDefaultWeatherService() => OpenMeteoWeatherService();
