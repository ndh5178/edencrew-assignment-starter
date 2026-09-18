import '../models/stock.dart';
import 'dto_parsing.dart';

class StockMetadataDto {
  const StockMetadataDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  factory StockMetadataDto.fromJson(Map<String, dynamic> json) {
    return StockMetadataDto(
      symbolCode: readRequiredString(json['symbolCode'], 'symbolCode'),
      stockName: readRequiredString(json['stockName'], 'stockName'),
      stockExchangeNameKor: readRequiredString(
        json['stockExchangeNameKor'],
        'stockExchangeNameKor',
      ),
    );
  }

  final String symbolCode;
  final String stockName;
  final String stockExchangeNameKor;

  Stock toModel() {
    return Stock(
      symbol: symbolCode,
      name: stockName,
      market: stockExchangeNameKor,
    );
  }
}
