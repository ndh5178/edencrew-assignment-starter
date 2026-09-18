import 'dart:async';

import 'package:edencrew_assignment_starter/data/favorite_storage.dart';
import 'package:edencrew_assignment_starter/data/models/stock.dart';
import 'package:edencrew_assignment_starter/data/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/data/naver_stock_service.dart';
import 'package:edencrew_assignment_starter/features/favorites/favorite_controller.dart';
import 'package:edencrew_assignment_starter/features/watchlist/watchlist_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('관심 종목이 없으면 empty 상태가 된다', () async {
    final FavoriteController favoriteController = FavoriteController(
      storage: _MemoryFavoriteStorage(),
    );
    await favoriteController.initialize();
    final WatchlistController watchlistController = WatchlistController(
      favoriteController: favoriteController,
      watchlistService: _FakeWatchlistService(),
    );

    watchlistController.initialize();

    expect(watchlistController.status, WatchlistStatus.empty);

    watchlistController.dispose();
    favoriteController.dispose();
  });

  test('관심 종목의 메타데이터와 시세를 불러온다', () async {
    final FavoriteController favoriteController = FavoriteController(
      storage: _MemoryFavoriteStorage(
        initialSymbols: <String>{'005930'},
      ),
    );
    await favoriteController.initialize();
    final WatchlistController watchlistController = WatchlistController(
      favoriteController: favoriteController,
      watchlistService: _FakeWatchlistService(),
    );

    watchlistController.initialize();
    await _waitUntilLoaded(watchlistController);

    expect(watchlistController.status, WatchlistStatus.success);
    expect(watchlistController.sortedItems, hasLength(1));
    expect(watchlistController.sortedItems.first.stock.name, '삼성전자');
    expect(
      watchlistController.sortedItems.first.quote!.currentPrice,
      179700,
    );

    watchlistController.dispose();
    favoriteController.dispose();
  });

  test('현재가순과 등락률순으로 정렬한다', () async {
    final FavoriteController favoriteController = FavoriteController(
      storage: _MemoryFavoriteStorage(
        initialSymbols: <String>{'005930', '000660'},
      ),
    );
    await favoriteController.initialize();
    final WatchlistController watchlistController = WatchlistController(
      favoriteController: favoriteController,
      watchlistService: _FakeWatchlistService(),
    );
    watchlistController.initialize();
    await _waitUntilLoaded(watchlistController);

    watchlistController.selectSort(WatchlistSort.currentPrice);
    expect(watchlistController.sortedItems.first.stock.symbol, '000660');

    watchlistController.selectSort(WatchlistSort.changeRate);
    expect(watchlistController.sortedItems.first.stock.symbol, '000660');

    watchlistController.dispose();
    favoriteController.dispose();
  });

  test('시세 새로고침이 실패해도 기존 가격을 유지한다', () async {
    final FavoriteController favoriteController = FavoriteController(
      storage: _MemoryFavoriteStorage(
        initialSymbols: <String>{'005930'},
      ),
    );
    await favoriteController.initialize();
    final _FakeWatchlistService service = _FakeWatchlistService();
    final WatchlistController watchlistController = WatchlistController(
      favoriteController: favoriteController,
      watchlistService: service,
    );
    watchlistController.initialize();
    await _waitUntilLoaded(watchlistController);

    service.shouldFailQuotes = true;
    await watchlistController.refreshQuotes();

    expect(watchlistController.hasQuoteLoadFailure, isTrue);
    expect(
      watchlistController.sortedItems.first.quote!.currentPrice,
      179700,
    );

    watchlistController.dispose();
    favoriteController.dispose();
  });
}

Future<void> _waitUntilLoaded(WatchlistController controller) async {
  if (controller.status == WatchlistStatus.success &&
      !controller.isRefreshingQuotes) {
    return;
  }

  final Completer<void> completer = Completer<void>();

  void listener() {
    if (controller.status == WatchlistStatus.success &&
        !controller.isRefreshingQuotes &&
        !completer.isCompleted) {
      completer.complete();
    }
  }

  controller.addListener(listener);
  await completer.future.timeout(const Duration(seconds: 1));
  controller.removeListener(listener);
}

class _MemoryFavoriteStorage implements FavoriteStorage {
  _MemoryFavoriteStorage({Set<String>? initialSymbols})
      : _symbols = initialSymbols ?? <String>{};

  final Set<String> _symbols;

  @override
  Future<List<String>> loadFavoriteSymbols() async {
    return _symbols.toList();
  }

  @override
  Future<void> saveFavoriteSymbols(Iterable<String> symbols) async {
    _symbols
      ..clear()
      ..addAll(symbols);
  }
}

class _FakeWatchlistService implements WatchlistService {
  bool shouldFailQuotes = false;

  @override
  Future<Stock> fetchStockMetadata(String symbol) async {
    if (symbol == '005930') {
      return const Stock(
        symbol: '005930',
        name: '삼성전자',
        market: '코스피',
      );
    }

    return const Stock(
      symbol: '000660',
      name: 'SK하이닉스',
      market: '코스피',
    );
  }

  @override
  Future<Map<String, StockQuote>> fetchQuotes(
    Iterable<String> symbols,
  ) async {
    if (shouldFailQuotes) {
      throw const StockServiceException('시세 요청 실패');
    }

    return <String, StockQuote>{
      '005930': const StockQuote(
        symbol: '005930',
        currentPrice: 179700,
        previousClose: 180100,
        openPrice: 172100,
        highPrice: 181700,
        lowPrice: 172000,
        accumulatedTradingVolume: 29113466,
        countOfListedStock: 5919637922,
      ),
      '000660': const StockQuote(
        symbol: '000660',
        currentPrice: 412500,
        previousClose: 403000,
        openPrice: 405000,
        highPrice: 415000,
        lowPrice: 400000,
        accumulatedTradingVolume: 1000000,
        countOfListedStock: 728002365,
      ),
    };
  }
}
