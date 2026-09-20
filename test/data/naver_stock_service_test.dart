import 'dart:convert';

import 'package:edencrew_assignment_starter/data/models/stock.dart';
import 'package:edencrew_assignment_starter/data/models/daily_price.dart';
import 'package:edencrew_assignment_starter/data/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/data/naver_stock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('겹치는 기간과 동시 요청은 일봉 페이지를 공유한다', () async {
    final calls = <int, int>{};
    final client = MockClient((request) async {
      final page = int.parse(request.url.queryParameters['page']!);
      calls.update(page, (count) => count + 1, ifAbsent: () => 1);
      await Future<void>.delayed(Duration.zero);
      return http.Response('''
        <table class="type2"><tr>
          <td>2026.03.27</td><td>100</td><td>1</td><td>99</td>
          <td>101</td><td>98</td><td>1000</td>
        </tr></table><table><tr><td class="pgRR"><a href="?page=25">last</a></td></tr></table>
      ''', 200);
    });
    final service = NaverStockService(client: client);
    await Future.wait([
      service.fetchDailyPrices('005930', DailyPricePeriod.oneMonth),
      service.fetchDailyPrices('005930', DailyPricePeriod.threeMonths),
    ]);
    expect(calls.length, 6);
    expect(calls.values, everyElement(1));
    await service.fetchDailyPrices('005930', DailyPricePeriod.oneMonth);
    expect(calls.values, everyElement(1));
    client.close();
  });
  test('국내 6자리 주식만 검색 결과 모델로 변환한다', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.url.host, 'ac.stock.naver.com');
      expect(request.url.queryParameters['q'], '삼성');

      final Map<String, dynamic> responseBody = <String, dynamic>{
        'query': '삼성',
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'code': '005930',
            'name': '삼성전자',
            'typeName': '코스피',
            'nationCode': 'KOR',
            'category': 'stock',
          },
          <String, dynamic>{
            'code': 'TSLA',
            'name': '테슬라',
            'typeName': '나스닥',
            'nationCode': 'USA',
            'category': 'stock',
          },
          <String, dynamic>{
            'code': 'KOSPI',
            'name': '코스피',
            'typeName': '지수',
            'nationCode': 'KOR',
            'category': 'index',
          },
        ],
      };

      return http.Response(
        jsonEncode(responseBody),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final NaverStockService service = NaverStockService(client: client);

    final List<Stock> results = await service.searchStocks('삼성');

    expect(results, hasLength(1));
    expect(results.first.symbol, '005930');
    expect(results.first.name, '삼성전자');
  });

  test('검색 API가 실패하면 서비스 예외를 전달한다', () async {
    final MockClient client = MockClient((http.Request request) async {
      return http.Response('server error', 500);
    });
    final NaverStockService service = NaverStockService(client: client);

    expect(service.searchStocks('삼성'), throwsA(isA<StockServiceException>()));
  });

  test('종목 메타데이터 응답을 Stock 모델로 변환한다', () async {
    final MockClient client = MockClient((http.Request request) async {
      final Map<String, dynamic> responseBody = <String, dynamic>{
        'symbolCode': '005930',
        'stockName': '삼성전자',
        'stockExchangeNameKor': '코스피',
      };

      return http.Response.bytes(
        utf8.encode(jsonEncode(responseBody)),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );
    });
    final NaverStockService service = NaverStockService(client: client);

    final Stock stock = await service.fetchStockMetadata('005930');

    expect(stock.symbol, '005930');
    expect(stock.name, '삼성전자');
    expect(stock.market, '코스피');
  });

  test('여러 종목의 실시간 시세를 한 번에 변환한다', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(
        request.url.queryParameters['query'],
        'SERVICE_ITEM:005930,000660',
      );

      final Map<String, dynamic> responseBody = <String, dynamic>{
        'resultCode': 'success',
        'result': <String, dynamic>{
          'areas': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'SERVICE_ITEM',
              'datas': <Map<String, dynamic>>[
                _quoteJson('005930', 179700, 180100),
                _quoteJson('000660', 412500, 403000),
              ],
            },
          ],
        },
      };

      return http.Response(jsonEncode(responseBody), 200);
    });
    final NaverStockService service = NaverStockService(client: client);

    final Map<String, StockQuote> quotes = await service.fetchQuotes(<String>[
      '005930',
      '000660',
    ]);

    expect(quotes, hasLength(2));
    expect(quotes['005930']!.changeAmount, -400);
    expect(quotes['000660']!.changeAmount, 9500);
  });

  test('일별 시세 HTML을 날짜와 가격 모델로 변환한다', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.url.host, 'finance.naver.com');
      expect(request.headers['User-Agent'], 'Mozilla/5.0');

      const String html = '''
        <table class="type2">
          <tr>
            <td><span>2026.03.27</span></td>
            <td><span>179,700</span></td>
            <td class="num nv01"><span>400</span></td>
            <td><span>172,100</span></td>
            <td><span>181,700</span></td>
            <td><span>172,000</span></td>
            <td><span>29,113,466</span></td>
          </tr>
        </table>
      ''';

      return http.Response.bytes(latin1.encode(html), 200);
    });
    final NaverStockService service = NaverStockService(client: client);

    final List<DailyPrice> prices = await service.fetchDailyPrices(
      '005930',
      DailyPricePeriod.oneMonth,
    );

    expect(prices, hasLength(1));
    expect(prices.first.localDate, '20260327');
    expect(prices.first.changeAmount, -400);
    expect(prices.first.accumulatedTradingVolume, 29113466);
  });

  test('기존 HTML 요청이 실패하면 일별 시세 JSON으로 전환한다', () async {
    final MockClient client = MockClient((http.Request request) async {
      if (request.url.host == 'finance.naver.com') {
        return http.Response('forbidden', 403);
      }

      final int page = int.parse(request.url.queryParameters['page']!);

      if (page > 1) {
        return http.Response('[]', 200);
      }

      final List<Map<String, dynamic>> responseBody = <Map<String, dynamic>>[
        <String, dynamic>{
          'localTradedAt': '2026-03-27',
          'closePrice': '179,700',
          'compareToPreviousClosePrice': '-400',
          'openPrice': '172,100',
          'highPrice': '181,700',
          'lowPrice': '172,000',
          'accumulatedTradingVolume': 29113466,
        },
      ];

      return http.Response(jsonEncode(responseBody), 200);
    });
    final NaverStockService service = NaverStockService(client: client);

    final List<DailyPrice> prices = await service.fetchDailyPrices(
      '005930',
      DailyPricePeriod.oneMonth,
    );

    expect(prices, hasLength(1));
    expect(prices.first.closePrice, 179700);
  });
}

Map<String, dynamic> _quoteJson(
  String symbol,
  int currentPrice,
  int previousClose,
) {
  return <String, dynamic>{
    'cd': symbol,
    'nv': currentPrice,
    'pcv': previousClose,
    'ov': currentPrice,
    'hv': currentPrice,
    'lv': currentPrice,
    'aq': 1000,
    'countOfListedStock': 1000000,
  };
}
