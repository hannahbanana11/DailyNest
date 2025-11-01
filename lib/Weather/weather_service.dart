import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherException implements Exception {
  final String message;

  WeatherException(this.message);

  @override
  String toString() => message;
}

class WeatherData {
  final String locationName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String description;

  const WeatherData({
    required this.locationName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.description,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>?
        ?? (throw WeatherException('Weather data is incomplete.'));
    final weatherList = json['weather'] as List<dynamic>?;
    final weather = weatherList != null && weatherList.isNotEmpty
        ? weatherList.first as Map<String, dynamic>
        : <String, dynamic>{'description': 'N/A'};

    return WeatherData(
      locationName: json['name'] as String? ?? 'Unknown location',
      temperature: (main['temp'] as num?)?.toDouble() ?? 0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      description: (weather['description'] as String? ?? 'N/A'),
    );
  }
}

class WeatherForecastEntry {
  final DateTime time;
  final double temperature;
  final String description;

  const WeatherForecastEntry({
    required this.time,
    required this.temperature,
    required this.description,
  });

  factory WeatherForecastEntry.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? const {};
    final weatherList = json['weather'] as List<dynamic>?;
    final weather = weatherList != null && weatherList.isNotEmpty
        ? weatherList.first as Map<String, dynamic>
        : <String, dynamic>{'description': 'N/A'};

    return WeatherForecastEntry(
      time: DateTime.fromMillisecondsSinceEpoch((json['dt'] as num).toInt() * 1000, isUtc: true).toLocal(),
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      description: weather['description']?.toString() ?? 'N/A',
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String description;

  const DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.description,
  });
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey = '8ff8674b3db689eab95854768a445d4e';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  final http.Client _client;

  Future<WeatherData> fetchByCoordinates({required double latitude, required double longitude}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'lat': latitude.toStringAsFixed(4),
      'lon': longitude.toStringAsFixed(4),
      'units': 'metric',
      'appid': _apiKey,
    });

    return _performRequest(uri);
  }

  Future<WeatherData> fetchByQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw WeatherException('Enter a location to search.');
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': trimmed,
      'units': 'metric',
      'appid': _apiKey,
    });

    return _performRequest(uri);
  }

  Future<List<WeatherForecastEntry>> fetchForecastByCoordinates({required double latitude, required double longitude}) async {
    final uri = Uri.parse(_forecastUrl).replace(queryParameters: {
      'lat': latitude.toStringAsFixed(4),
      'lon': longitude.toStringAsFixed(4),
      'units': 'metric',
      'appid': _apiKey,
    });

    return _performForecastRequest(uri);
  }

  Future<List<WeatherForecastEntry>> fetchForecastByQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw WeatherException('Enter a location to search.');
    }

    final uri = Uri.parse(_forecastUrl).replace(queryParameters: {
      'q': trimmed,
      'units': 'metric',
      'appid': _apiKey,
    });

    return _performForecastRequest(uri);
  }

  Future<WeatherData> _performRequest(Uri uri) async {
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final message = body['message']?.toString();
        throw WeatherException(message ?? 'Failed to load weather data.');
      } catch (_) {
        throw WeatherException('Failed to load weather data.');
      }
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherData.fromJson(data);
  }

  Future<List<WeatherForecastEntry>> _performForecastRequest(Uri uri) async {
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final message = body['message']?.toString();
        throw WeatherException(message ?? 'Failed to load forecast data.');
      } catch (_) {
        throw WeatherException('Failed to load forecast data.');
      }
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['list'] as List<dynamic>?;
    if (list == null || list.isEmpty) {
      return const [];
    }

    return list
        .cast<Map<String, dynamic>>()
        .map(WeatherForecastEntry.fromJson)
        .toList(growable: false);
  }

  List<DailyForecast> processDailyForecast(List<WeatherForecastEntry> hourlyData) {
    if (hourlyData.isEmpty) return const [];

    final Map<String, List<double>> dailyTemps = {};
    final Map<String, String> dailyDesc = {};

    for (final entry in hourlyData) {
      final dateKey = '${entry.time.year}-${entry.time.month}-${entry.time.day}';
      
      dailyTemps.putIfAbsent(dateKey, () => []);
      dailyTemps[dateKey]!.add(entry.temperature);
      
      if (!dailyDesc.containsKey(dateKey)) {
        dailyDesc[dateKey] = entry.description;
      }
    }

    final dailyForecasts = <DailyForecast>[];
    for (final dateKey in dailyTemps.keys) {
      final temps = dailyTemps[dateKey]!;
      final parts = dateKey.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      dailyForecasts.add(DailyForecast(
        date: date,
        maxTemp: temps.reduce((a, b) => a > b ? a : b),
        minTemp: temps.reduce((a, b) => a < b ? a : b),
        description: dailyDesc[dateKey] ?? 'N/A',
      ));
    }

    dailyForecasts.sort((a, b) => a.date.compareTo(b.date));
    return dailyForecasts.take(10).toList(growable: false);
  }
}
