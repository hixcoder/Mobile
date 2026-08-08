import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_forecast.dart';
import 'package:weather_app/widgets/location_header.dart';

class CurrentWeatherView extends StatelessWidget {
  const CurrentWeatherView({
    super.key,
    required this.forecast,
    this.fallbackLabel,
  });

  final WeatherForecast? forecast;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    if (forecast == null) {
      return Center(
        child: LocationHeader(
          place: null,
          fallbackLabel: fallbackLabel,
        ),
      );
    }

    final current = forecast!.current;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 600 ? 32.0 : 16.0;

        return ListView(
          padding: EdgeInsets.all(padding),
          children: [
            LocationHeader(place: forecast!.place),
            const SizedBox(height: 16),
            Text(
              '${current.temperatureCelsius.toStringAsFixed(1)} °C',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              current.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Wind: ${current.windSpeedKmh.toStringAsFixed(1)} km/h',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        );
      },
    );
  }
}
