import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/parsed_trade_data.dart';
import '../utils/parser_helper.dart';



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

    // SEMBOL PARSE
    for (final line in lines) {
      if (line.contains('v')) {
        final rawSymbol = line.split('v')[0].trim();
        final cleaned = ParserHelper.cleanSymbol(rawSymbol);
        if (cleaned.isNotEmpty) {
          symbol = cleaned;
          break;
        }
      }
    }

    // TP parse
    for (int i = 0; i < lines.length - 2; i++) {
      if (lines[i].toLowerCase().contains('kârı al') || lines[i].toLowerCase().contains('karı al')) {
        final candidate = _tryParseDouble(lines[i + 1]);
        if (candidate != null) {
          tp = candidate;
          break;
        }
      }
    }

    // SL parse
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

    // Price parse
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
