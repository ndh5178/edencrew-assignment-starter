import 'dart:convert';

import 'package:edencrew_assignment_starter/data/models/stock.dart';
import 'package:edencrew_assignment_starter/data/naver_stock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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

    expect(
      service.searchStocks('삼성'),
      throwsA(isA<StockServiceException>()),
    );
  });
}
