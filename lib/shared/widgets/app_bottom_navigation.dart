import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../theme/theme.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedTab,
    required this.onTabSelected,
    super.key,
  });

  final AppTab selectedTab;
  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: dimens.tabBarHeight,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _NavigationItem(
                  itemKey: const Key('bottom_nav_watchlist'),
                  label: '관심',
                  icon: Icons.star_border,
                  selectedIcon: Icons.star,
                  isSelected: selectedTab == AppTab.watchlist,
                  onTap: () {
                    onTabSelected(AppTab.watchlist);
                  },
                ),
              ),
              Expanded(
                child: _NavigationItem(
                  itemKey: const Key('bottom_nav_search'),
                  label: '검색',
                  icon: Icons.search,
                  selectedIcon: Icons.search,
                  isSelected: selectedTab == AppTab.search,
                  onTap: () {
                    onTabSelected(AppTab.search);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.itemKey,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  final Key itemKey;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final Color contentColor;

    if (isSelected) {
      contentColor = colors.navActive;
    } else {
      contentColor = colors.navInactive;
    }

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$label 탭',
      child: InkWell(
        key: itemKey,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              isSelected ? selectedIcon : icon,
              color: contentColor,
              size: 24,
            ),
            SizedBox(height: dimens.space1),
            Text(
              label,
              style: TextStyle(
                color: contentColor,
                fontSize: 11,
                fontWeight: AppTypography.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
