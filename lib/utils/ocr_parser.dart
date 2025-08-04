import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ParsedTradeData {
  final String? symbol;
  final double? tp;
  final double? sl;
  final double? price;

  ParsedTradeData({this.symbol, this.tp, this.sl, this.price});

  bool get isValid => symbol != null && (tp != null || sl != null);
}

class OCRParser {
  static ParsedTradeData parse(RecognizedText recognizedText) {
    final List<_TextLineWithPosition> sortedLines = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final rect = line.boundingBox;
        if (rect != null) {
          sortedLines.add(
            _TextLineWithPosition(line.text.trim(), rect.top.toDouble(), rect.left.toDouble()),
          );
        }
      }
    }

    // Yukarıdan aşağıya, soldan sağa sırala
    sortedLines.sort((a, b) {
      const rowThreshold = 10.0;
      if ((a.top - b.top).abs() < rowThreshold) {
        return a.left.compareTo(b.left);
      } else {
        return a.top.compareTo(b.top);
      }
    });

    final lines = sortedLines.map((e) => e.text).toList();

    String? symbol;
    double? tp;
    double? sl;
    double? price;

    // SEMBOL: önceki başarılı algoritmadan alınan yöntem
    for (var line in lines) {
      if (line.contains('v')) {
        final match = RegExp(r'([A-Z]+[0-9]*)(?=v)').firstMatch(line);
        if (match != null) {
          symbol = match.group(1);
          break;
        }
      }
    }

    // TP değeri: "Kârı Al" sonrası gelen sayı
    for (int i = 0; i < lines.length - 2; i++) {
      if (lines[i].toLowerCase().contains('kârı al') || lines[i].toLowerCase().contains('karı al')) {
        final candidate = _tryParseDouble(lines[i + 1]);
        if (candidate != null) {
          tp = candidate;
          break;
        }
      }
    }

    // SL değeri: "Zararı Durdur" sonrası gelen sayı
    for (int i = 0; i < lines.length - 2; i++) {
      if (lines[i].toLowerCase().contains('zararı durdur')) {
        if (lines[i + 1].toLowerCase().contains('ayarlanmamış')) {
          sl = 0;
        } else {
          final candidate = _tryParseDouble(lines[i + 1]);
          if (candidate != null) {
            sl = candidate;
          }
        }
        break;
      }
    }

    // FİYAT: En büyük sayı olarak belirle
    final allNumbers = lines.map(_tryParseDouble).whereType<double>().toList();
    if (allNumbers.isNotEmpty) {
      price = allNumbers.reduce((a, b) => a > b ? a : b);
    }

    return ParsedTradeData(symbol: symbol, tp: tp, sl: sl, price: price);
  }

  static double? _tryParseDouble(String value) {
    value = value.replaceAll(',', '.');
    return double.tryParse(value);
  }
}

class _TextLineWithPosition {
  final String text;
  final double top;
  final double left;

  _TextLineWithPosition(this.text, this.top, this.left);
}
