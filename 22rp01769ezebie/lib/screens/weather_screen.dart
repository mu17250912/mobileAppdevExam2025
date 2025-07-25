import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../models/daily_forecast.dart';
import '../models/hourly_forecast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart' show checkForRainAlerts, initializeNotifications;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'weather_history_screen.dart';
// import '../l10n/app_localizations.dart';
import 'notification_center_screen.dart';
import 'package:hive/hive.dart';
import 'package:infofarmer/screens/login_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WeatherScreen extends StatefulWidget {
  final bool showAppBar;
  final bool isAdmin;
  const WeatherScreen({Key? key, this.showAppBar = false, this.isAdmin = false}) : super(key: key);
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String? weatherDesc;
  double? temp;
  double? currentRain;
  double? currentWind;
  int? humidity;
  DateTime? sunrise;
  DateTime? sunset;
  bool loading = true;
  String? error;
  List<DailyForecast> forecast = [];
  List<HourlyForecast> hourlyForecast = [];
  bool offline = false;
  String selectedCrop = 'Beans';
  bool _showFahrenheit = false;

  @override
  void initState() {
    super.initState();
    initializeNotifications(); // Ensure notifications are initialized
    // Show cached weather instantly if available
    var box = Hive.isBoxOpen('weather_history') ? Hive.box<DailyForecast>('weather_history') : null;
    if (box != null && box.isNotEmpty) {
      setState(() {
        forecast = box.values.toList();
        loading = false;
        offline = true;
      });
    } else {
      setState(() { loading = true; });
    }
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    if (mounted) {
      setState(() { error = null; offline = false; });
    }
    try {
      // Check connectivity
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Load from Hive
        var box = Hive.box<DailyForecast>('weather_history');
        if (mounted) {
          setState(() {
            forecast = box.values.toList();
            hourlyForecast = []; // Optionally, use another box for hourly if needed
            loading = false;
            offline = true;
          });
        }
        return;
      }
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() { error = 'Location services are disabled.'; loading = false; });
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() { error = 'Location permissions are denied.'; loading = false; });
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() { error = 'Location permissions are permanently denied.'; loading = false; });
        }
        return;
      }
      // Try to get last known position for faster initial load
      Position? position;
      if (kIsWeb) {
        position = await Geolocator.getCurrentPosition();
      } else {
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          position = await Geolocator.getCurrentPosition();
        }
      }
      final lat = position.latitude;
      final lon = position.longitude;
      const apiKey = '69c63c534463c5d1cbaee583820be1c3';
      // Fetch current weather and forecast in parallel
      final currentWeatherUrl = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
      final results = await Future.wait([
        http.get(Uri.parse(currentWeatherUrl)).timeout(Duration(seconds: 5)),
        http.get(Uri.parse(forecastUrl)).timeout(Duration(seconds: 5)),
      ]);
      final response = results[0];
      final forecastResp = results[1];
      if (response.statusCode == 200 && forecastResp.statusCode == 200) {
        final data = json.decode(response.body);
        final forecastData = json.decode(forecastResp.body);
        if (mounted) {
          setState(() {
            weatherDesc = data['weather'][0]['description'];
            temp = data['main']['temp']?.toDouble();
            currentRain = (data['rain'] != null && data['rain']['1h'] != null)
                ? (data['rain']['1h'] as num).toDouble()
                : null;
            currentWind = (data['wind'] != null && data['wind']['speed'] != null)
                ? (data['wind']['speed'] as num).toDouble()
                : null;
            humidity = data['main']['humidity'] as int?;
            sunrise = data['sys'] != null && data['sys']['sunrise'] != null
                ? DateTime.fromMillisecondsSinceEpoch((data['sys']['sunrise'] as int) * 1000)
                : null;
            sunset = data['sys'] != null && data['sys']['sunset'] != null
                ? DateTime.fromMillisecondsSinceEpoch((data['sys']['sunset'] as int) * 1000)
                : null;
            forecast = parseForecast(forecastData['list']);
            hourlyForecast = parseHourlyForecast(forecastData['list']);
            loading = false;
            offline = false;
          });
        }
        // Save to Hive
        var box = Hive.box<DailyForecast>('weather_history');
        await box.clear();
        await box.addAll(forecast);
        // Check for rain/flood/dry spell alerts after updating hourlyForecast
        checkForRainAlerts(hourlyForecast);
      } else {
        if (mounted) {
          setState(() { error = 'Failed to fetch weather data.'; loading = false; });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { error = 'Error: $e'; loading = false; });
      }
    }
  }

  List<DailyForecast> parseForecast(List<dynamic> list) {
    final Map<String, List<dynamic>> byDay = {};
    for (var entry in list) {
      final dtTxt = entry['dt_txt'] as String;
      final day = dtTxt.substring(0, 10);
      byDay.putIfAbsent(day, () => []).add(entry);
    }
    final today = DateTime.now();
    final List<DailyForecast> result = [];
    byDay.forEach((day, entries) {
      final date = DateTime.parse(day);
      if (date.isBefore(today)) return;
      entries.sort((a, b) => (a['dt_txt'] as String).compareTo(b['dt_txt'] as String));
      var midday = entries[(entries.length / 2).floor()];
      double minT = double.infinity, maxT = -double.infinity, rainSum = 0, windSum = 0;
      int rainCount = 0;
      for (var e in entries) {
        final t = e['main']['temp']?.toDouble() ?? 0.0;
        if (t < minT) minT = t;
        if (t > maxT) maxT = t;
        if (e['rain'] != null && e['rain']['3h'] != null) {
          rainSum += (e['rain']['3h'] as num).toDouble();
          rainCount++;
        }
        windSum += (e['wind']['speed'] as num?)?.toDouble() ?? 0.0;
      }
      result.add(DailyForecast(
        date: date,
        temp: midday['main']['temp']?.toDouble() ?? 0.0,
        minTemp: minT != double.infinity ? minT : null,
        maxTemp: maxT != -double.infinity ? maxT : null,
        icon: midday['weather'][0]['icon'] ?? '01d',
        rainChance: rainCount > 0 ? (rainSum / rainCount) : null,
        wind: entries.isNotEmpty ? (windSum / entries.length) : null,
      ));
    });
    result.sort((a, b) => a.date.compareTo(b.date));
    return result.take(3).toList();
  }

  List<HourlyForecast> parseHourlyForecast(List<dynamic> list) {
    final now = DateTime.now();
    return list
        .map((entry) => HourlyForecast(
              time: DateTime.parse(entry['dt_txt']),
              temp: entry['main']['temp']?.toDouble() ?? 0.0,
              icon: entry['weather'][0]['icon'] ?? '01d',
              rain: entry['rain'] != null && entry['rain']['3h'] != null
                  ? (entry['rain']['3h'] as num).toDouble()
                  : 0.0,
              wind: entry['wind'] != null && entry['wind']['speed'] != null
                  ? (entry['wind']['speed'] as num).toDouble()
                  : 0.0,
            ))
        .where((h) => h.time.isAfter(now))
        .take(8)
        .toList();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _weekday(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  String? getCropAdvice(String crop, List<DailyForecast> forecast) {
    double rainSum = forecast.take(3).fold(0.0, (sum, day) => sum + (day.rainChance ?? 0.0));
    if (crop == 'Beans' && rainSum < 10) {
      return 'Your selected crop (beans) needs watering. No rain expected for 3 days.';
    }
    if (crop == 'Maize' && rainSum < 15) {
      return 'Your selected crop (maize) needs watering. No rain expected for 3 days.';
    }
    if (crop == 'Potatoes' && rainSum < 12) {
      return 'Your selected crop (potatoes) needs watering. No rain expected for 3 days.';
    }
    return null;
  }

  double _toF(double c) => c * 9 / 5 + 32;
  String _tempString(double? c) {
    if (c == null) return '--';
    return _showFahrenheit ? '${_toF(c).toStringAsFixed(1)}°F' : '${c.toStringAsFixed(1)}°C';
  }

  @override
  Widget build(BuildContext context) {
    // final loc = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text('Weather'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(_showFahrenheit ? Icons.thermostat : Icons.thermostat_auto),
                  tooltip: _showFahrenheit ? 'Show Celsius' : 'Show Fahrenheit',
                  onPressed: () {
                    setState(() {
                      _showFahrenheit = !_showFahrenheit;
                    });
                  },
                ),
              ],
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6DD5FA), // Light blue
              Color(0xFF2980B9), // Deep blue
            ],
          ),
        ),
        child: loading
            ? Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading weather data...', style: TextStyle(color: Colors.white)),
                      if (loading)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Still loading, please wait...', style: TextStyle(color: Colors.white70)),
                        ),
                    ],
                  ),
                ),
              )
            : error != null
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text(error!, style: TextStyle(color: Colors.red, fontSize: 18)),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: fetchWeather,
                            icon: Icon(Icons.refresh),
                            label: Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : (forecast.isEmpty && offline)
                    ? Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off, color: Colors.grey, size: 48),
                              SizedBox(height: 16),
                              Text('No cached weather data available.', style: TextStyle(fontSize: 18, color: Colors.white)),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: fetchWeather,
                                icon: Icon(Icons.refresh),
                                label: Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : (forecast.isEmpty)
                        ? Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud, color: Colors.grey, size: 48),
                                  SizedBox(height: 16),
                                  Text('No weather data available.', style: TextStyle(fontSize: 18, color: Colors.white)),
                                  SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: fetchWeather,
                                    icon: Icon(Icons.refresh),
                                    label: Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildWeatherContent(context),
      ),
    );
  }

  Widget _buildWeatherContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      children: [
        if (widget.isAdmin)
          Card(
            color: Colors.amber[50],
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.amber[900]),
                  SizedBox(width: 8),
                  Text('Admin Mode: You have access to admin features.', style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        if (weatherDesc != null && temp != null)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8,
            color: Colors.white.withOpacity(0.9),
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Image.network(
                    'https://openweathermap.org/img/wn/01d@2x.png',
                    width: 64,
                    height: 64,
                    errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 48, color: Colors.blue),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Temperature: ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey[800], fontSize: 18)),
                            Text(_tempString(temp), style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text('Condition: ${weatherDesc!.toUpperCase()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey[700])),
                        if (currentRain != null) Text('Rain: ${currentRain?.toStringAsFixed(1)} mm', style: TextStyle(color: Colors.blueGrey[700], fontSize: 16)),
                        if (currentWind != null) Text('Wind: ${currentWind?.toStringAsFixed(1)} m/s', style: TextStyle(color: Colors.blueGrey[700], fontSize: 16)),
                        if (humidity != null) Text('Humidity: $humidity%', style: TextStyle(color: Colors.blueGrey[700], fontSize: 16)),
                        if (sunrise != null && sunset != null)
                          Text('Sunrise: ${sunrise!.hour}:${sunrise!.minute.toString().padLeft(2, '0')}  |  Sunset: ${sunset!.hour}:${sunset!.minute.toString().padLeft(2, '0')}', style: TextStyle(color: Colors.blueGrey[700], fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        Text('3-Day Forecast:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        // Toggle button for Celsius/Fahrenheit
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: Icon(_showFahrenheit ? Icons.thermostat : Icons.thermostat_auto),
            label: Text(_showFahrenheit ? 'Show °C' : 'Show °F'),
            onPressed: () {
              setState(() {
                _showFahrenheit = !_showFahrenheit;
              });
            },
          ),
        ),
        SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: forecast.length,
              itemBuilder: (context, i) {
                final f = forecast[i];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                  color: Colors.blue[(i + 2) * 100]?.withOpacity(0.85) ?? Colors.blue[200],
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, color: Colors.white, size: 28),
                        SizedBox(height: 6),
                        Text('${f.date.toLocal().toString().split(' ')[0]}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 6),
                        Text('Avg Temp: ${_tempString(f.temp)}', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Min: ${_tempString(f.minTemp)}', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Max: ${_tempString(f.maxTemp)}', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        if (f.rainChance != null) Text('Rain: ${f.rainChance}', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        if (f.wind != null) Text('Wind: ${f.wind}', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            );
          },
        ),
        SizedBox(height: 24),
        Text('Next 8 Hours:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hourlyForecast.length,
            separatorBuilder: (_, __) => SizedBox(width: 12),
            itemBuilder: (context, i) {
              final h = hourlyForecast[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                color: Colors.white.withOpacity(0.85),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, color: Colors.blue[700]),
                      SizedBox(height: 4),
                      Text('Time: ${h.time.hour}:00', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 13)),
                      Text('Temp: ${_tempString(h.temp)}', style: TextStyle(fontSize: 14, color: Colors.blue[900], fontWeight: FontWeight.bold)),
                      Text('Rain: ${h.rain}', style: TextStyle(fontSize: 11, color: Colors.blueGrey[700])),
                      Text('Wind: ${h.wind}', style: TextStyle(fontSize: 11, color: Colors.blueGrey[700])),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final DailyForecast forecast;
  const _ForecastCard({required this.forecast});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[100]!, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.13),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.network(
                'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
                width: 32,
                height: 32,
                cacheWidth: 32,
                cacheHeight: 32,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(width: 32, height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                },
                errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 28),
              ),
              const SizedBox(height: 2),
              Tooltip(
                message: 'Average temperature for the day',
                child: Text(
                  '${forecast.temp.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
              if (forecast.minTemp != null && forecast.maxTemp != null)
                Tooltip(
                  message: 'Minimum and maximum temperature for the day',
                  child: Text(
                    'Min: ${forecast.minTemp!.toStringAsFixed(0)}°  Max: ${forecast.maxTemp!.toStringAsFixed(0)}°',
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: 'Day of the week for this forecast',
          child: Text(
            _weekday(forecast.date),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _weekday(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }
}

class WeatherHistoryScreen extends StatefulWidget {
  const WeatherHistoryScreen({Key? key}) : super(key: key);
  @override
  State<WeatherHistoryScreen> createState() => _WeatherHistoryScreenState();
}

class _WeatherHistoryScreenState extends State<WeatherHistoryScreen> {
  int days = 7;
  List<DailyForecast> history = [];
  bool loading = true;

  double get avgTemp => history.isEmpty ? 0 : history.map((d) => d.temp).reduce((a, b) => a + b) / history.length;
  double get totalRain => history.isEmpty ? 0 : history.map((d) => d.rainChance ?? 0).reduce((a, b) => a + b);

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (mounted) {
      setState(() { loading = true; });
    }
    var box = Hive.box<DailyForecast>('weather_history');
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final all = box.values
      .where((d) => d.date.isAfter(cutoff) && d.date.isBefore(now.add(const Duration(days: 1))))
      .toList();
    all.sort((a, b) => a.date.compareTo(b.date));
    if (mounted) {
      setState(() {
        history = all;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather History'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, semanticLabel: 'Logout'),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Show last'),
                      DropdownButton<int>(
                        value: days,
                        items: [7, 14, 30].map((d) => DropdownMenuItem(value: d, child: Text('$d days'))).toList(),
                        onChanged: (v) {
                          if (mounted) {
                            setState(() { days = v!; });
                          }
                          loadHistory();
                        },
                      ),
                    ],
                  ),
                ),
                if (history.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Avg Temp: ${avgTemp.toStringAsFixed(1)}°C', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 24),
                        Text('Total Rain: ${totalRain.toStringAsFixed(1)}mm', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: history.isEmpty
                        ? Center(child: Text('No history data available'))
                        : Column(
                            children: [
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 || idx >= history.length) return const SizedBox();
                                            final d = history[idx].date;
                                            return Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10));
                                          },
                                          interval: 1,
                                        ),
                                      ),
                                    ),
                                    minY: history.map((d) => d.temp).reduce((a, b) => a < b ? a : b) - 2,
                                    maxY: history.map((d) => d.temp).reduce((a, b) => a > b ? a : b) + 2,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: [
                                          for (int i = 0; i < history.length; i++)
                                            FlSpot(i.toDouble(), history[i].temp),
                                        ],
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 3,
                                        dotData: FlDotData(show: false),
                                      ),
                                    ],
                                    gridData: FlGridData(show: true),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: BarChart(
                                  BarChartData(
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 || idx >= history.length) return const SizedBox();
                                            final d = history[idx].date;
                                            return Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10));
                                          },
                                          interval: 1,
                                        ),
                                      ),
                                    ),
                                    barGroups: [
                                      for (int i = 0; i < history.length; i++)
                                        BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY: (history[i].rainChance ?? 0),
                                              color: Colors.blueAccent,
                                              width: 12,
                                            ),
                                          ],
                                        ),
                                    ],
                                    gridData: FlGridData(show: true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }
} 