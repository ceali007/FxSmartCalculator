import '../models/symbol_model.dart';
import '../models/calculation_result.dart';

class CalculationService {
  static CalculationResult calculatePnL({
    required SymbolModel symbol,
    required double price,
    required double lot,
    double? tp,
    double? sl,
  }) {
    final contractSize = symbol.contractSize;
    double? profit;
    double? loss;

    final isBuy = tp != null && tp > price;
    final isSell = tp != null && tp < price;

    if (tp != null && tp > 0) {
      final diff = (tp - price).abs();
      final value = lot * contractSize * diff;
      if (isBuy || isSell) {
        profit = value;
      }
    }

    if (sl != null && sl > 0) {
      final diff = (price - sl).abs();
      final value = lot * contractSize * diff;
      if (isBuy || isSell) {
        loss = value;
      }
    }

    return CalculationResult(profit: profit, loss: loss);
  }
}