import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_forecast.dart';
import 'package:weather_app/widgets/location_header.dart';

class TodayWeatherView extends StatelessWidget {
  const TodayWeatherView({
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
        ...forecast!.todayHourly.map(
          (hour) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hour.formattedTime,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${hour.temperatureCelsius.toStringAsFixed(1)} °C'),
                Text(hour.description),
                Text('Wind: ${hour.windSpeedKmh.toStringAsFixed(1)} km/h'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
