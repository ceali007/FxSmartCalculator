class SymbolModel {
  final String symbol;
  final String name;
  final List<String> alternativeCodes;
  final int contractSize;
  final int digit;
  final double tickSize;
  final String currency;
  final String type;

  SymbolModel({
    required this.symbol,
    required this.name,
    required this.alternativeCodes,
    required this.contractSize,
    required this.digit,
    required this.tickSize,
    required this.currency,
    required this.type,
  });

  factory SymbolModel.fromJson(Map<String, dynamic> json) {
    return SymbolModel(
      symbol: json['symbol'],
      name: json['name'],
      alternativeCodes:
      (json['alternativeCodes'] as List<dynamic>).cast<String>(),
      contractSize: json['contractSize'],
      digit: json['digit'],
      tickSize: (json['tickSize'] as num).toDouble(),
      currency: json['currency'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'alternativeCodes': alternativeCodes,
      'contractSize': contractSize,
      'digit': digit,
      'tickSize': tickSize,
      'currency': currency,
      'type': type,
    };
  }

  // 🔽 Eşitlik kontrolü için yalnızca symbol dikkate alınır
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SymbolModel &&
              runtimeType == other.runtimeType &&
              symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;
}
