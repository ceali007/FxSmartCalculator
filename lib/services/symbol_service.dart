import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/symbol_model.dart';
import '../utils/parser_helper.dart';

class SymbolService {
  Future<List<SymbolModel>> getAllSymbols() async {
    final String response = await rootBundle.loadString('assets/data/symbols.json');
    final List<dynamic> data = json.decode(response);
    return data.map((json) => SymbolModel.fromJson(json)).toList();
  }

  Future<SymbolModel?> getSymbol(String rawSymbol) async {
    final cleaned = ParserHelper.cleanSymbol(rawSymbol);
    final symbols = await getAllSymbols();

    for (final symbol in symbols) {
      if (symbol.symbol.toLowerCase() == cleaned.toLowerCase()) {
        return symbol;
      }
      if (symbol.alternativeCodes.any(
              (code) => code.toLowerCase() == cleaned.toLowerCase())) {
        return symbol;
      }
    }
    return null;
  }
}
