import 'dart:async';

import 'package:flutter/material.dart';
import 'package:weather_app/models/place.dart';
import 'package:weather_app/models/service_result.dart';
import 'package:weather_app/models/weather_forecast.dart';
import 'package:weather_app/services/geocoding_service.dart';
import 'package:weather_app/services/location/location_service.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:weather_app/widgets/current_weather_view.dart';
import 'package:weather_app/widgets/today_weather_view.dart';
import 'package:weather_app/widgets/weekly_weather_view.dart';
import 'package:weather_app/widgets/weather_message_view.dart';

enum _ContentMessageSource { geocoding, weather }

class WeatherPage extends StatefulWidget {
  const WeatherPage({
    super.key,
    this.locationService,
    this.geocodingService,
    this.weatherService,
  });

  final LocationService? locationService;
  final GeocodingService? geocodingService;
  final WeatherService? weatherService;

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;
  late final LocationService _locationService;
  late final GeocodingService _geocodingService;
  late final WeatherService _weatherService;

  WeatherForecast? _weatherForecast;
  String? _fallbackLocationLabel;
  String? _contentMessage;
  ServiceFailure? _contentMessageFailure;
  _ContentMessageSource? _contentMessageSource;
  List<Place> _suggestions = const [];
  bool _isFetchingLocation = false;
  bool _isSearching = false;
  bool _isFetchingWeather = false;
  String? _locationAccessMessage;
  Timer? _searchDebounce;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? createDefaultLocationService();
    _geocodingService =
        widget.geocodingService ?? createDefaultGeocodingService();
    _weatherService = widget.weatherService ?? createDefaultWeatherService();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _searchController.addListener(_onSearchTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _updateSuggestions(query);
    });
  }

  void _setContentMessage({
    required String message,
    required ServiceFailure failure,
    required _ContentMessageSource source,
  }) {
    _contentMessage = message;
    _contentMessageFailure = failure;
    _contentMessageSource = source;
  }

  void _clearContentMessage() {
    _contentMessage = null;
    _contentMessageFailure = null;
    _contentMessageSource = null;
  }

  void _clearContentMessageIfGeocodingConnectionRestored() {
    if (_contentMessageSource == _ContentMessageSource.geocoding &&
        _contentMessageFailure == ServiceFailure.connectionError) {
      _clearContentMessage();
    }
  }

  String _geocodingFailureMessage(ServiceFailure failure) {
    return switch (failure) {
      ServiceFailure.notFound =>
        'No cities found matching your search. Please try a different search term.',
      ServiceFailure.connectionError =>
        'Unable to search cities. Please check your internet connection and try again.',
    };
  }

  String _weatherFailureMessage(ServiceFailure failure) {
    return switch (failure) {
      ServiceFailure.notFound =>
        'No weather data available for this location. Please try a different location.',
      ServiceFailure.connectionError =>
        'Unable to fetch weather data. Please check your internet connection and try again.',
    };
  }

  Future<void> _updateSuggestions(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = const [];
        _isSearching = false;
      });
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() {
      _isSearching = true;
    });

    final result = await _geocodingService.search(trimmedQuery);

    if (!mounted || requestId != _searchRequestId) {
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _suggestions = const [];
        _isSearching = false;
        _setContentMessage(
          message: _geocodingFailureMessage(result.failure!),
          failure: result.failure!,
          source: _ContentMessageSource.geocoding,
        );
      });
      return;
    }

    setState(() {
      _suggestions = result.places!;
      _isSearching = false;
      _clearContentMessageIfGeocodingConnectionRestored();
    });
  }

  Future<void> _applyPlace(Place place) async {
    setState(() {
      _fallbackLocationLabel = null;
      _locationAccessMessage = null;
      _clearContentMessage();
      _suggestions = const [];
      _isFetchingWeather = true;
    });

    final result = await _weatherService.fetchForecast(place);

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _weatherForecast = null;
        _setContentMessage(
          message: _weatherFailureMessage(result.failure!),
          failure: result.failure!,
          source: _ContentMessageSource.weather,
        );
        _isFetchingWeather = false;
      });
      return;
    }

    setState(() {
      _weatherForecast = result.forecast;
      _isFetchingWeather = false;
    });
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isFetchingLocation) {
      return;
    }

    setState(() {
      _isFetchingLocation = true;
    });

    final result = await _locationService.getCurrentLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      _isFetchingLocation = false;
    });

    if (result.isSuccess) {
      final coordinates = result.coordinates!;
      final place = await _geocodingService.reverseGeocode(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      );

      if (!mounted) {
        return;
      }

      if (place != null) {
        _searchController.text = place.name;
        await _applyPlace(place);
        return;
      }

      final coordinatePlace = Place(
        name: coordinates.displayLabel,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      );
      _searchController.text = coordinatePlace.name;
      await _applyPlace(coordinatePlace);
      return;
    }

    _handleLocationFailure(result.failure!);
  }

  void _handleLocationFailure(LocationFailure failure) {
    final message = switch (failure) {
      LocationFailure.serviceDisabled =>
        'Location services are disabled. Search for a city to get the weather.',
      LocationFailure.permissionDenied ||
      LocationFailure.permissionDeniedForever =>
        'Location access denied. Search for a city to get the weather.',
    };

    setState(() {
      _locationAccessMessage = message;
    });
  }

  void _onGeolocationPressed() {
    _fetchCurrentLocation();
  }

  Future<void> _onSearchSubmitted(String value) async {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return;
    }

    final currentSuggestions = List<Place>.from(_suggestions);
    setState(() {
      _suggestions = const [];
    });
    _searchFocusNode.unfocus();

    if (currentSuggestions.isNotEmpty) {
      _searchController.text = currentSuggestions.first.name;
      await _applyPlace(currentSuggestions.first);
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final result = await _geocodingService.search(trimmedValue);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearching = false;
    });

    if (!result.isSuccess) {
      setState(() {
        _weatherForecast = null;
        _setContentMessage(
          message: _geocodingFailureMessage(result.failure!),
          failure: result.failure!,
          source: _ContentMessageSource.geocoding,
        );
      });
      return;
    }

    if (result.places!.isEmpty) {
      setState(() {
        _weatherForecast = null;
        _setContentMessage(
          message: _geocodingFailureMessage(ServiceFailure.notFound),
          failure: ServiceFailure.notFound,
          source: _ContentMessageSource.geocoding,
        );
      });
      return;
    }

    _searchController.text = result.places!.first.name;
    await _applyPlace(result.places!.first);
  }

  Future<void> _onSuggestionSelected(Place place) async {
    _searchController.text = place.name;
    setState(() {
      _suggestions = const [];
    });
    _searchFocusNode.unfocus();
    await _applyPlace(place);
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty && !_isSearching) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: _isSearching && _suggestions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final place = _suggestions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.location_city_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        place.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(place.suggestionSubtitle),
                      onTap: () => _onSuggestionSelected(place),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _isFetchingLocation
                ? 'Getting your location...'
                : 'Loading weather data...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(int index) {
    if (_isFetchingLocation || _isFetchingWeather) {
      return _buildLoadingView();
    }

    if (_contentMessage != null) {
      return WeatherMessageView(message: _contentMessage!);
    }

    return switch (index) {
      0 => CurrentWeatherView(
          forecast: _weatherForecast,
          fallbackLabel: _fallbackLocationLabel,
        ),
      1 => TodayWeatherView(
          forecast: _weatherForecast,
          fallbackLabel: _fallbackLocationLabel,
        ),
      2 => WeeklyWeatherView(
          forecast: _weatherForecast,
          fallbackLabel: _fallbackLocationLabel,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideScreen = screenWidth >= 600;
    final showSuggestions =
        _searchFocusNode.hasFocus && (_suggestions.isNotEmpty || _isSearching);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: isWideScreen ? 24 : 12,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search city...',
            prefixIcon: const Icon(Icons.search),
            contentPadding: EdgeInsets.symmetric(
              vertical: isWideScreen ? 14 : 10,
            ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isWideScreen ? 12 : 4),
            child: IconButton.filledTonal(
              icon: Icon(
                _isFetchingLocation
                    ? Icons.location_searching
                    : Icons.my_location,
                size: isWideScreen ? 26 : 22,
              ),
              tooltip: 'Use current location',
              onPressed: _isFetchingLocation ? null : _onGeolocationPressed,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_locationAccessMessage != null)
                MaterialBanner(
                  content: Text(_locationAccessMessage!),
                  leading: const Icon(Icons.location_off),
                  backgroundColor:
                      Theme.of(context).colorScheme.errorContainer,
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _locationAccessMessage = null;
                        });
                      },
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              if (showSuggestions) _buildSuggestionsList(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(3, _buildTabContent),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: BottomAppBar(
          height: isWideScreen ? 72 : 60,
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 32 : 8,
          ),
          child: TabBar(
            controller: _tabController,
            tabAlignment: TabAlignment.fill,
            labelStyle: TextStyle(
              fontSize: isWideScreen ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isWideScreen ? 14 : 12,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.wb_sunny),
                text: 'Currently',
              ),
              Tab(
                icon: Icon(Icons.today),
                text: 'Today',
              ),
              Tab(
                icon: Icon(Icons.calendar_view_week),
                text: 'Weekly',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
