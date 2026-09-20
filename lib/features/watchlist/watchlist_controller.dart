import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/stock.dart';
import '../../data/models/stock_quote.dart';
import '../../data/naver_stock_service.dart';
import '../favorites/favorite_controller.dart';

enum WatchlistStatus { loading, empty, success, failure }

enum WatchlistSort {
  currentPrice('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const WatchlistSort(this.label);

  final String label;
}

class WatchlistItem {
  const WatchlistItem({required this.stock, this.quote});

  final Stock stock;
  final StockQuote? quote;

  WatchlistItem withQuote(StockQuote? newQuote) {
    return WatchlistItem(stock: stock, quote: newQuote);
  }
}

class WatchlistController extends ChangeNotifier {
  WatchlistController({
    required FavoriteController favoriteController,
    required WatchlistService watchlistService,
  }) : _favoriteController = favoriteController,
       _watchlistService = watchlistService;

  final FavoriteController _favoriteController;
  final WatchlistService _watchlistService;

  final Set<String> _loadedFavoriteSymbols = <String>{};
  List<WatchlistItem> _items = <WatchlistItem>[];
  WatchlistStatus _status = WatchlistStatus.loading;
  WatchlistSort _sort = WatchlistSort.name;
  bool _isRefreshingQuotes = false;
  bool _hasQuoteLoadFailure = false;
  bool _isDisposed = false;
  int _requestVersion = 0;

  WatchlistStatus get status {
    return _status;
  }

  WatchlistSort get sort {
    return _sort;
  }

  bool get isRefreshingQuotes {
    return _isRefreshingQuotes;
  }

  bool get hasQuoteLoadFailure {
    return _hasQuoteLoadFailure;
  }

  List<WatchlistItem> get sortedItems {
    final List<WatchlistItem> sortedItems = List<WatchlistItem>.from(_items);

    sortedItems.sort(_compareItems);
    return sortedItems;
  }

  void initialize() {
    _favoriteController.addListener(_handleFavoriteChange);
    _handleFavoriteChange();
  }

  void selectSort(WatchlistSort newSort) {
    if (_sort == newSort) {
      return;
    }

    _sort = newSort;
    notifyListeners();
  }

  Future<void> refreshQuotes() async {
    if (_items.isEmpty || _isRefreshingQuotes) {
      return;
    }

    final int requestedVersion = _requestVersion;
    _isRefreshingQuotes = true;
    _hasQuoteLoadFailure = false;
    notifyListeners();

    await _loadQuotes(requestedVersion);
  }

  void retry() {
    _loadedFavoriteSymbols.clear();
    _handleFavoriteChange();
  }

  void _handleFavoriteChange() {
    if (_isDisposed) {
      return;
    }

    if (_favoriteController.status == FavoriteStatus.initial ||
        _favoriteController.status == FavoriteStatus.loading) {
      _status = WatchlistStatus.loading;
      notifyListeners();
      return;
    }

    if (_favoriteController.status == FavoriteStatus.failure) {
      _items = <WatchlistItem>[];
      _status = WatchlistStatus.failure;
      _isRefreshingQuotes = false;
      notifyListeners();
      return;
    }

    final Set<String> currentSymbols = _favoriteController.favoriteSymbols;

    if (currentSymbols.isEmpty) {
      _loadedFavoriteSymbols.clear();
      _requestVersion += 1;
      _items = <WatchlistItem>[];
      _status = WatchlistStatus.empty;
      _isRefreshingQuotes = false;
      _hasQuoteLoadFailure = false;
      notifyListeners();
      return;
    }

    if (setEquals(currentSymbols, _loadedFavoriteSymbols)) {
      return;
    }

    _loadedFavoriteSymbols
      ..clear()
      ..addAll(currentSymbols);
    _requestVersion += 1;

    unawaited(_loadFavoriteItems(currentSymbols, _requestVersion));
  }

  Future<void> _loadFavoriteItems(
    Set<String> symbols,
    int requestedVersion,
  ) async {
    _status = WatchlistStatus.loading;
    _hasQuoteLoadFailure = false;
    notifyListeners();

    final List<Future<Stock?>> metadataRequests = <Future<Stock?>>[];
    // 메타데이터를 기다리는 동안 시세도 조회한다. 실패는 즉시 처리해 둔다.
    final quoteRequest = _watchlistService
        .fetchQuotes(symbols)
        .then(
          (quotes) => quotes,
          onError: (Object error, StackTrace stack) {
            debugPrint('관심 종목 시세 조회 실패: $error');
            return <String, StockQuote>{};
          },
        );

    for (final String symbol in symbols) {
      metadataRequests.add(_loadMetadata(symbol));
    }

    final List<Stock?> metadataResults = await Future.wait(metadataRequests);

    if (_shouldIgnoreResponse(requestedVersion)) {
      return;
    }

    final List<WatchlistItem> loadedItems = <WatchlistItem>[];

    for (final Stock? stock in metadataResults) {
      if (stock != null) {
        loadedItems.add(WatchlistItem(stock: stock));
      }
    }

    if (loadedItems.isEmpty) {
      _items = <WatchlistItem>[];
      _status = WatchlistStatus.failure;
      _isRefreshingQuotes = false;
      notifyListeners();
      return;
    }

    _items = loadedItems;
    _status = WatchlistStatus.success;
    _isRefreshingQuotes = true;
    notifyListeners();

    final quotes = await quoteRequest;
    if (_shouldIgnoreResponse(requestedVersion)) {
      return;
    }
    _items = _items
        .map((item) => item.withQuote(quotes[item.stock.symbol]))
        .toList();
    _hasQuoteLoadFailure = _items.any((item) => item.quote == null);
    _isRefreshingQuotes = false;
    notifyListeners();
  }

  Future<Stock?> _loadMetadata(String symbol) async {
    try {
      return await _watchlistService.fetchStockMetadata(symbol);
    } on Object catch (error) {
      debugPrint('종목 메타데이터 조회 실패 ($symbol): $error');
      return null;
    }
  }

  Future<void> _loadQuotes(int requestedVersion) async {
    try {
      final Map<String, StockQuote> quotes = await _watchlistService
          .fetchQuotes(_items.map((WatchlistItem item) => item.stock.symbol));

      if (_shouldIgnoreResponse(requestedVersion)) {
        return;
      }

      _items = _items.map((WatchlistItem item) {
        final StockQuote? loadedQuote = quotes[item.stock.symbol];
        return item.withQuote(loadedQuote ?? item.quote);
      }).toList();
      _hasQuoteLoadFailure = quotes.length < _items.length;
    } on Object catch (error, stackTrace) {
      if (_shouldIgnoreResponse(requestedVersion)) {
        return;
      }

      debugPrint('관심 종목 시세 조회 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      _hasQuoteLoadFailure = true;
    }

    _isRefreshingQuotes = false;
    notifyListeners();
  }

  int _compareItems(WatchlistItem first, WatchlistItem second) {
    switch (_sort) {
      case WatchlistSort.currentPrice:
        return _compareNullableNumbers(
          first.quote?.currentPrice,
          second.quote?.currentPrice,
        );
      case WatchlistSort.changeRate:
        return _compareNullableNumbers(
          first.quote?.changeRate,
          second.quote?.changeRate,
        );
      case WatchlistSort.name:
        return first.stock.name.compareTo(second.stock.name);
    }
  }

  int _compareNullableNumbers(num? first, num? second) {
    if (first == null && second == null) {
      return 0;
    }

    if (first == null) {
      return 1;
    }

    if (second == null) {
      return -1;
    }

    return second.compareTo(first);
  }

  bool _shouldIgnoreResponse(int requestedVersion) {
    return _isDisposed || requestedVersion != _requestVersion;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _favoriteController.removeListener(_handleFavoriteChange);
    super.dispose();
  }
}
