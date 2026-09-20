import 'dart:async';

import 'package:flutter/material.dart';

import '../data/favorite_storage.dart';
import '../data/models/stock.dart';
import '../data/naver_stock_service.dart';
import '../features/favorites/favorite_controller.dart';
import '../features/search/search_screen.dart';
import '../features/stock_detail/stock_detail_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import '../shared/widgets/app_bottom_navigation.dart';
import '../theme/theme.dart';
import 'app_controller.dart';

class EdencrewAssignmentApp extends StatefulWidget {
  const EdencrewAssignmentApp({
    this.stockSearchService,
    this.watchlistService,
    this.dailyPriceService,
    this.favoriteStorage,
    super.key,
  });

  final StockSearchService? stockSearchService;
  final WatchlistService? watchlistService;
  final DailyPriceService? dailyPriceService;
  final FavoriteStorage? favoriteStorage;

  @override
  State<EdencrewAssignmentApp> createState() {
    return _EdencrewAssignmentAppState();
  }
}

class _EdencrewAssignmentAppState extends State<EdencrewAssignmentApp> {
  late final AppController _appController;
  late final StockSearchService _stockSearchService;
  late final WatchlistService _watchlistService;
  late final DailyPriceService _dailyPriceService;
  NaverStockService? _ownedNaverStockService;
  late final FavoriteController _favoriteController;

  @override
  void initState() {
    super.initState();
    _appController = AppController();
    if (widget.stockSearchService == null ||
        widget.watchlistService == null ||
        widget.dailyPriceService == null) {
      _ownedNaverStockService = NaverStockService();
    }

    _stockSearchService = widget.stockSearchService ?? _ownedNaverStockService!;
    _watchlistService = widget.watchlistService ?? _ownedNaverStockService!;
    _dailyPriceService = widget.dailyPriceService ?? _ownedNaverStockService!;
    _favoriteController = FavoriteController(
      storage: widget.favoriteStorage ?? SharedPreferencesFavoriteStorage(),
    );
    unawaited(_favoriteController.initialize());
  }

  @override
  void dispose() {
    _appController.dispose();
    _favoriteController.dispose();
    _ownedNaverStockService?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '이든크루 평가 과제',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AppShell(
        controller: _appController,
        stockSearchService: _stockSearchService,
        watchlistService: _watchlistService,
        dailyPriceService: _dailyPriceService,
        favoriteController: _favoriteController,
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.controller,
    required this.stockSearchService,
    required this.watchlistService,
    required this.dailyPriceService,
    required this.favoriteController,
    super.key,
  });

  final AppController controller;
  final StockSearchService stockSearchService;
  final WatchlistService watchlistService;
  final DailyPriceService dailyPriceService;
  final FavoriteController favoriteController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          body: IndexedStack(
            index: controller.selectedTabIndex,
            children: <Widget>[
              WatchlistScreen(
                watchlistService: watchlistService,
                favoriteController: favoriteController,
                onStockSelected: (Stock stock) {
                  _openStockDetail(context, stock);
                },
              ),
              SearchScreen(
                searchService: stockSearchService,
                favoriteController: favoriteController,
                onStockSelected: (Stock stock) {
                  _openStockDetail(context, stock);
                },
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavigation(
            selectedTab: controller.selectedTab,
            onTabSelected: controller.selectTab,
          ),
        );
      },
    );
  }

  void _openStockDetail(BuildContext context, Stock stock) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return StockDetailScreen(
            stock: stock,
            watchlistService: watchlistService,
            dailyPriceService: dailyPriceService,
            favoriteController: favoriteController,
          );
        },
      ),
    );
  }
}
