class StockQuote {
  const StockQuote({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
    required this.countOfListedStock,
  });

  final String symbol;
  final int currentPrice;
  final int previousClose;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;
  final int countOfListedStock;

  int get changeAmount {
    return currentPrice - previousClose;
  }

  double get changeRate {
    if (previousClose == 0) {
      return 0;
    }

    return changeAmount / previousClose * 100;
  }

  int get marketCapitalization {
    return currentPrice * countOfListedStock;
  }
}
