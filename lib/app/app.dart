import 'dart:async';

import 'package:flutter/material.dart';

import '../data/favorite_storage.dart';
import '../features/search/search_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import '../data/naver_stock_service.dart';
import '../features/favorites/favorite_controller.dart';
import '../shared/widgets/app_bottom_navigation.dart';
import '../theme/theme.dart';
import 'app_controller.dart';

class EdencrewAssignmentApp extends StatefulWidget {
  const EdencrewAssignmentApp({
    this.stockSearchService,
    this.watchlistService,
    this.favoriteStorage,
    super.key,
  });

  final StockSearchService? stockSearchService;
  final WatchlistService? watchlistService;
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
  NaverStockService? _ownedNaverStockService;
  late final FavoriteController _favoriteController;

  @override
  void initState() {
    super.initState();
    _appController = AppController();
    if (widget.stockSearchService == null || widget.watchlistService == null) {
      _ownedNaverStockService = NaverStockService();
    }

    _stockSearchService =
        widget.stockSearchService ?? _ownedNaverStockService!;
    _watchlistService = widget.watchlistService ?? _ownedNaverStockService!;
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
    required this.favoriteController,
    super.key,
  });

  final AppController controller;
  final StockSearchService stockSearchService;
  final WatchlistService watchlistService;
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
              ),
              SearchScreen(
                searchService: stockSearchService,
                favoriteController: favoriteController,
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
}
