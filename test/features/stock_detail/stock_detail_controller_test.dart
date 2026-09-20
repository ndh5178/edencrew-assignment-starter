import 'dart:async';
import 'package:edencrew_assignment_starter/data/models/stock.dart';
import 'package:edencrew_assignment_starter/data/models/daily_price.dart';
import 'package:edencrew_assignment_starter/data/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/data/naver_stock_service.dart';
import 'package:edencrew_assignment_starter/features/stock_detail/stock_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('캐시로 돌아온 뒤 늦은 다른 기간 응답을 무시한다', () async {
    final service = _FakeWatchlistService(hasQuote: true);
    final controller = StockDetailController(
      stock: const Stock(symbol: '005930', name: '삼성전자', market: '코스피'),
      watchlistService: service,
      dailyPriceService: service,
    );
    await controller.initialize();
    service.pending = Completer<List<DailyPrice>>();
    final loading = controller.selectPeriod(DailyPricePeriod.threeMonths);
    await controller.selectPeriod(DailyPricePeriod.oneMonth);
    service.pending!.complete([]);
    await loading;
    expect(controller.selectedPeriod, DailyPricePeriod.oneMonth);
    expect(controller.dailyPrices, hasLength(1));
    controller.dispose();
  });
  const Stock samsungElectronics = Stock(
    symbol: '005930',
    name: '삼성전자',
    market: '코스피',
  );

  test('시세를 받아 상세 정보 상태를 success로 변경한다', () async {
    final _FakeWatchlistService service = _FakeWatchlistService(hasQuote: true);
    final StockDetailController controller = StockDetailController(
      stock: samsungElectronics,
      watchlistService: service,
      dailyPriceService: service,
    );

    await controller.initialize();

    expect(controller.status, StockDetailStatus.success);
    expect(controller.detail!.stock, samsungElectronics);
    expect(controller.detail!.quote.currentPrice, 179700);

    controller.dispose();
  });

  test('시세가 없으면 failure 상태로 변경한다', () async {
    final _FakeWatchlistService service = _FakeWatchlistService(
      hasQuote: false,
    );
    final StockDetailController controller = StockDetailController(
      stock: samsungElectronics,
      watchlistService: service,
      dailyPriceService: service,
    );

    await controller.initialize();

    expect(controller.status, StockDetailStatus.failure);
    expect(controller.detail, isNull);

    controller.dispose();
  });

  test('같은 기간을 다시 선택하면 메모리 캐시를 사용한다', () async {
    final _FakeWatchlistService service = _FakeWatchlistService(hasQuote: true);
    final StockDetailController controller = StockDetailController(
      stock: samsungElectronics,
      watchlistService: service,
      dailyPriceService: service,
    );

    await controller.initialize();
    await controller.selectPeriod(DailyPricePeriod.threeMonths);
    await controller.selectPeriod(DailyPricePeriod.oneMonth);

    expect(service.dailyPriceRequestCount, 2);
    expect(controller.selectedPeriod, DailyPricePeriod.oneMonth);
    expect(controller.dailyPriceStatus, DailyPriceStatus.success);

    controller.dispose();
  });
}

class _FakeWatchlistService implements WatchlistService, DailyPriceService {
  _FakeWatchlistService({required this.hasQuote});

  final bool hasQuote;
  int dailyPriceRequestCount = 0;
  Completer<List<DailyPrice>>? pending;

  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    DailyPricePeriod period,
  ) async {
    dailyPriceRequestCount += 1;
    if (pending != null) return pending!.future;

    return const <DailyPrice>[
      DailyPrice(
        localDate: '20260327',
        closePrice: 179700,
        changeAmount: -400,
        openPrice: 172100,
        highPrice: 181700,
        lowPrice: 172000,
        accumulatedTradingVolume: 29113466,
      ),
    ];
  }

  @override
  Future<Stock> fetchStockMetadata(String symbol) async {
    return const Stock(symbol: '005930', name: '삼성전자', market: '코스피');
  }

  @override
  Future<Map<String, StockQuote>> fetchQuotes(Iterable<String> symbols) async {
    if (!hasQuote) {
      return <String, StockQuote>{};
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
    };
  }
}
