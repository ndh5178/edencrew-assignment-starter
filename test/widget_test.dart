import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edencrew_assignment_starter/app/app.dart';
import 'package:edencrew_assignment_starter/data/favorite_storage.dart';
import 'package:edencrew_assignment_starter/data/models/stock.dart';
import 'package:edencrew_assignment_starter/data/naver_stock_service.dart';

void main() {
  testWidgets('관심 탭과 검색 탭을 전환한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      EdencrewAssignmentApp(
        stockSearchService: _FakeStockSearchService(),
        favoriteStorage: _MemoryFavoriteStorage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('watchlist_screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom_nav_search')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_screen')), findsOneWidget);
  });
}

class _FakeStockSearchService implements StockSearchService {
  @override
  Future<List<Stock>> searchStocks(String query) async {
    return <Stock>[];
  }

  @override
  void close() {}
}

class _MemoryFavoriteStorage implements FavoriteStorage {
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
}
