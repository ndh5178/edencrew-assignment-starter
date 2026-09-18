import 'dart:convert';

import 'package:http/http.dart' as http;

import 'dtos/stock_search_dto.dart';
import 'models/stock.dart';

abstract interface class StockSearchService {
  Future<List<Stock>> searchStocks(String query);

  void close();
}

class NaverStockService implements StockSearchService {
  NaverStockService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<List<Stock>> searchStocks(String query) async {
    final String normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return <Stock>[];
    }

    final Uri uri = Uri.https(
      'ac.stock.naver.com',
      '/ac',
      <String, String>{
        'q': normalizedQuery,
        'target': 'stock,ipo,index,marketindicator',
      },
    );

    final http.Response response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw StockServiceException(
        '종목 검색 요청에 실패했습니다. 상태 코드: ${response.statusCode}',
      );
    }

    final Object? decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

    if (decodedResponse is! Map<String, dynamic>) {
      throw const StockServiceException('종목 검색 응답 형식이 올바르지 않습니다.');
    }

    final Object? rawItems = decodedResponse['items'];

    if (rawItems is! List<dynamic>) {
      throw const StockServiceException('종목 검색 결과가 올바르지 않습니다.');
    }

    final List<Stock> stocks = <Stock>[];

    for (final Object? rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic>) {
        continue;
      }

      final StockSearchDto dto;

      try {
        dto = StockSearchDto.fromJson(rawItem);
      } on FormatException {
        continue;
      }

      if (!_isDomesticStock(dto)) {
        continue;
      }

      stocks.add(dto.toModel());
    }

    return stocks;
  }

  bool _isDomesticStock(StockSearchDto dto) {
    final RegExp sixDigitSymbol = RegExp(r'^\d{6}$');

    return dto.nationCode == 'KOR' &&
        dto.category == 'stock' &&
        sixDigitSymbol.hasMatch(dto.code);
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class StockServiceException implements Exception {
  const StockServiceException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
