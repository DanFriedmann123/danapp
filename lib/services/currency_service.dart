import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _defaultBaseCurrency = 'ILS'; // Israeli Shekel
  static Map<String, Map<String, double>> _cachedRates = {};
  static Map<String, DateTime> _lastCacheTime = {};
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Get exchange rates for a base currency
  static Future<Map<String, double>> getExchangeRates([
    String baseCurrency = _defaultBaseCurrency,
  ]) async {
    print('🔍 [CurrencyService] Getting exchange rates for: $baseCurrency');

    // Check if we have cached rates for this base currency that are still valid
    if (_cachedRates.containsKey(baseCurrency) &&
        _lastCacheTime.containsKey(baseCurrency)) {
      final timeDiff = DateTime.now().difference(_lastCacheTime[baseCurrency]!);
      print(
        '🔍 [CurrencyService] Cache time difference: ${timeDiff.inMinutes} minutes',
      );

      if (timeDiff < _cacheDuration) {
        print('✅ [CurrencyService] Using cached rates for $baseCurrency');
        return _cachedRates[baseCurrency]!;
      }
    }

    print('🌐 [CurrencyService] Fetching new rates from API for $baseCurrency');
    try {
      final url = '$_baseUrl/$baseCurrency';
      print('🔗 [CurrencyService] API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      print('📡 [CurrencyService] API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '📊 [CurrencyService] API Response data keys: ${data.keys.toList()}',
        );

        final ratesData = data['rates'] as Map<String, dynamic>;
        final rates = <String, double>{};

        // Convert all values to double, handling both int and double types
        ratesData.forEach((key, value) {
          if (value is int) {
            rates[key] = value.toDouble();
          } else if (value is double) {
            rates[key] = value;
          } else if (value is num) {
            rates[key] = value.toDouble();
          }
        });

        print('💱 [CurrencyService] Processed ${rates.length} exchange rates');
        print(
          '💱 [CurrencyService] Sample rates: ${rates.entries.take(5).map((e) => '${e.key}: ${e.value}').join(', ')}',
        );

        // Cache the rates for this base currency
        _cachedRates[baseCurrency] = rates;
        _lastCacheTime[baseCurrency] = DateTime.now();

        print('💾 [CurrencyService] Cached rates for $baseCurrency');
        return rates;
      } else {
        print('❌ [CurrencyService] API Error: ${response.statusCode}');
        throw Exception(
          'Failed to load exchange rates: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ [CurrencyService] Exception: $e');
      // Return cached rates if available, even if expired
      if (_cachedRates.containsKey(baseCurrency)) {
        print(
          '🔄 [CurrencyService] Using expired cached rates for $baseCurrency',
        );
        return _cachedRates[baseCurrency]!;
      }
      throw Exception('Failed to load exchange rates: $e');
    }
  }

  /// Convert amount from one currency to another
  static Future<double> convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    print(
      '🔄 [CurrencyService] Converting $amount $fromCurrency to $toCurrency',
    );

    if (fromCurrency == toCurrency) {
      print('✅ [CurrencyService] Same currency, returning original amount');
      return amount;
    }

    final rates = await getExchangeRates(fromCurrency);
    final rate = rates[toCurrency];

    print('💱 [CurrencyService] Exchange rate for $toCurrency: $rate');

    if (rate == null) {
      print('❌ [CurrencyService] Exchange rate not available for $toCurrency');
      print('❌ [CurrencyService] Available currencies: ${rates.keys.toList()}');
      throw Exception('Exchange rate not available for $toCurrency');
    }

    final result = amount * rate;
    print(
      '✅ [CurrencyService] Conversion result: $amount $fromCurrency = $result $toCurrency',
    );
    return result;
  }

  /// Get supported currencies
  static List<String> getSupportedCurrencies() {
    return [
      'ILS', // Israeli Shekel
      'USD', // US Dollar
      'EUR', // Euro
      'GBP', // British Pound
      'JPY', // Japanese Yen
      'CAD', // Canadian Dollar
      'AUD', // Australian Dollar
      'CHF', // Swiss Franc
      'CNY', // Chinese Yuan
      'INR', // Indian Rupee
      'BRL', // Brazilian Real
      'MXN', // Mexican Peso
      'KRW', // South Korean Won
      'SGD', // Singapore Dollar
      'NZD', // New Zealand Dollar
      'SEK', // Swedish Krona
      'NOK', // Norwegian Krone
      'DKK', // Danish Krone
      'PLN', // Polish Złoty
      'CZK', // Czech Koruna
      'HUF', // Hungarian Forint
      'RUB', // Russian Ruble
      'TRY', // Turkish Lira
      'ZAR', // South African Rand
      'THB', // Thai Baht
      'MYR', // Malaysian Ringgit
      'IDR', // Indonesian Rupiah
      'PHP', // Philippine Peso
      'VND', // Vietnamese Dong
    ];
  }

  /// Get currency symbols
  static Map<String, String> getCurrencySymbols() {
    return {
      'ILS': '₪',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'CHF': 'CHF',
      'CNY': '¥',
      'INR': '₹',
      'BRL': 'R\$',
      'MXN': '\$',
      'KRW': '₩',
      'SGD': 'S\$',
      'NZD': 'NZ\$',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'PLN': 'zł',
      'CZK': 'Kč',
      'HUF': 'Ft',
      'RUB': '₽',
      'TRY': '₺',
      'ZAR': 'R',
      'THB': '฿',
      'MYR': 'RM',
      'IDR': 'Rp',
      'PHP': '₱',
      'VND': '₫',
    };
  }

  /// Get currency names
  static Map<String, String> getCurrencyNames() {
    return {
      'ILS': 'Israeli Shekel',
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'JPY': 'Japanese Yen',
      'CAD': 'Canadian Dollar',
      'AUD': 'Australian Dollar',
      'CHF': 'Swiss Franc',
      'CNY': 'Chinese Yuan',
      'INR': 'Indian Rupee',
      'BRL': 'Brazilian Real',
      'MXN': 'Mexican Peso',
      'KRW': 'South Korean Won',
      'SGD': 'Singapore Dollar',
      'NZD': 'New Zealand Dollar',
      'SEK': 'Swedish Krona',
      'NOK': 'Norwegian Krone',
      'DKK': 'Danish Krone',
      'PLN': 'Polish Złoty',
      'CZK': 'Czech Koruna',
      'HUF': 'Hungarian Forint',
      'RUB': 'Russian Ruble',
      'TRY': 'Turkish Lira',
      'ZAR': 'South African Rand',
      'THB': 'Thai Baht',
      'MYR': 'Malaysian Ringgit',
      'IDR': 'Indonesian Rupiah',
      'PHP': 'Philippine Peso',
      'VND': 'Vietnamese Dong',
    };
  }

  /// Format currency amount with symbol
  static String formatCurrency(double amount, String currencyCode) {
    final symbols = getCurrencySymbols();
    final symbol = symbols[currencyCode] ?? currencyCode;

    if (amount == 0) return '$symbol 0.00';

    // Convert to string with 2 decimal places
    String numStr = amount.toStringAsFixed(2);

    // Split into integer and decimal parts
    List<String> parts = numStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add commas for thousands separators
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ',';
      }
      formattedInteger += integerPart[i];
    }

    // Handle negative numbers
    if (formattedInteger.startsWith('-')) {
      formattedInteger = '-${formattedInteger.substring(1)}';
    }

    return '$symbol $formattedInteger.$decimalPart';
  }

  /// Clear cached rates (useful for testing or when rates need to be refreshed)
  static void clearCache() {
    _cachedRates.clear();
    _lastCacheTime.clear();
  }

  /// Check if rates are cached and valid
  static bool hasValidCache() {
    return _cachedRates.isNotEmpty &&
        _lastCacheTime.isNotEmpty &&
        _lastCacheTime.values.any(
          (time) => DateTime.now().difference(time) < _cacheDuration,
        );
  }
}
