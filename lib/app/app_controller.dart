import 'package:flutter/foundation.dart';

enum AppTab {
  watchlist,
  search,
}

class AppController extends ChangeNotifier {
  AppTab _selectedTab = AppTab.watchlist;

  AppTab get selectedTab {
    return _selectedTab;
  }

  int get selectedTabIndex {
    return _selectedTab.index;
  }

  void selectTab(AppTab tab) {
    if (_selectedTab == tab) {
      return;
    }

    _selectedTab = tab;
    notifyListeners();
  }
}
