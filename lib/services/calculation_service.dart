import '../models/symbol_model.dart';
import '../models/calculation_result.dart';
import 'exchange_rate_service.dart';

class CalculationService {
  static Future<CalculationResult> calculatePnL({
    required SymbolModel symbol,
    required double price,
    required double lot,
    double? tp,
    double? sl,
  }) async {
    final int contractSize = symbol.contractSize;
    final String currency = symbol.currency;

    double? profit;
    double? loss;

    final isBuy = tp != null && tp > price;

    if (tp != null) {
      profit = (isBuy ? (tp - price) : (price - tp)) * lot * contractSize;
    }

    if (sl != null) {
      loss = (isBuy ? (price - sl) : (sl - price)) * lot * contractSize;
    }

    // Döviz kuru USD değilse, çevir
    if (currency.toUpperCase() != 'USD') {
      final rateToUSD = await ExchangeRateService().getRateToUSD(currency);
      if (profit != null) profit *= rateToUSD;
      if (loss != null) loss *= rateToUSD;
    }

    return CalculationResult(profit: profit, loss: loss);
  }

  static double? calculateLotByRiskRatio({
    required double price,
    required double sl,
    required double balance,
    required double riskPercentage,
    required double contractSize,
  }) {
    final stopPoint = (price - sl).abs();

    if (stopPoint == 0 || contractSize == 0) return null;

    final maxLoss = balance * (riskPercentage / 100);
    final lot = maxLoss / (contractSize * stopPoint);

    return lot;
  }


}
