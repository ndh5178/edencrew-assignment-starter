import 'dart:convert';

import 'package:http/http.dart' as http;

import 'dtos/stock_search_dto.dart';
import 'dtos/stock_metadata_dto.dart';
import 'dtos/stock_quote_dto.dart';
import 'models/stock.dart';
import 'models/stock_quote.dart';

abstract interface class StockSearchService {
  Future<List<Stock>> searchStocks(String query);

  void close();
}

abstract interface class WatchlistService {
  Future<Stock> fetchStockMetadata(String symbol);

  Future<Map<String, StockQuote>> fetchQuotes(Iterable<String> symbols);
}

class NaverStockService implements StockSearchService, WatchlistService {
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

  @override
  Future<Stock> fetchStockMetadata(String symbol) async {
    final Uri uri = Uri.https(
      'stock.naver.com',
      '/api/securityFe/api/fchart/domestic/stock/$symbol',
    );
    final http.Response response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw StockServiceException(
        '종목 정보 요청에 실패했습니다. 상태 코드: ${response.statusCode}',
      );
    }

    final Object? decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

    if (decodedResponse is! Map<String, dynamic>) {
      throw const StockServiceException('종목 정보 응답 형식이 올바르지 않습니다.');
    }

    return StockMetadataDto.fromJson(decodedResponse).toModel();
  }

  @override
  Future<Map<String, StockQuote>> fetchQuotes(
    Iterable<String> symbols,
  ) async {
    final List<String> symbolList = symbols.toSet().toList();

    if (symbolList.isEmpty) {
      return <String, StockQuote>{};
    }

    final Uri uri = Uri.https(
      'polling.finance.naver.com',
      '/api/realtime',
      <String, String>{
        'query': 'SERVICE_ITEM:${symbolList.join(',')}',
      },
    );
    final http.Response response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw StockServiceException(
        '실시간 시세 요청에 실패했습니다. 상태 코드: ${response.statusCode}',
      );
    }

    final Object? decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
    final List<dynamic> rawQuotes = _readRealtimeQuoteList(decodedResponse);
    final Map<String, StockQuote> quotes = <String, StockQuote>{};

    for (final Object? rawQuote in rawQuotes) {
      if (rawQuote is! Map<String, dynamic>) {
        continue;
      }

      try {
        final StockQuote quote = StockQuoteDto.fromJson(rawQuote).toModel();
        quotes[quote.symbol] = quote;
      } on FormatException {
        continue;
      }
    }

    return quotes;
  }

  List<dynamic> _readRealtimeQuoteList(Object? decodedResponse) {
    if (decodedResponse is! Map<String, dynamic>) {
      throw const StockServiceException('실시간 시세 응답 형식이 올바르지 않습니다.');
    }

    final Object? rawResult = decodedResponse['result'];

    if (rawResult is! Map<String, dynamic>) {
      throw const StockServiceException('실시간 시세 결과가 없습니다.');
    }

    final Object? rawAreas = rawResult['areas'];

    if (rawAreas is! List<dynamic>) {
      throw const StockServiceException('실시간 시세 영역이 없습니다.');
    }

    for (final Object? rawArea in rawAreas) {
      if (rawArea is! Map<String, dynamic>) {
        continue;
      }

      if (rawArea['name'] != 'SERVICE_ITEM') {
        continue;
      }

      final Object? rawDatas = rawArea['datas'];

      if (rawDatas is List<dynamic>) {
        return rawDatas;
      }
    }

    return <dynamic>[];
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
