import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _mainCurrencyKey = 'main_currency';
  static const String _defaultCurrency = 'ILS';

  /// Get the user's main currency
  static Future<String> getMainCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mainCurrencyKey) ?? _defaultCurrency;
  }

  /// Set the user's main currency
  static Future<void> setMainCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mainCurrencyKey, currency);
  }

  /// Get all user preferences
  static Future<Map<String, dynamic>> getAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'main_currency': prefs.getString(_mainCurrencyKey) ?? _defaultCurrency,
    };
  }

  /// Clear all preferences
  static Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
