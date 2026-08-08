import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_forecast.dart';
import 'package:weather_app/utils/weather_icons.dart';
import 'package:weather_app/widgets/location_header.dart';
import 'package:weather_app/widgets/weather_card.dart';
import 'package:weather_app/widgets/weather_empty_view.dart';

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
        ...forecast!.todayHourly.map(
          (hour) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WeatherCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      hour.formattedTime,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    weatherIconForDescription(hour.description),
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${hour.temperatureCelsius.toStringAsFixed(1)} °C',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          hour.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          'Wind: ${hour.windSpeedKmh.toStringAsFixed(1)} km/h',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
