import 'package:flutter/foundation.dart';

import '../../data/models/stock.dart';
import '../../data/models/daily_price.dart';
import '../../data/models/stock_detail.dart';
import '../../data/models/stock_quote.dart';
import '../../data/naver_stock_service.dart';

enum StockDetailStatus { loading, success, failure }

enum DailyPriceStatus { loading, success, failure }

class StockDetailController extends ChangeNotifier {
  StockDetailController({
    required Stock stock,
    required WatchlistService watchlistService,
    required DailyPriceService dailyPriceService,
  }) : _stock = stock,
       _watchlistService = watchlistService,
       _dailyPriceService = dailyPriceService;

  final Stock _stock;
  final WatchlistService _watchlistService;
  final DailyPriceService _dailyPriceService;
  final Map<DailyPricePeriod, List<DailyPrice>> _dailyPriceCache =
      <DailyPricePeriod, List<DailyPrice>>{};

  StockDetailStatus _status = StockDetailStatus.loading;
  StockDetail? _detail;
  DailyPriceStatus _dailyPriceStatus = DailyPriceStatus.loading;
  DailyPricePeriod _selectedPeriod = DailyPricePeriod.oneMonth;
  List<DailyPrice> _dailyPrices = <DailyPrice>[];
  int _dailyPriceRequestId = 0;
  bool _isDisposed = false;

  StockDetailStatus get status {
    return _status;
  }

  StockDetail? get detail {
    return _detail;
  }

  DailyPriceStatus get dailyPriceStatus {
    return _dailyPriceStatus;
  }

  DailyPricePeriod get selectedPeriod {
    return _selectedPeriod;
  }

  List<DailyPrice> get dailyPrices {
    return List<DailyPrice>.unmodifiable(_dailyPrices);
  }

  Future<void> initialize() async {
    await Future.wait(<Future<void>>[
      _loadDetail(),
      _loadDailyPrices(_selectedPeriod),
    ]);
  }

  Future<void> retry() async {
    await _loadDetail();
  }

  Future<void> selectPeriod(DailyPricePeriod period) async {
    if (_selectedPeriod == period &&
        _dailyPriceStatus == DailyPriceStatus.success) {
      return;
    }

    _selectedPeriod = period;
    await _loadDailyPrices(period);
  }

  Future<void> retryDailyPrices() async {
    await _loadDailyPrices(_selectedPeriod, ignoreCache: true);
  }

  Future<void> _loadDailyPrices(
    DailyPricePeriod period, {
    bool ignoreCache = false,
  }) async {
    final List<DailyPrice>? cachedPrices = _dailyPriceCache[period];

    if (!ignoreCache && cachedPrices != null) {
      _dailyPrices = cachedPrices;
      _dailyPriceStatus = DailyPriceStatus.success;
      notifyListeners();
      return;
    }

    final int requestId = ++_dailyPriceRequestId;
    _dailyPrices = <DailyPrice>[];
    _dailyPriceStatus = DailyPriceStatus.loading;
    notifyListeners();

    try {
      final List<DailyPrice> loadedPrices = await _dailyPriceService
          .fetchDailyPrices(_stock.symbol, period);

      if (_isDisposed || requestId != _dailyPriceRequestId) {
        return;
      }

      _dailyPriceCache[period] = loadedPrices;
      _dailyPrices = loadedPrices;
      _dailyPriceStatus = DailyPriceStatus.success;
    } on Object {
      if (_isDisposed || requestId != _dailyPriceRequestId) {
        return;
      }

      _dailyPrices = <DailyPrice>[];
      _dailyPriceStatus = DailyPriceStatus.failure;
    }

    notifyListeners();
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
