import 'dart:async';

import 'package:flutter/material.dart';
import 'package:weather_app/models/place.dart';
import 'package:weather_app/services/geocoding_service.dart';
import 'package:weather_app/services/location/location_service.dart';
import 'package:weather_app/services/weather_service.dart';

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

  String? _locationSource;
  List<Place> _suggestions = const [];
  bool _isFetchingLocation = false;
  bool _isSearching = false;
  bool _isFetchingWeather = false;
  String? _locationAccessMessage;
  Timer? _searchDebounce;
  int _searchRequestId = 0;

  static const _tabLabels = ['Currently', 'Today', 'Weekly'];

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? createDefaultLocationService();
    _geocodingService =
        widget.geocodingService ?? createDefaultGeocodingService();
    _weatherService = widget.weatherService ?? createDefaultWeatherService();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
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

    final results = await _geocodingService.search(trimmedQuery);

    if (!mounted || requestId != _searchRequestId) {
      return;
    }

    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  Future<void> _applyPlace(Place place) async {
    setState(() {
      _locationSource = place.displayLabel;
      _locationAccessMessage = null;
      _suggestions = const [];
      _isFetchingWeather = true;
    });

    await _weatherService.fetchForecast(place);

    if (!mounted) {
      return;
    }

    setState(() {
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

      setState(() {
        _locationSource = coordinates.displayLabel;
        _locationAccessMessage = null;
        _searchController.clear();
        _suggestions = const [];
      });
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

    final results = await _geocodingService.search(trimmedValue);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearching = false;
    });

    if (results.isEmpty) {
      setState(() {
        _locationSource = trimmedValue;
      });
      return;
    }

    _searchController.text = results.first.name;
    await _applyPlace(results.first);
  }

  Future<void> _onSuggestionSelected(Place place) async {
    _searchController.text = place.name;
    setState(() {
      _suggestions = const [];
    });
    _searchFocusNode.unfocus();
    await _applyPlace(place);
  }

  double _contentFontSize(double width) {
    if (width >= 900) {
      return 40;
    }
    if (width >= 600) {
      return 32;
    }
    return 24;
  }

  double _horizontalPadding(double width) {
    if (width >= 900) {
      return width * 0.2;
    }
    if (width >= 600) {
      return width * 0.12;
    }
    return 16;
  }

  Widget _buildTabTitleText({
    required String text,
    required TextStyle? style,
    required double maxWidth,
  }) {
    return SizedBox(
      width: maxWidth,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }

  Widget _buildLocationText({
    required String text,
    required TextStyle? style,
    required double maxWidth,
  }) {
    return SizedBox(
      width: maxWidth,
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty && !_isSearching) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 4,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: _isSearching && _suggestions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = _suggestions[index];
                  return ListTile(
                    title: Text(place.name),
                    subtitle: Text(place.suggestionSubtitle),
                    onTap: () => _onSuggestionSelected(place),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = _horizontalPadding(width);
        final maxTextWidth = width - (horizontalPadding * 2);
        final tabName = _tabLabels[index];
        final location = _locationSource;
        final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: _contentFontSize(width),
              fontWeight: FontWeight.bold,
            );
        final subtitleStyle =
            Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: _contentFontSize(width) * 0.75,
                );

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabTitleText(
                  text: tabName,
                  style: titleStyle,
                  maxWidth: maxTextWidth,
                ),
                if (_isFetchingLocation || _isFetchingWeather) ...[
                  SizedBox(height: width >= 600 ? 16 : 12),
                  SizedBox(
                    width: maxTextWidth,
                    child: const LinearProgressIndicator(),
                  ),
                ] else if (location != null && location.isNotEmpty) ...[
                  SizedBox(height: width >= 600 ? 16 : 12),
                  _buildLocationText(
                    text: location,
                    style: subtitleStyle,
                    maxWidth: maxTextWidth,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        titleSpacing: isWideScreen ? 24 : 0,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search city...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            contentPadding: EdgeInsets.symmetric(
              vertical: isWideScreen ? 16 : 12,
            ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFetchingLocation ? Icons.location_searching : Icons.my_location,
              size: isWideScreen ? 28 : 24,
            ),
            tooltip: 'Use current location',
            onPressed: _isFetchingLocation ? null : _onGeolocationPressed,
          ),
          SizedBox(width: isWideScreen ? 8 : 0),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_locationAccessMessage != null)
              MaterialBanner(
                content: Text(_locationAccessMessage!),
                leading: const Icon(Icons.location_off),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
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
                children: List.generate(
                  _tabLabels.length,
                  _buildTabContent,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: BottomAppBar(
          height: isWideScreen ? 72 : 56,
          color: Theme.of(context).colorScheme.surface,
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 32 : 12,
          ),
          child: TabBar(
            controller: _tabController,
            tabAlignment: TabAlignment.fill,
            labelStyle: TextStyle(
              fontSize: isWideScreen ? 14 : 12,
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
