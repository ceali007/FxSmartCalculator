class TextParserHelper {
  static Map<String, String> parseText(String text) {
    final symbolRegex = RegExp(r'\b[A-Z]{3,6}\b');
    final priceRegex = RegExp(r'GIRIS\s*[:：]?\s*([\d.]+)', caseSensitive: false);
    final slRegex = RegExp(r'SL\s*[:：]?\s*([\d.]+)', caseSensitive: false);
    final tpRegex = RegExp(r'TP\s*[:：]?\s*([\d.]+)', caseSensitive: false);

    return {
      'symbol': symbolRegex.firstMatch(text)?.group(0) ?? '',
      'price': priceRegex.firstMatch(text)?.group(1) ?? '',
      'sl': slRegex.firstMatch(text)?.group(1) ?? '',
      'tp': tpRegex.firstMatch(text)?.group(1) ?? '',
    };
  }
}
