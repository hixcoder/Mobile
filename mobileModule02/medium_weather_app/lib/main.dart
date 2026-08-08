import 'package:flutter/material.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String? _locationSource;

  static const _tabLabels = ['Currently', 'Today', 'Weekly'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _applyLocationSource(String source) {
    setState(() {
      _locationSource = source;
    });
  }

  void _onGeolocationPressed() {
    _applyLocationSource('Geolocation');
  }

  void _onSearchSubmitted(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return;
    }

    _applyLocationSource(trimmedValue);
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
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: style,
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
                if (location != null && location.isNotEmpty) ...[
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        titleSpacing: isWideScreen ? 24 : 0,
        title: TextField(
          controller: _searchController,
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
              Icons.my_location,
              size: isWideScreen ? 28 : 24,
            ),
            tooltip: 'Use current location',
            onPressed: _onGeolocationPressed,
          ),
          SizedBox(width: isWideScreen ? 8 : 0),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: List.generate(
            _tabLabels.length,
            _buildTabContent,
          ),
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
