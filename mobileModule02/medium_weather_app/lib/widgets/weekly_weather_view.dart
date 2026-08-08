import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_forecast.dart';
import 'package:weather_app/widgets/location_header.dart';

class WeeklyWeatherView extends StatelessWidget {
  const WeeklyWeatherView({
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LocationHeader(place: forecast!.place),
        const SizedBox(height: 16),
        ...forecast!.weekly.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.formattedDate,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Min: ${day.minTemperatureCelsius.toStringAsFixed(1)} °C | '
                  'Max: ${day.maxTemperatureCelsius.toStringAsFixed(1)} °C',
                ),
                Text(day.description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
