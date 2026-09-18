import 'package:flutter/material.dart';

import '../../data/models/stock.dart';
import '../../data/models/stock_quote.dart';
import '../../data/naver_stock_service.dart';
import '../../shared/formatters/number_formatter.dart';
import '../../theme/theme.dart';
import '../favorites/favorite_controller.dart';
import 'watchlist_controller.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({
    required this.watchlistService,
    required this.favoriteController,
    required this.onStockSelected,
    super.key,
  });

  final WatchlistService watchlistService;
  final FavoriteController favoriteController;
  final ValueChanged<Stock> onStockSelected;

  @override
  State<WatchlistScreen> createState() {
    return _WatchlistScreenState();
  }
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late final WatchlistController _watchlistController;

  @override
  void initState() {
    super.initState();
    _watchlistController = WatchlistController(
      favoriteController: widget.favoriteController,
      watchlistService: widget.watchlistService,
    );
    _watchlistController.initialize();
  }

  @override
  void dispose() {
    _watchlistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('watchlist_screen'),
      bottom: false,
      child: AnimatedBuilder(
        animation: _watchlistController,
        builder: (BuildContext context, Widget? child) {
          return Column(
            children: <Widget>[
              _WatchlistHeader(
                selectedSort: _watchlistController.sort,
                isRefreshing: _watchlistController.isRefreshingQuotes,
                onSortPressed: _showSortSheet,
                onRefreshPressed: _watchlistController.refreshQuotes,
              ),
              Expanded(child: _buildContent()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (_watchlistController.status) {
      case WatchlistStatus.loading:
        return const _WatchlistLoadingView();
      case WatchlistStatus.empty:
        return const _WatchlistEmptyView();
      case WatchlistStatus.success:
        return _WatchlistItems(
          items: _watchlistController.sortedItems,
          onStockSelected: widget.onStockSelected,
        );
      case WatchlistStatus.failure:
        return _WatchlistFailureView(onRetry: _watchlistController.retry);
    }
  }

  Future<void> _showSortSheet() async {
    final AppColors colors = context.colors;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceBase.withValues(alpha: 0),
      barrierColor: colors.surfaceBase.withValues(alpha: 0.72),
      builder: (BuildContext sheetContext) {
        return _WatchlistSortSheet(
          selectedSort: _watchlistController.sort,
          onSortSelected: (WatchlistSort sort) {
            _watchlistController.selectSort(sort);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }
}

class _WatchlistHeader extends StatelessWidget {
  const _WatchlistHeader({
    required this.selectedSort,
    required this.isRefreshing,
    required this.onSortPressed,
    required this.onRefreshPressed,
  });

  final WatchlistSort selectedSort;
  final bool isRefreshing;
  final VoidCallback onSortPressed;
  final VoidCallback onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        dimens.space5,
        dimens.space2,
        dimens.space3,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '관심',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
          TextButton.icon(
            key: const Key('watchlist_sort_button'),
            onPressed: onSortPressed,
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
              padding: EdgeInsets.symmetric(horizontal: dimens.space2),
            ),
            label: Text(
              selectedSort.label,
              style: TextStyle(fontSize: 14, fontWeight: AppTypography.medium),
            ),
            icon: const Icon(Icons.arrow_downward, size: 18),
            iconAlignment: IconAlignment.end,
          ),
          IconButton(
            key: const Key('watchlist_refresh_button'),
            onPressed: isRefreshing ? null : onRefreshPressed,
            icon: Icon(
              Icons.refresh,
              color: isRefreshing ? colors.textDisabled : colors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistLoadingView extends StatelessWidget {
  const _WatchlistLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: context.colors.accentDefault,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _WatchlistEmptyView extends StatelessWidget {
  const _WatchlistEmptyView();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.star_border, color: colors.textTertiary, size: 36),
          SizedBox(height: dimens.space3),
          Text(
            '관심 종목이 없습니다',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 20,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: dimens.space2),
          Text(
            '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 13,
              fontWeight: AppTypography.regular,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistFailureView extends StatelessWidget {
  const _WatchlistFailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '관심 종목을 불러오지 못했습니다',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 18,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: dimens.space3),
          TextButton(
            onPressed: onRetry,
            child: Text('다시 시도', style: TextStyle(color: colors.accentDefault)),
          ),
        ],
      ),
    );
  }
}

class _WatchlistItems extends StatelessWidget {
  const _WatchlistItems({required this.items, required this.onStockSelected});

  final List<WatchlistItem> items;
  final ValueChanged<Stock> onStockSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          height: 1,
          thickness: context.dimens.borderHairline,
          color: context.colors.borderSubtle,
        );
      },
      itemBuilder: (BuildContext context, int index) {
        final WatchlistItem item = items[index];

        return _WatchlistRow(
          item: item,
          onStockSelected: () {
            onStockSelected(item.stock);
          },
        );
      },
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({required this.item, required this.onStockSelected});

  final WatchlistItem item;
  final VoidCallback onStockSelected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      key: Key('watchlist_item_${item.stock.symbol}'),
      onTap: onStockSelected,
      child: Container(
        constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          vertical: dimens.space3,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.stock.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  SizedBox(height: dimens.space1),
                  Text(
                    '${item.stock.symbol} · ${item.stock.market}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: AppTypography.regular,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: dimens.space3),
            _WatchlistPrice(quote: item.quote),
          ],
        ),
      ),
    );
  }
}

class _WatchlistPrice extends StatelessWidget {
  const _WatchlistPrice({required this.quote});

  final StockQuote? quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    if (quote == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          _SkeletonBar(width: 64, height: 16),
          SizedBox(height: dimens.space1),
          _SkeletonBar(width: 48, height: 12),
        ],
      );
    }

    final StockQuote loadedQuote = quote!;
    final Color changeColor;

    if (loadedQuote.changeAmount > 0) {
      changeColor = colors.priceUpText;
    } else if (loadedQuote.changeAmount < 0) {
      changeColor = colors.priceDownText;
    } else {
      changeColor = colors.priceFlatText;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          formatInteger(loadedQuote.currentPrice),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: AppTypography.bold,
          ),
        ),
        SizedBox(height: dimens.space1),
        Text(
          '${formatSignedInteger(loadedQuote.changeAmount)} '
          '(${formatSignedRate(loadedQuote.changeRate)})',
          style: TextStyle(
            color: changeColor,
            fontSize: 13,
            fontWeight: AppTypography.regular,
          ),
        ),
      ],
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.feedbackSkeleton,
        borderRadius: BorderRadius.circular(context.dimens.radiusSm),
      ),
    );
  }
}

class _WatchlistSortSheet extends StatelessWidget {
  const _WatchlistSortSheet({
    required this.selectedSort,
    required this.onSortSelected,
  });

  final WatchlistSort selectedSort;
  final ValueChanged<WatchlistSort> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final List<Widget> sheetChildren = <Widget>[
      Text(
        '정렬',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: AppTypography.bold,
        ),
      ),
      SizedBox(height: dimens.space4),
    ];

    for (final WatchlistSort sort in WatchlistSort.values) {
      sheetChildren.add(
        _SortOption(
          sort: sort,
          isSelected: sort == selectedSort,
          onTap: () {
            onSortSelected(sort);
          },
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(dimens.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            dimens.space5,
            dimens.space5,
            dimens.space5,
            dimens.space3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sheetChildren,
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.sort,
    required this.isSelected,
    required this.onTap,
  });

  final WatchlistSort sort;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return InkWell(
      key: Key('sort_option_${sort.name}'),
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                sort.label,
                style: TextStyle(
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                  fontSize: 16,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: colors.textPrimary, size: 22),
          ],
        ),
      ),
    );
  }
}
