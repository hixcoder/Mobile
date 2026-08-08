import 'package:flutter/material.dart';
import 'package:weather_app/app/app_theme.dart';
import 'package:weather_app/pages/weather_page.dart';
import 'package:weather_app/services/geocoding_service.dart';
import 'package:weather_app/services/location/location_service.dart';
import 'package:weather_app/services/weather_service.dart';

class WeatherApp extends StatelessWidget {
  const WeatherApp({
    super.key,
    this.locationService,
    this.geocodingService,
    this.weatherService,
  });

  final LocationService? locationService;
  final GeocodingService? geocodingService;
  final WeatherService? weatherService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: WeatherPage(
        locationService: locationService,
        geocodingService: geocodingService,
        weatherService: weatherService,
      ),
    );
  }
}
