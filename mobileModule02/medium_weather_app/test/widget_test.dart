import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/app/weather_app.dart';
import 'package:weather_app/models/current_weather.dart';
import 'package:weather_app/models/daily_weather.dart';
import 'package:weather_app/models/hourly_weather.dart';
import 'package:weather_app/models/place.dart';
import 'package:weather_app/models/service_result.dart';
import 'package:weather_app/models/weather_forecast.dart';
import 'package:weather_app/services/geocoding_service.dart';
import 'package:weather_app/services/location/location_service.dart';
import 'package:weather_app/services/weather_service.dart';

class FakeLocationService implements LocationService {
  FakeLocationService({
    this.result = const LocationResult.success(
      LocationCoordinates(latitude: 48.8566, longitude: 2.3522),
    ),
  });

  final LocationResult result;

  @override
  Future<LocationResult> getCurrentLocation() async => result;
}

class FakeGeocodingService implements GeocodingService {
  FakeGeocodingService({
    this.searchResults = const [],
    this.searchFailure,
    this.reverseResult,
  });

  final List<Place> searchResults;
  final ServiceFailure? searchFailure;
  final Place? reverseResult;
  String? lastSearchQuery;

  @override
  Future<GeocodingSearchResult> search(String query) async {
    lastSearchQuery = query;
    if (searchFailure != null) {
      return GeocodingSearchResult.failure(searchFailure!);
    }
    if (searchResults.isNotEmpty) {
      return GeocodingSearchResult.success(searchResults);
    }
    if (query.toLowerCase().startsWith('pa')) {
      return const GeocodingSearchResult.success([
        Place(
          name: 'Paris',
          region: 'Île-de-France',
          country: 'France',
          latitude: 48.8566,
          longitude: 2.3522,
        ),
      ]);
    }
    return const GeocodingSearchResult.failure(ServiceFailure.notFound);
  }

  @override
  Future<Place?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    return reverseResult ??
        const Place(
          name: 'Paris',
          region: 'Île-de-France',
          country: 'France',
          latitude: 48.8566,
          longitude: 2.3522,
        );
  }
}

class FakeWeatherService implements WeatherService {
  FakeWeatherService({
    this.forecast,
    this.failure,
  });

  Place? lastFetchedPlace;
  final WeatherForecast? forecast;
  final ServiceFailure? failure;

  @override
  Future<WeatherFetchResult> fetchForecast(Place place) async {
    lastFetchedPlace = place;
    if (failure != null) {
      return WeatherFetchResult.failure(failure!);
    }
    return WeatherFetchResult.success(
      forecast ??
          WeatherForecast(
            place: place,
            current: const CurrentWeather(
              temperatureCelsius: 18.5,
              description: 'Partly cloudy',
              windSpeedKmh: 12.3,
            ),
            todayHourly: [
              HourlyWeather(
                time: DateTime(2026, 8, 8, 9),
                temperatureCelsius: 17.0,
                description: 'Clear sky',
                windSpeedKmh: 10.0,
              ),
              HourlyWeather(
                time: DateTime(2026, 8, 8, 12),
                temperatureCelsius: 20.0,
                description: 'Partly cloudy',
                windSpeedKmh: 12.0,
              ),
            ],
            weekly: [
              DailyWeather(
                date: DateTime(2026, 8, 8),
                minTemperatureCelsius: 14.0,
                maxTemperatureCelsius: 22.0,
                description: 'Partly cloudy',
              ),
              DailyWeather(
                date: DateTime(2026, 8, 9),
                minTemperatureCelsius: 15.0,
                maxTemperatureCelsius: 23.0,
                description: 'Clear sky',
              ),
            ],
          ),
    );
  }
}

WeatherApp _buildTestApp({
  LocationService? locationService,
  GeocodingService? geocodingService,
  WeatherService? weatherService,
}) {
  return WeatherApp(
    locationService: locationService ??
        FakeLocationService(
          result: const LocationResult.failure(
            LocationFailure.permissionDenied,
          ),
        ),
    geocodingService: geocodingService ?? FakeGeocodingService(),
    weatherService: weatherService ?? FakeWeatherService(),
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 50,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Expected to find widget: $finder');
}

void main() {
  testWidgets('AppBar shows search field and geolocation button',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(TabBarView), findsOneWidget);
    expect(find.text('Currently'), findsWidgets);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
  });

  testWidgets('Search updates all tabs with resolved city details',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(
      tester,
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.textContaining('Paris'),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.textContaining('Île-de-France'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.textContaining('France'),
      ),
      findsOneWidget,
    );
    expect(find.text('Currently Paris'), findsNothing);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.textContaining('Paris'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.textContaining('Paris'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Typing shows city suggestions with region and country',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Pa');
    await tester.pump(const Duration(milliseconds: 350));
    await _pumpUntilFound(tester, find.text('Paris'));
    expect(find.text('Île-de-France, France'), findsOneWidget);
  });

  testWidgets('Selecting a suggestion resolves the city in all tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Pa');
    await tester.pump(const Duration(milliseconds: 350));
    await _pumpUntilFound(tester, find.text('Paris'));

    await tester.tap(find.text('Paris'));
    await _pumpUntilFound(
      tester,
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.textContaining('France'),
      ),
    );
  });

  testWidgets('Geolocation resolves to city name when reverse geocoding works',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        locationService: FakeLocationService(
          result: const LocationResult.success(
            LocationCoordinates(latitude: 48.8566, longitude: 2.3522),
          ),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.textContaining('Paris'),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.textContaining('France'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('App requests location on startup', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        locationService: FakeLocationService(
          result: const LocationResult.success(
            LocationCoordinates(latitude: 40.7128, longitude: -74.0060),
          ),
        ),
        geocodingService: FakeGeocodingService(
          reverseResult: const Place(
            name: 'New York',
            region: 'New York',
            country: 'United States',
            latitude: 40.7128,
            longitude: -74.0060,
          ),
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.textContaining('New York'),
      ),
    );
  });

  testWidgets('Denied location shows access message', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Location access denied'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsOneWidget);
  });

  testWidgets('Swiping switches between tabs', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TabBarView), findsOneWidget);

    final tabBarViewSize = tester.getSize(find.byType(TabBarView));
    await tester.drag(
      find.byType(TabBarView),
      Offset(-tabBarViewSize.width, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final tabController =
        tester.widget<TabBarView>(find.byType(TabBarView)).controller!;
    expect(tabController.index, 1);
  });

  testWidgets('Invalid city search shows error in all tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'NotACity123');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(
      tester,
      find.textContaining('No cities found matching your search'),
    );

    expect(find.text('18.5 °C'), findsNothing);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No cities found matching your search'),
      findsOneWidget,
    );

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No cities found matching your search'),
      findsOneWidget,
    );
  });

  testWidgets('Geocoding connection error shows message in tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        geocodingService: FakeGeocodingService(
          searchFailure: ServiceFailure.connectionError,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(
      tester,
      find.textContaining('Unable to search cities'),
    );
  });

  testWidgets('Weather connection error shows message in tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        weatherService: FakeWeatherService(
          failure: ServiceFailure.connectionError,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(
      tester,
      find.textContaining('Unable to fetch weather data'),
    );
  });

  testWidgets('Long error message wraps to multiple lines',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    const longCityName =
        'Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch';
    await tester.enterText(find.byType(TextField), longCityName);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(
      tester,
      find.textContaining('No cities found matching your search'),
    );

    final errorTextFinder = find.descendant(
      of: find.byType(TabBarView),
      matching: find.textContaining('No cities found matching your search'),
    );
    expect(errorTextFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(errorTextFinder);
    expect(textWidget.softWrap, isTrue);
    expect(textWidget.maxLines, 6);
  });

  testWidgets('Currently tab shows temperature, description, and wind',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(tester, find.text('18.5 °C'));

    expect(find.text('Partly cloudy'), findsOneWidget);
    expect(find.text('Wind: 12.3 km/h'), findsOneWidget);
  });

  testWidgets('Today tab shows hourly forecast entries',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(tester, find.text('18.5 °C'));

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('17.0 °C'), findsOneWidget);
    expect(find.text('20.0 °C'), findsOneWidget);
    expect(find.text('Clear sky'), findsOneWidget);
    expect(find.text('Wind: 10.0 km/h'), findsOneWidget);
  });

  testWidgets('Weekly tab shows daily min and max temperatures',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(tester, find.text('18.5 °C'));

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.text('2026-08-08'), findsOneWidget);
    expect(find.text('2026-08-09'), findsOneWidget);
    expect(find.text('Min: 14.0 °C | Max: 22.0 °C'), findsOneWidget);
    expect(find.text('Min: 15.0 °C | Max: 23.0 °C'), findsOneWidget);
  });

  testWidgets('Search keeps the active tab instead of resetting it',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(tester, find.text('2026-08-08'));

    final tabController =
        tester.widget<TabBarView>(find.byType(TabBarView)).controller!;
    expect(tabController.index, 2);
  });

  testWidgets('LayoutBuilder adapts tab content to screen width',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _pumpUntilFound(tester, find.text('18.5 °C'));

    expect(find.byType(LayoutBuilder), findsWidgets);
  });
}
