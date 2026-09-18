import 'package:edencrew_assignment_starter/app/app.dart';
import 'package:edencrew_assignment_starter/data/favorite_storage.dart';
import 'package:edencrew_assignment_starter/data/models/stock.dart';
import 'package:edencrew_assignment_starter/data/models/daily_price.dart';
import 'package:edencrew_assignment_starter/data/models/stock_quote.dart';
import 'package:edencrew_assignment_starter/data/naver_stock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final _FakeFavoriteStorage favoriteStorage = _FakeFavoriteStorage();

  setUp(() {
    favoriteStorage.clear();
  });

  Future<void> pauseForObservation(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> launchApp(WidgetTester tester) async {
    final _FakeStockService stockService = _FakeStockService();

    runApp(
      EdencrewAssignmentApp(
        stockSearchService: stockService,
        watchlistService: stockService,
        dailyPriceService: stockService,
        favoriteStorage: favoriteStorage,
      ),
    );
    await tester.pumpAndSettle();
    await pauseForObservation(tester);
  }

  testWidgets('00. 앱이 정상적으로 실행된다', (WidgetTester tester) async {
    await launchApp(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('01. 관심 탭과 검색 탭을 전환한다', (WidgetTester tester) async {
    await launchApp(tester);

    expect(find.byKey(const Key('watchlist_screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom_nav_search')));
    await tester.pumpAndSettle();
    await pauseForObservation(tester);

    expect(find.byKey(const Key('search_screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom_nav_watchlist')));
    await tester.pumpAndSettle();
    await pauseForObservation(tester);

    expect(find.byKey(const Key('watchlist_screen')), findsOneWidget);
  });

  testWidgets('02. 삼성전자를 검색하고 결과를 확인한다', (WidgetTester tester) async {
    await launchApp(tester);

    await tester.tap(find.byKey(const Key('bottom_nav_search')));
    await tester.pumpAndSettle();
    await pauseForObservation(tester);

    await tester.enterText(find.byKey(const Key('stock_search_field')), '삼성');
    await tester.pumpAndSettle();
    await pauseForObservation(tester);

    expect(find.byKey(const Key('search_result_005930')), findsOneWidget);
    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.textContaining('005930'), findsOneWidget);
  });

  testWidgets('03. 검색 결과에서 관심 종목을 등록한다', (WidgetTester tester) async {
    await launchApp(tester);

    await tester.tap(find.byKey(const Key('bottom_nav_search')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('stock_search_field')), '삼성');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('favorite_button_005930')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    expect(find.byKey(const Key('favorite_active_005930')), findsOneWidget);
    await pauseForObservation(tester);

    await tester.tap(find.byKey(const Key('bottom_nav_watchlist')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('watchlist_item_005930')), findsOneWidget);
    expect(find.text('삼성전자'), findsOneWidget);
    await pauseForObservation(tester);
  });

  testWidgets('04. 관심 목록의 정렬 방식을 변경한다', (WidgetTester tester) async {
    await launchApp(tester);

    await tester.tap(find.byKey(const Key('watchlist_sort_button')));
    await tester.pumpAndSettle();
    await pauseForObservation(tester);

    expect(find.text('정렬'), findsOneWidget);

    await tester.tap(find.text('현재가순'));
    await tester.pumpAndSettle();
    await pauseForObservation(tester);

    expect(find.text('현재가순'), findsOneWidget);
  });

  testWidgets('05. 상세 화면에서 조회 기간을 변경하고 일별 시세를 확인한다', (
    WidgetTester tester,
  ) async {
    favoriteStorage.seed('005930');
    await launchApp(tester);

    await tester.tap(find.byKey(const Key('watchlist_item_005930')));
    await tester.pumpAndSettle();
    await pauseForObservation(tester);

    expect(find.byKey(const Key('stock_detail_screen')), findsOneWidget);
    expect(find.text('삼성전자'), findsOneWidget);
    final Finder currentPriceFinder = find.byKey(
      const Key('stock_detail_current_price'),
    );
    expect(currentPriceFinder, findsOneWidget);
    expect(tester.widget<Text>(currentPriceFinder).data, '179,700');
    expect(find.text('시가'), findsOneWidget);
    expect(find.text('시가총액'), findsOneWidget);

    await tester.tap(find.byKey(const Key('period_3_months')));
    await tester.pumpAndSettle();
    await pauseForObservation(tester);

    expect(find.byKey(const Key('candlestick_chart')), findsOneWidget);
    expect(find.byKey(const Key('daily_price_list')), findsOneWidget);
  });

  testWidgets('06. 상세 화면에서 관심을 해제하면 관심 목록에서도 제거된다', (
    WidgetTester tester,
  ) async {
    favoriteStorage.seed('005930');
    await launchApp(tester);

    await tester.tap(find.byKey(const Key('watchlist_item_005930')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('favorite_button_005930')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('관심이 해제되었습니다'), findsOneWidget);
    await pauseForObservation(tester);

    await tester.tap(find.byKey(const Key('stock_detail_back_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('watchlist_item_005930')), findsNothing);
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
  });

  testWidgets('07. 앱을 다시 시작해도 관심 종목이 유지된다', (WidgetTester tester) async {
    await launchApp(tester);

    await tester.tap(find.byKey(const Key('bottom_nav_search')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('stock_search_field')), '삼성');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('favorite_button_005930')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await launchApp(tester);

    await tester.tap(find.byKey(const Key('bottom_nav_search')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('stock_search_field')), '삼성');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('favorite_active_005930')), findsOneWidget);
    await pauseForObservation(tester);
  });
}

class _FakeStockService
    implements StockSearchService, WatchlistService, DailyPriceService {
  @override
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    DailyPricePeriod period,
  ) async {
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
      DailyPrice(
        localDate: '20260326',
        closePrice: 180100,
        changeAmount: 1200,
        openPrice: 178900,
        highPrice: 181000,
        lowPrice: 178500,
        accumulatedTradingVolume: 32074131,
      ),
    ];
  }

  @override
  Future<List<Stock>> searchStocks(String query) async {
    if (!query.contains('삼성')) {
      return <Stock>[];
    }

    return const <Stock>[
      Stock(symbol: '005930', name: '삼성전자', market: '코스피'),
      Stock(symbol: '005935', name: '삼성전자우', market: '코스피'),
      Stock(symbol: '207940', name: '삼성바이오로직스', market: '코스피'),
    ];
  }

  @override
  Future<Stock> fetchStockMetadata(String symbol) async {
    if (symbol == '005930') {
      return const Stock(symbol: '005930', name: '삼성전자', market: '코스피');
    }

    return Stock(symbol: symbol, name: '테스트 종목', market: '코스피');
  }

  @override
  Future<Map<String, StockQuote>> fetchQuotes(Iterable<String> symbols) async {
    final Map<String, StockQuote> quotes = <String, StockQuote>{};

    for (final String symbol in symbols) {
      if (symbol == '005930') {
        quotes[symbol] = const StockQuote(
          symbol: '005930',
          currentPrice: 179700,
          previousClose: 180100,
          openPrice: 172100,
          highPrice: 181700,
          lowPrice: 172000,
          accumulatedTradingVolume: 29113466,
          countOfListedStock: 5919637922,
        );
      }
    }

    return quotes;
  }

  @override
  void close() {}
}

class _FakeFavoriteStorage implements FavoriteStorage {
  final Set<String> _symbols = <String>{};

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

  void clear() {
    _symbols.clear();
  }

  void seed(String symbol) {
    _symbols.add(symbol);
  }
}
