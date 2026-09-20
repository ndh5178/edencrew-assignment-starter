import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/stock.dart';
import '../../data/naver_stock_service.dart';

enum SearchStatus { initial, loading, success, empty, failure }

class StockSearchController extends ChangeNotifier {
  StockSearchController({
    required StockSearchService searchService,
    Duration debounceDuration = const Duration(milliseconds: 350),
  }) : _searchService = searchService,
       _debounceDuration = debounceDuration;

  final StockSearchService _searchService;
  final Duration _debounceDuration;

  Timer? _debounceTimer;
  int _searchVersion = 0;
  bool _isDisposed = false;
  final Map<String, ({DateTime expires, List<Stock> stocks})> _cache = {};
  final Map<String, Future<List<Stock>>> _pending = {};

  String _query = '';
  SearchStatus _status = SearchStatus.initial;
  List<Stock> _results = <Stock>[];
  String? _errorMessage;

  String get query {
    return _query;
  }

  SearchStatus get status {
    return _status;
  }

  List<Stock> get results {
    return List<Stock>.unmodifiable(_results);
  }

  String? get errorMessage {
    return _errorMessage;
  }

  void onQueryChanged(String value) {
    _query = value.trim();
    _searchVersion += 1;
    _debounceTimer?.cancel();

    if (_query.isEmpty) {
      _status = SearchStatus.initial;
      _results = <Stock>[];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    final cached = _cache.remove(_query);
    if (cached != null && DateTime.now().isBefore(cached.expires)) {
      _cache[_query] = cached;
      _results = cached.stocks;
      _status = _results.isEmpty ? SearchStatus.empty : SearchStatus.success;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _status = SearchStatus.loading;
    _results = <Stock>[];
    _errorMessage = null;
    notifyListeners();

    final int requestedVersion = _searchVersion;
    final String requestedQuery = _query;

    _debounceTimer = Timer(_debounceDuration, () {
      _requestSearch(requestedQuery, requestedVersion);
    });
  }

  void clearSearch() {
    onQueryChanged('');
  }

  void retry() {
    _debounceTimer?.cancel();
    if (_query.isEmpty) {
      return;
    }

    _searchVersion += 1;
    final int requestedVersion = _searchVersion;

    _status = SearchStatus.loading;
    _errorMessage = null;
    notifyListeners();

    _requestSearch(_query, requestedVersion);
  }

  Future<void> _requestSearch(String query, int requestedVersion) async {
    try {
      final List<Stock> stocks = await _pending.putIfAbsent(
        query,
        () => _searchService.searchStocks(query).whenComplete(() {
          _pending.remove(query);
        }),
      );
      if (!_isDisposed) {
        _cache.remove(query);
        _cache[query] = (
          expires: DateTime.now().add(const Duration(minutes: 5)),
          stocks: stocks,
        );
        while (_cache.length > 30) {
          _cache.remove(_cache.keys.first);
        }
      }

      if (_shouldIgnoreResponse(requestedVersion)) {
        return;
      }

      _results = stocks;

      if (stocks.isEmpty) {
        _status = SearchStatus.empty;
      } else {
        _status = SearchStatus.success;
      }
    } on Object catch (error, stackTrace) {
      if (_shouldIgnoreResponse(requestedVersion)) {
        return;
      }

      debugPrint('종목 검색 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      _results = <Stock>[];
      _status = SearchStatus.failure;
      _errorMessage = '검색 결과를 불러오지 못했습니다.';
    }

    notifyListeners();
  }

  bool _shouldIgnoreResponse(int requestedVersion) {
    return _isDisposed || requestedVersion != _searchVersion;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}
