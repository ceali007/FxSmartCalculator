import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/symbol_model.dart';

class SymbolService {
  List<SymbolModel>? _cachedSymbols;

  Future<List<SymbolModel>> _loadSymbols() async {
    if (_cachedSymbols != null) return _cachedSymbols!;
    final String jsonString =
    await rootBundle.loadString('assets/data/symbols.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _cachedSymbols = jsonList.map((e) => SymbolModel.fromJson(e)).toList();
    return _cachedSymbols!;
  }

  Future<SymbolModel?> getSymbol(String code) async {
    final symbols = await _loadSymbols();
    final upperCode = code.toUpperCase();

    print('[DEBUG] Aranan kod: $upperCode');

    for (final symbol in symbols) {
      print('[DEBUG] Karşılaştırılan ana kod: ${symbol.symbol.toUpperCase()}');
      print('[DEBUG] Alternatif kodlar: ${symbol.alternativeCodes.map((e) => e.toUpperCase()).join(', ')}');

      if (symbol.symbol.toUpperCase() == upperCode ||
          symbol.alternativeCodes.map((e) => e.toUpperCase()).contains(upperCode)) {
        print('[DEBUG] EŞLEŞME BULUNDU: ${symbol.symbol}');
        return symbol;
      }
    }

    print('[DEBUG] Eşleşme bulunamadı.');
    return null;
  }

}
