import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dailynest/Weather/weather_service.dart';
import 'package:dailynest/Weather/weather_widgets.dart';

class Weather extends StatefulWidget {
  static const String id = "Weather";

  const Weather({super.key});

  @override
  State<Weather> createState() => _WeatherState();
}

class _WeatherState extends State<Weather> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherService _weatherService = WeatherService();

  WeatherData? _weather;
  List<DailyForecast> _dailyForecast = const [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocationWeather();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _resolveLocation();
      if (!mounted) return;
      final data = await _weatherService.fetchByCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final forecast = await _weatherService.fetchForecastByCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _weather = data;
        _dailyForecast = _weatherService.processDailyForecast(forecast);
        _errorMessage = null;
      });
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _resolveLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw WeatherException('Enable location services to fetch your weather.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw WeatherException('Location permission is required to load your current weather.');
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
  }

  Future<void> _searchWeather() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _weatherService.fetchByQuery(_searchController.text);
      final forecast = await _weatherService.fetchForecastByQuery(_searchController.text);
      if (!mounted) return;
      setState(() {
        _weather = data;
        _dailyForecast = _weatherService.processDailyForecast(forecast);
        _errorMessage = null;
      });
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleError(Object error) {
    final message = error is WeatherException
        ? error.message
        : 'Something went wrong while loading weather data.';
    if (!mounted) {
      return;
    }
    setState(() {
      _errorMessage = message;
      _dailyForecast = const [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildWeatherContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_weather == null) {
      return const Center(
        child: Text(
          'Weather details will appear here.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    final data = _weather!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.locationName,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9E4D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${data.temperature.toStringAsFixed(1)}°C',
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data.description,
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _WeatherMetric(label: 'Feels like', value: '${data.feelsLike.toStringAsFixed(1)}°C'),
            _WeatherMetric(label: 'Humidity', value: '${data.humidity}%'),
          ],
        ),
        const SizedBox(height: 24),
        _build10DayForecast(),
      ],
    );
  }

  Widget _build10DayForecast() {
    if (_dailyForecast.isEmpty) {
      return const SizedBox.shrink();
    }

    return TenDayForecastList(forecasts: _dailyForecast);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ModalRoute.of(context)?.canPop == true
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'DailyNest',
                    style: TextStyle(
                      color: Color(0xFFFF9E4D),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Weather',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchWeather(),
                    decoration: InputDecoration(
                      hintText: 'Search for a city or country',
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchWeather,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFFF9E4D)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _loadCurrentLocationWeather,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use current location'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: _buildWeatherContent(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherMetric extends StatelessWidget {
  final String label;
  final String value;

  const _WeatherMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}