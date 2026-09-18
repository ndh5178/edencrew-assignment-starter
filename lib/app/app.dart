import 'package:flutter/material.dart';

import '../features/search/search_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import '../shared/widgets/app_bottom_navigation.dart';
import '../theme/theme.dart';
import 'app_controller.dart';

class EdencrewAssignmentApp extends StatefulWidget {
  const EdencrewAssignmentApp({super.key});

  @override
  State<EdencrewAssignmentApp> createState() {
    return _EdencrewAssignmentAppState();
  }
}

class _EdencrewAssignmentAppState extends State<EdencrewAssignmentApp> {
  late final AppController _appController;

  @override
  void initState() {
    super.initState();
    _appController = AppController();
  }

  @override
  void dispose() {
    _appController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '이든크루 평가 과제',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AppShell(controller: _appController),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          body: IndexedStack(
            index: controller.selectedTabIndex,
            children: const <Widget>[
              WatchlistScreen(),
              SearchScreen(),
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
