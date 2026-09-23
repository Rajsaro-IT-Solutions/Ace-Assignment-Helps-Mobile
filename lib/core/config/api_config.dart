import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _keyBaseUrl = 'pref_portal_api_base_url';

  // Public Cloud Endpoint (Accessible from ANY physical phone on Wi-Fi or 4G/5G mobile data)
  static const String cloudUrl = 'https://multicuspidate-rosaline-precontemporaneously.ngrok-free.dev';

  // Local Network Presets
  static const String lanUrl = 'http://172.16.1.119:8000';
  static const String emulatorUrl = 'http://10.0.2.2:8000';
  static const String localhostUrl = 'http://localhost:8000';

  static String _currentBaseUrl = '';

  static String get defaultBaseUrl {
    // Default to the public cloud endpoint so physical phones work immediately without network setup
    return cloudUrl;
  }

  static String get baseUrl {
    if (_currentBaseUrl.isNotEmpty) return _currentBaseUrl;
    return defaultBaseUrl;
  }

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyBaseUrl);
      // If previous version stored emulator or local LAN URL, automatically upgrade to public cloudUrl
      if (saved != null &&
          saved.trim().isNotEmpty &&
          !saved.contains('10.0.2.2') &&
          !saved.contains('172.16.1.119') &&
          !saved.contains('localhost')) {
        _currentBaseUrl = saved.trim();
      } else {
        _currentBaseUrl = defaultBaseUrl;
        await prefs.setString(_keyBaseUrl, defaultBaseUrl);
      }
    } catch (e) {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    String formatted = newUrl.trim();
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    _currentBaseUrl = formatted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, formatted);
  }

  static String get portalApiEndpoint => '$baseUrl/portal_api.php';
}
