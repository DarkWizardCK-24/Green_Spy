import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  // Using exchangerate-api.com (free tier available)
  static const String baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  // Alternative: 'https://open.er-api.com/v6/latest'

  Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$baseCurrency'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load exchange rates');
      }
    } catch (e) {
      throw Exception('Error fetching rates: $e');
    }
  }

  Future<double> convertCurrency({
    required String from,
    required String to,
    required double amount,
  }) async {
    try {
      final data = await getExchangeRates(from);
      final rates = data['rates'] as Map<String, dynamic>;

      if (rates.containsKey(to)) {
        final rate = rates[to] as num;
        return amount * rate.toDouble();
      } else {
        throw Exception('Currency not found');
      }
    } catch (e) {
      throw Exception('Conversion failed: $e');
    }
  }

  // Popular currencies with flags
  static List<CurrencyData> getPopularCurrencies() {
    return [
      CurrencyData('USD', 'US Dollar', '🇺🇸'),
      CurrencyData('EUR', 'Euro', '🇪🇺'),
      CurrencyData('GBP', 'British Pound', '🇬🇧'),
      CurrencyData('JPY', 'Japanese Yen', '🇯🇵'),
      CurrencyData('AUD', 'Australian Dollar', '🇦🇺'),
      CurrencyData('CAD', 'Canadian Dollar', '🇨🇦'),
      CurrencyData('CHF', 'Swiss Franc', '🇨🇭'),
      CurrencyData('CNY', 'Chinese Yuan', '🇨🇳'),
      CurrencyData('INR', 'Indian Rupee', '🇮🇳'),
      CurrencyData('MXN', 'Mexican Peso', '🇲🇽'),
      CurrencyData('BRL', 'Brazilian Real', '🇧🇷'),
      CurrencyData('ZAR', 'South African Rand', '🇿🇦'),
      CurrencyData('SGD', 'Singapore Dollar', '🇸🇬'),
      CurrencyData('HKD', 'Hong Kong Dollar', '🇭🇰'),
      CurrencyData('SEK', 'Swedish Krona', '🇸🇪'),
      CurrencyData('NZD', 'New Zealand Dollar', '🇳🇿'),
      CurrencyData('KRW', 'South Korean Won', '🇰🇷'),
      CurrencyData('TRY', 'Turkish Lira', '🇹🇷'),
      CurrencyData('RUB', 'Russian Ruble', '🇷🇺'),
      CurrencyData('AED', 'UAE Dirham', '🇦🇪'),
    ];
  }
}

class CurrencyData {
  final String code;
  final String name;
  final String flag;

  CurrencyData(this.code, this.name, this.flag);
}
