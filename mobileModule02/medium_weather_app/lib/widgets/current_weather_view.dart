import 'package:flutter/material.dart';
import 'package:weather_app/models/weather_forecast.dart';
import 'package:weather_app/utils/weather_icons.dart';
import 'package:weather_app/widgets/location_header.dart';
import 'package:weather_app/widgets/weather_card.dart';
import 'package:weather_app/widgets/weather_empty_view.dart';

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

    final current = forecast!.current;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 600 ? 32.0 : 16.0;

        return ListView(
          padding: EdgeInsets.all(padding),
          children: [
            LocationHeader(place: forecast!.place),
            const SizedBox(height: 20),
            WeatherCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  Icon(
                    weatherIconForDescription(current.description),
                    size: 72,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${current.temperatureCelsius.toStringAsFixed(1)} °C',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w300,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    current.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.air,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Wind: ${current.windSpeedKmh.toStringAsFixed(1)} km/h',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
