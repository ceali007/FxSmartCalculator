import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  Future<double> getRateToUSD(String currencyCode) async {
    if (currencyCode.toUpperCase() == 'USD') {
      return 1.0;
    }

    final url = Uri.parse('https://api.exchangerate.host/latest?base=$currencyCode&symbols=USD');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rate = data['rates']['USD'];
      return rate is double ? rate : double.parse(rate.toString());
    } else {
      throw Exception('Kur bilgisi alınamadı: ${response.statusCode}');
    }
  }
}
