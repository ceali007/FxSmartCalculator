class ParserHelper {
  static String cleanSymbol(String raw) {
    // <Geri gibi metinleri filtrele
    if (raw.contains('Geri') || raw.contains('→')) {
      return '';
    }

    // Sondan başlayarak harf/rakam olmayan karakterleri temizle
    final match = RegExp(r'([A-Z0-9]+)$').firstMatch(raw);
    return match?.group(1) ?? '';
  }
}
