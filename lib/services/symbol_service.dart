import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/symbol_model.dart';

class SymbolService {
  Future<List<SymbolModel>> loadSymbols() async {
    final String jsonString =
    await rootBundle.loadString('assets/data/symbols.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => SymbolModel.fromJson(json)).toList();
  }

  Future<SymbolModel?> findSymbolByCode(String code) async {
    final symbols = await loadSymbols();
    for (final symbol in symbols) {
      if (symbol.symbol.toLowerCase() == code.toLowerCase() ||
          (symbol.alternativeCodes?.any((alt) =>
          alt.toLowerCase() == code.toLowerCase()) ??
              false)) {
        return symbol;
      }
    }
    return null;
  }
}
