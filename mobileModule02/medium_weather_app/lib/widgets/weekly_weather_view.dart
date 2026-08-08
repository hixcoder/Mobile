import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_forecast.dart';
import 'package:weather_app/utils/weather_icons.dart';
import 'package:weather_app/widgets/location_header.dart';
import 'package:weather_app/widgets/weather_card.dart';
import 'package:weather_app/widgets/weather_empty_view.dart';

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
      if (fallbackLabel != null && fallbackLabel!.isNotEmpty) {
        return Center(
          child: LocationHeader(
            place: null,
            fallbackLabel: fallbackLabel,
          ),
        );
      }
      return const WeatherEmptyView();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LocationHeader(place: forecast!.place),
        const SizedBox(height: 16),
        ...forecast!.weekly.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WeatherCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    weatherIconForDescription(day.description),
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.formattedDate,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Min: ${day.minTemperatureCelsius.toStringAsFixed(1)} °C | '
                          'Max: ${day.maxTemperatureCelsius.toStringAsFixed(1)} °C',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          day.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
