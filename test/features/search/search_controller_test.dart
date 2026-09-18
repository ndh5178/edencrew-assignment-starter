import 'dart:async';

import 'package:edencrew_assignment_starter/data/models/stock.dart';
import 'package:edencrew_assignment_starter/data/naver_stock_service.dart';
import 'package:edencrew_assignment_starter/features/search/search_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('검색 결과가 있으면 success 상태가 된다', () async {
    final _ImmediateSearchService service = _ImmediateSearchService(
      results: const <Stock>[
        Stock(symbol: '005930', name: '삼성전자', market: '코스피'),
      ],
    );
    final StockSearchController controller = StockSearchController(
      searchService: service,
      debounceDuration: Duration.zero,
    );

    controller.onQueryChanged('삼성');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, SearchStatus.success);
    expect(controller.results.first.symbol, '005930');

    controller.dispose();
  });

  test('검색 결과가 없으면 empty 상태가 된다', () async {
    final _ImmediateSearchService service = _ImmediateSearchService(
      results: <Stock>[],
    );
    final StockSearchController controller = StockSearchController(
      searchService: service,
      debounceDuration: Duration.zero,
    );

    controller.onQueryChanged('없는종목');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, SearchStatus.empty);

    controller.dispose();
  });

  test('이전 검색보다 최신 검색 결과만 반영한다', () async {
    final _ControlledSearchService service = _ControlledSearchService();
    final StockSearchController controller = StockSearchController(
      searchService: service,
      debounceDuration: Duration.zero,
    );

    controller.onQueryChanged('삼성');
    await Future<void>.delayed(Duration.zero);

    controller.onQueryChanged('카카오');
    await Future<void>.delayed(Duration.zero);

    service.complete(
      '카카오',
      const <Stock>[
        Stock(symbol: '035720', name: '카카오', market: '코스피'),
      ],
    );
    await Future<void>.delayed(Duration.zero);

    service.complete(
      '삼성',
      const <Stock>[
        Stock(symbol: '005930', name: '삼성전자', market: '코스피'),
      ],
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, SearchStatus.success);
    expect(controller.results.first.symbol, '035720');

    controller.dispose();
  });
}

class _ImmediateSearchService implements StockSearchService {
  _ImmediateSearchService({required this.results});

  final List<Stock> results;

  @override
  Future<List<Stock>> searchStocks(String query) async {
    return results;
  }

  @override
  void close() {}
}

class _ControlledSearchService implements StockSearchService {
  final Map<String, Completer<List<Stock>>> _requests =
      <String, Completer<List<Stock>>>{};

  @override
  Future<List<Stock>> searchStocks(String query) {
    final Completer<List<Stock>> completer = Completer<List<Stock>>();
    _requests[query] = completer;
    return completer.future;
  }

  void complete(String query, List<Stock> results) {
    _requests[query]!.complete(results);
  }

  @override
  void close() {}
}
