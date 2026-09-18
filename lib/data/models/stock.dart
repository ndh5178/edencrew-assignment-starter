class Stock {
  const Stock({
    required this.symbol,
    required this.name,
    required this.market,
  });

  final String symbol;
  final String name;
  final String market;

  String get canonicalId {
    return 'domestic:$symbol';
  }
}
