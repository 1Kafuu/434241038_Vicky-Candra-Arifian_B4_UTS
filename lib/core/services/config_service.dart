import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _baseUrlKey = 'backend_base_url';
  static const String _defaultLocalUrl = 'https://flutter-backend-production-8ad5.up.railway.app';

  static Map<String, dynamic>? _appConfig;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_baseUrlKey)) {
      await prefs.setString(_baseUrlKey, _defaultLocalUrl);
    } else {
      final stored = prefs.getString(_baseUrlKey);
      if (stored == null || stored.contains('192.168') || stored.contains('localhost')) {
        await prefs.setString(_baseUrlKey, _defaultLocalUrl);
      }
    }
    await _loadAppConfig();
  }

  static Future<void> _loadAppConfig() async {
    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      _appConfig = json.decode(jsonString);
    } catch (e) {
      _appConfig = null;
    }
  }

  static Map<String, dynamic>? get appConfig => _appConfig;

  static String get appName => _appConfig?['app_name'] ?? 'E-Ticketing';
  static String get supportEmail => _appConfig?['support_email'] ?? '';
  static bool get notificationsEnabled => _appConfig?['features']?['notifications'] ?? true;
  static bool get darkModeEnabled => _appConfig?['features']?['dark_mode'] ?? false;

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? _defaultLocalUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  static Future<String?> fetchBaseUrlFromServer(String serverUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/api/config'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['baseUrl'];
      }
    } catch (_) {}
    return null;
  }

  static Future<void> discoverAndSetBaseUrl() async {
    final discovered = await fetchBaseUrlFromServer(_defaultLocalUrl);
    if (discovered != null) {
      await setBaseUrl(discovered);
    }
  }
}
