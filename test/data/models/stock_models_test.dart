import 'package:edencrew_assignment_starter/data/dtos/dtos.dart';
import 'package:edencrew_assignment_starter/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Stock', () {
    test('검색 API 응답을 종목 모델로 변환한다', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'code': '005930',
        'name': '삼성전자',
        'typeName': '코스피',
        'nationCode': 'KOR',
        'category': 'stock',
      };

      final StockSearchDto dto = StockSearchDto.fromJson(json);
      final Stock stock = dto.toModel();

      expect(stock.symbol, '005930');
      expect(stock.name, '삼성전자');
      expect(stock.market, '코스피');
      expect(stock.canonicalId, 'domestic:005930');
    });

    test('메타데이터 API 응답을 종목 모델로 변환한다', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'symbolCode': '005930',
        'stockName': '삼성전자',
        'stockExchangeNameKor': '코스피',
      };

      final StockMetadataDto dto = StockMetadataDto.fromJson(json);
      final Stock stock = dto.toModel();

      expect(stock.symbol, '005930');
      expect(stock.name, '삼성전자');
      expect(stock.market, '코스피');
    });
  });

  group('StockQuote', () {
    test('실시간 시세 응답을 변환하고 등락 정보를 계산한다', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'cd': '005930',
        'nv': 179700,
        'pcv': 180100,
        'ov': 172100,
        'hv': 181700,
        'lv': 172000,
        'aq': 29113466,
        'countOfListedStock': 5919637922,
      };

      final StockQuoteDto dto = StockQuoteDto.fromJson(json);
      final StockQuote quote = dto.toModel();

      expect(quote.symbol, '005930');
      expect(quote.changeAmount, -400);
      expect(quote.changeRate, closeTo(-0.22, 0.01));
      expect(
        quote.marketCapitalization,
        179700 * 5919637922,
      );
    });

    test('쉼표가 포함된 문자열 가격도 정수로 변환한다', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'cd': '005930',
        'nv': '179,700',
        'pcv': '180,100',
        'ov': '172,100',
        'hv': '181,700',
        'lv': '172,000',
        'aq': '29,113,466',
        'countOfListedStock': '5,919,637,922',
      };

      final StockQuoteDto dto = StockQuoteDto.fromJson(json);
      final StockQuote quote = dto.toModel();

      expect(quote.currentPrice, 179700);
      expect(quote.accumulatedTradingVolume, 29113466);
    });
  });

  test('StockDetail은 종목 정보와 실시간 시세를 함께 가진다', () {
    const Stock stock = Stock(
      symbol: '005930',
      name: '삼성전자',
      market: '코스피',
    );
    const StockQuote quote = StockQuote(
      symbol: '005930',
      currentPrice: 179700,
      previousClose: 180100,
      openPrice: 172100,
      highPrice: 181700,
      lowPrice: 172000,
      accumulatedTradingVolume: 29113466,
      countOfListedStock: 5919637922,
    );

    const StockDetail detail = StockDetail(stock: stock, quote: quote);

    expect(detail.stock.name, '삼성전자');
    expect(detail.quote.currentPrice, 179700);
  });

  test('DailyPrice는 일별 시세에 필요한 값을 가진다', () {
    const DailyPrice dailyPrice = DailyPrice(
      localDate: '20260327',
      closePrice: 179700,
      changeAmount: -400,
      openPrice: 172100,
      highPrice: 181700,
      lowPrice: 172000,
      accumulatedTradingVolume: 29113466,
    );

    expect(dailyPrice.localDate, '20260327');
    expect(dailyPrice.changeAmount, -400);
    expect(dailyPrice.highPrice, 181700);
  });
}
