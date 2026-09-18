import '../models/daily_price.dart';
import 'dto_parsing.dart';

class DailyPriceDto {
  const DailyPriceDto({
    required this.localDate,
    required this.closePrice,
    required this.changeAmount,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
  });

  factory DailyPriceDto.fromJson(Map<String, dynamic> json) {
    return DailyPriceDto(
      localDate: readRequiredString(
        json['localTradedAt'],
        'localTradedAt',
      ).replaceAll('-', ''),
      closePrice: readRequiredInt(json['closePrice'], 'closePrice'),
      changeAmount: readRequiredInt(
        json['compareToPreviousClosePrice'],
        'compareToPreviousClosePrice',
      ),
      openPrice: readRequiredInt(json['openPrice'], 'openPrice'),
      highPrice: readRequiredInt(json['highPrice'], 'highPrice'),
      lowPrice: readRequiredInt(json['lowPrice'], 'lowPrice'),
      accumulatedTradingVolume: readRequiredInt(
        json['accumulatedTradingVolume'],
        'accumulatedTradingVolume',
      ),
    );
  }

  final String localDate;
  final int closePrice;
  final int changeAmount;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;

  DailyPrice toModel() {
    return DailyPrice(
      localDate: localDate,
      closePrice: closePrice,
      changeAmount: changeAmount,
      openPrice: openPrice,
      highPrice: highPrice,
      lowPrice: lowPrice,
      accumulatedTradingVolume: accumulatedTradingVolume,
    );
  }
}
