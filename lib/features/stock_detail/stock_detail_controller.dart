import 'package:flutter/foundation.dart';

import '../../data/models/stock.dart';
import '../../data/models/stock_detail.dart';
import '../../data/models/stock_quote.dart';
import '../../data/naver_stock_service.dart';

enum StockDetailStatus { loading, success, failure }

class StockDetailController extends ChangeNotifier {
  StockDetailController({
    required Stock stock,
    required WatchlistService watchlistService,
  }) : _stock = stock,
       _watchlistService = watchlistService;

  final Stock _stock;
  final WatchlistService _watchlistService;

  StockDetailStatus _status = StockDetailStatus.loading;
  StockDetail? _detail;
  bool _isDisposed = false;

  StockDetailStatus get status {
    return _status;
  }

  StockDetail? get detail {
    return _detail;
  }

  Future<void> initialize() async {
    await _loadDetail();
  }

  Future<void> retry() async {
    await _loadDetail();
  }

  Future<void> _loadDetail() async {
    _status = StockDetailStatus.loading;
    _detail = null;
    notifyListeners();

    try {
      final Map<String, StockQuote> quotes = await _watchlistService
          .fetchQuotes(<String>[_stock.symbol]);
      final StockQuote? quote = quotes[_stock.symbol];

      if (quote == null) {
        throw StateError('종목 시세를 찾지 못했습니다.');
      }

      if (_isDisposed) {
        return;
      }

      _detail = StockDetail(stock: _stock, quote: quote);
      _status = StockDetailStatus.success;
    } on Object {
      if (_isDisposed) {
        return;
      }

      _detail = null;
      _status = StockDetailStatus.failure;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
