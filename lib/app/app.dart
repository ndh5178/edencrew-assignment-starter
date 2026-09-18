import 'package:flutter/material.dart';

import '../features/search/search_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import '../data/naver_stock_service.dart';
import '../shared/widgets/app_bottom_navigation.dart';
import '../theme/theme.dart';
import 'app_controller.dart';

class EdencrewAssignmentApp extends StatefulWidget {
  const EdencrewAssignmentApp({
    this.stockSearchService,
    super.key,
  });

  final StockSearchService? stockSearchService;

  @override
  State<EdencrewAssignmentApp> createState() {
    return _EdencrewAssignmentAppState();
  }
}

class _EdencrewAssignmentAppState extends State<EdencrewAssignmentApp> {
  late final AppController _appController;
  late final StockSearchService _stockSearchService;
  late final bool _ownsStockSearchService;

  @override
  void initState() {
    super.initState();
    _appController = AppController();
    _ownsStockSearchService = widget.stockSearchService == null;
    _stockSearchService = widget.stockSearchService ?? NaverStockService();
  }

  @override
  void dispose() {
    _appController.dispose();
    if (_ownsStockSearchService) {
      _stockSearchService.close();
    }
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
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.controller,
    required this.stockSearchService,
    super.key,
  });

  final AppController controller;
  final StockSearchService stockSearchService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          body: IndexedStack(
            index: controller.selectedTabIndex,
            children: <Widget>[
              const WatchlistScreen(),
              SearchScreen(searchService: stockSearchService),
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
