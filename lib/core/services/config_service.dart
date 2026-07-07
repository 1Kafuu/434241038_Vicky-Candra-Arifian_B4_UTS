import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _baseUrlKey = 'backend_base_url';
  static const String _defaultLocalUrl = 'http://192.168.1.23:3000';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_baseUrlKey)) {
      await prefs.setString(_baseUrlKey, _defaultLocalUrl);
    }
  }

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
