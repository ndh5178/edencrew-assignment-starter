import 'stock.dart';
import 'stock_quote.dart';

class StockDetail {
  const StockDetail({
    required this.stock,
    required this.quote,
  });

  final Stock stock;
  final StockQuote quote;
}
