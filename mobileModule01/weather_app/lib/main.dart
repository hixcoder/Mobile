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

  void _onGeolocationPressed() {
    setState(() {
      _locationSource = 'Geolocation';
    });
  }

  void _onSearchSubmitted(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return;
    }

    setState(() {
      _locationSource = trimmedValue;
    });
  }

  String _tabDisplayText(int index) {
    if (_locationSource == null) {
      return "";
    }
    return ' $_locationSource';
  }

  void _onTabSelected(int index) {
    _tabController.animateTo(index);
  }

  Widget _buildTabContent(int index) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _tabLabels[index],
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            _tabDisplayText(index),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTab(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search city...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Use current location',
            onPressed: _onGeolocationPressed,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          _tabLabels.length,
          _buildTabContent,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            _buildBottomTab(0, Icons.wb_sunny, 'Currently'),
            _buildBottomTab(1, Icons.today, 'Today'),
            _buildBottomTab(2, Icons.calendar_view_week, 'Weekly'),
          ],
        ),
      ),
    );
  }
}
