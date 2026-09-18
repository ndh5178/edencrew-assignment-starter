enum DailyPricePeriod {
  oneMonth(label: '1개월', pageCount: 2),
  threeMonths(label: '3개월', pageCount: 6),
  sixMonths(label: '6개월', pageCount: 12),
  oneYear(label: '1년', pageCount: 25);

  const DailyPricePeriod({required this.label, required this.pageCount});

  final String label;
  final int pageCount;
}

class DailyPrice {
  const DailyPrice({
    required this.localDate,
    required this.closePrice,
    required this.changeAmount,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
  });

  final String localDate;
  final int closePrice;
  final int changeAmount;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;
}
