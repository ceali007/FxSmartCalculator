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
      alternativeCodes: List<String>.from(json['alternativeCodes']),
      contractSize: json['contractSize'],
      digit: json['digit'],
      tickSize: (json['tickSize'] as num).toDouble(),
      currency: json['currency'],
      type: json['type'],
    );
  }
}
