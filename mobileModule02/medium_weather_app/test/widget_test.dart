import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/location_service.dart';
import 'package:weather_app/main.dart';

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

void main() {
  testWidgets('AppBar shows search field and geolocation button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      WeatherApp(
        locationService: FakeLocationService(
          result: const LocationResult.failure(
            LocationFailure.permissionDenied,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

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

  testWidgets('Search updates all tabs with entered text on a new line',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      WeatherApp(
        locationService: FakeLocationService(
          result: const LocationResult.failure(
            LocationFailure.permissionDenied,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Currently'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.text('Paris'),
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
        matching: find.text('Paris'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.text('Paris'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Geolocation button updates all tabs with coordinates',
      (WidgetTester tester) async {
    const coordinates = LocationCoordinates(
      latitude: 48.8566,
      longitude: 2.3522,
    );

    await tester.pumpWidget(
      WeatherApp(
        locationService: FakeLocationService(
          result: LocationResult.success(coordinates),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pumpAndSettle();

    expect(find.text('Currently'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.text(coordinates.displayLabel),
      ),
      findsOneWidget,
    );
    expect(find.text('Currently ${coordinates.displayLabel}'), findsNothing);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.text(coordinates.displayLabel),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.text(coordinates.displayLabel),
      ),
      findsOneWidget,
    );
  });

  testWidgets('App requests location on startup', (WidgetTester tester) async {
    const coordinates = LocationCoordinates(
      latitude: 40.7128,
      longitude: -74.0060,
    );

    await tester.pumpWidget(
      WeatherApp(
        locationService: FakeLocationService(
          result: LocationResult.success(coordinates),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(TabBarView),
        matching: find.text(coordinates.displayLabel),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Denied location shows access message', (WidgetTester tester) async {
    await tester.pumpWidget(
      WeatherApp(
        locationService: FakeLocationService(
          result: const LocationResult.failure(
            LocationFailure.permissionDenied,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Location access denied'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsOneWidget);
  });

  testWidgets('Swiping switches between tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      WeatherApp(
        locationService: FakeLocationService(
          result: const LocationResult.failure(
            LocationFailure.permissionDenied,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBarView), findsOneWidget);

    await tester.drag(find.byType(TabBarView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    final tabController =
        tester.widget<TabBarView>(find.byType(TabBarView)).controller!;
    expect(tabController.index, 1);
  });

  testWidgets('Long search text wraps to multiple lines',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      WeatherApp(
        locationService: FakeLocationService(
          result: const LocationResult.failure(
            LocationFailure.permissionDenied,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const longCityName =
        'Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch';
    await tester.enterText(find.byType(TextField), longCityName);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final locationTextFinder = find.descendant(
      of: find.byType(TabBarView),
      matching: find.text(longCityName),
    );
    expect(locationTextFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(locationTextFinder);
    expect(textWidget.softWrap, isTrue);
    expect(textWidget.maxLines, 4);

    final renderParagraph = tester.renderObject<RenderParagraph>(
      locationTextFinder,
    );
    expect(renderParagraph.size.height, greaterThan(30));
  });

  testWidgets('LayoutBuilder adapts tab content to screen width',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      WeatherApp(
        locationService: FakeLocationService(
          result: const LocationResult.failure(
            LocationFailure.permissionDenied,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LayoutBuilder), findsWidgets);
  });
}
