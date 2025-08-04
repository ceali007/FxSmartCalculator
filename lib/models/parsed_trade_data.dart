class ParsedTradeData {
  final String? symbol;
  final double? tp;
  final double? sl;
  final double? price;

  ParsedTradeData({
    this.symbol,
    this.tp,
    this.sl,
    this.price,
  });

  bool get isValid => symbol != null && (tp != null || sl != null);
}