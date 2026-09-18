import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'dtos/daily_price_dto.dart';
import 'dtos/stock_search_dto.dart';
import 'dtos/stock_metadata_dto.dart';
import 'dtos/stock_quote_dto.dart';
import 'models/stock.dart';
import 'models/daily_price.dart';
import 'models/stock_quote.dart';

abstract interface class StockSearchService {
  Future<List<Stock>> searchStocks(String query);

  void close();
}

abstract interface class WatchlistService {
  Future<Stock> fetchStockMetadata(String symbol);

  Future<Map<String, StockQuote>> fetchQuotes(Iterable<String> symbols);
}

abstract interface class DailyPriceService {
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    DailyPricePeriod period,
  );
}

class NaverStockService
    implements StockSearchService, WatchlistService, DailyPriceService {
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

    final Uri uri = Uri.https('ac.stock.naver.com', '/ac', <String, String>{
      'q': normalizedQuery,
      'target': 'stock,ipo,index,marketindicator',
    });

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
  Future<Map<String, StockQuote>> fetchQuotes(Iterable<String> symbols) async {
    final List<String> symbolList = symbols.toSet().toList();

    if (symbolList.isEmpty) {
      return <String, StockQuote>{};
    }

    final Uri uri = Uri.https(
      'polling.finance.naver.com',
      '/api/realtime',
      <String, String>{'query': 'SERVICE_ITEM:${symbolList.join(',')}'},
    );
    final http.Response response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw StockServiceException(
        '실시간 시세 요청에 실패했습니다. 상태 코드: ${response.statusCode}',
      );
    }

    // 실시간 시세 API는 `EUC-KR` 응답을 사용합니다.
    // 현재 사용하는 시세 필드는 영문 키와 숫자이므로 JSON 구조가 보존되는
    // latin1로 읽고, EUC-KR인 종목명 필드는 검색 API의 값을 사용합니다.
    final String responseText = latin1.decode(response.bodyBytes);
    final Object? decodedResponse = jsonDecode(responseText);
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

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    DailyPricePeriod period,
  ) async {
    final List<DailyPrice> prices = <DailyPrice>[];
    bool useJsonFallback = false;

    for (int page = 1; page <= period.pageCount; page += 1) {
      if (useJsonFallback) {
        prices.addAll(await _fetchDailyPriceJsonPage(symbol, page));
        continue;
      }

      final _DailyPriceHtmlPage htmlPage;

      try {
        htmlPage = await _fetchDailyPriceHtmlPage(symbol, page);
      } on Object {
        useJsonFallback = true;
        prices.addAll(await _fetchDailyPriceJsonPage(symbol, page));
        continue;
      }

      if (htmlPage.prices.isEmpty) {
        useJsonFallback = true;
        prices.addAll(await _fetchDailyPriceJsonPage(symbol, page));
        continue;
      }

      prices.addAll(htmlPage.prices);

      if (page >= htmlPage.lastPage) {
        break;
      }
    }

    prices.sort((DailyPrice first, DailyPrice second) {
      return second.localDate.compareTo(first.localDate);
    });

    return prices;
  }

  Future<_DailyPriceHtmlPage> _fetchDailyPriceHtmlPage(
    String symbol,
    int page,
  ) async {
    final Uri uri = Uri.https(
      'finance.naver.com',
      '/item/sise_day.naver',
      <String, String>{'code': symbol, 'page': '$page'},
    );
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{'User-Agent': 'Mozilla/5.0'},
    );

    if (response.statusCode != 200) {
      throw StockServiceException(
        '일별 시세 요청에 실패했습니다. 상태 코드: ${response.statusCode}',
      );
    }

    // 이 HTML은 EUC-KR이지만 필요한 날짜, 숫자, class 값은 ASCII입니다.
    final String htmlText = latin1.decode(response.bodyBytes);
    final Document document = html_parser.parse(htmlText);
    final List<DailyPrice> prices = <DailyPrice>[];
    final List<Element> rows = document.querySelectorAll('table.type2 tr');

    for (final Element row in rows) {
      final List<Element> cells = row.querySelectorAll('td');

      if (cells.length != 7) {
        continue;
      }

      final String localDate = cells[0].text.trim().replaceAll('.', '');

      if (!RegExp(r'^\d{8}$').hasMatch(localDate)) {
        continue;
      }

      final int unsignedChange = _readHtmlNumber(cells[2].text);
      final String changeClass = cells[2].className;
      final int changeAmount;

      if (changeClass.contains('nv01')) {
        changeAmount = -unsignedChange;
      } else {
        changeAmount = unsignedChange;
      }

      prices.add(
        DailyPriceDto(
          localDate: localDate,
          closePrice: _readHtmlNumber(cells[1].text),
          changeAmount: changeAmount,
          openPrice: _readHtmlNumber(cells[3].text),
          highPrice: _readHtmlNumber(cells[4].text),
          lowPrice: _readHtmlNumber(cells[5].text),
          accumulatedTradingVolume: _readHtmlNumber(cells[6].text),
        ).toModel(),
      );
    }

    int lastPage = page;
    final List<Element> pageLinks = document.querySelectorAll(
      '.pgRR a, td.pgRR a',
    );

    for (final Element link in pageLinks) {
      final String href = link.attributes['href'] ?? '';
      final RegExpMatch? match = RegExp(r'page=(\d+)').firstMatch(href);

      if (match != null) {
        lastPage = int.parse(match.group(1)!);
      }
    }

    return _DailyPriceHtmlPage(prices: prices, lastPage: lastPage);
  }

  Future<List<DailyPrice>> _fetchDailyPriceJsonPage(
    String symbol,
    int page,
  ) async {
    final Uri uri = Uri.https(
      'm.stock.naver.com',
      '/api/stock/$symbol/price',
      <String, String>{'pageSize': '10', 'page': '$page'},
    );
    final http.Response response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw StockServiceException(
        '일별 시세 대체 요청에 실패했습니다. 상태 코드: ${response.statusCode}',
      );
    }

    final Object? decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

    if (decodedResponse is! List<dynamic>) {
      throw const StockServiceException('일별 시세 응답 형식이 올바르지 않습니다.');
    }

    final List<DailyPrice> prices = <DailyPrice>[];

    for (final Object? rawPrice in decodedResponse) {
      if (rawPrice is! Map<String, dynamic>) {
        continue;
      }

      try {
        prices.add(DailyPriceDto.fromJson(rawPrice).toModel());
      } on FormatException {
        continue;
      }
    }

    return prices;
  }

  int _readHtmlNumber(String value) {
    final String normalizedValue = value.replaceAll(',', '').trim();
    return int.parse(normalizedValue);
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

class _DailyPriceHtmlPage {
  const _DailyPriceHtmlPage({required this.prices, required this.lastPage});

  final List<DailyPrice> prices;
  final int lastPage;
}

class StockServiceException implements Exception {
  const StockServiceException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
