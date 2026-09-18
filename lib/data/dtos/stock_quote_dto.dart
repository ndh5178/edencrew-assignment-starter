import '../models/stock_quote.dart';
import 'dto_parsing.dart';

class StockQuoteDto {
  const StockQuoteDto({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
    required this.countOfListedStock,
  });

  factory StockQuoteDto.fromJson(Map<String, dynamic> json) {
    return StockQuoteDto(
      symbol: readRequiredString(json['cd'], 'cd'),
      currentPrice: readRequiredInt(json['nv'], 'nv'),
      previousClose: readRequiredInt(json['pcv'], 'pcv'),
      openPrice: readRequiredInt(json['ov'], 'ov'),
      highPrice: readRequiredInt(json['hv'], 'hv'),
      lowPrice: readRequiredInt(json['lv'], 'lv'),
      accumulatedTradingVolume: readRequiredInt(json['aq'], 'aq'),
      countOfListedStock: readRequiredInt(
        json['countOfListedStock'],
        'countOfListedStock',
      ),
    );
  }

  final String symbol;
  final int currentPrice;
  final int previousClose;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;
  final int countOfListedStock;

  StockQuote toModel() {
    return StockQuote(
      symbol: symbol,
      currentPrice: currentPrice,
      previousClose: previousClose,
      openPrice: openPrice,
      highPrice: highPrice,
      lowPrice: lowPrice,
      accumulatedTradingVolume: accumulatedTradingVolume,
      countOfListedStock: countOfListedStock,
    );
  }
}
