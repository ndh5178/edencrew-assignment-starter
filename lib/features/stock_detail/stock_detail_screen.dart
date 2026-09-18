import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/stock.dart';
import '../../data/models/stock_detail.dart';
import '../../data/models/stock_quote.dart';
import '../../data/naver_stock_service.dart';
import '../../shared/formatters/number_formatter.dart';
import '../../theme/theme.dart';
import '../favorites/favorite_controller.dart';
import 'price_chart_section.dart';
import 'stock_detail_controller.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({
    required this.stock,
    required this.watchlistService,
    required this.dailyPriceService,
    required this.favoriteController,
    super.key,
  });

  final Stock stock;
  final WatchlistService watchlistService;
  final DailyPriceService dailyPriceService;
  final FavoriteController favoriteController;

  @override
  State<StockDetailScreen> createState() {
    return _StockDetailScreenState();
  }
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late final StockDetailController _detailController;

  @override
  void initState() {
    super.initState();
    _detailController = StockDetailController(
      stock: widget.stock,
      watchlistService: widget.watchlistService,
      dailyPriceService: widget.dailyPriceService,
    );
    unawaited(_detailController.initialize());
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('stock_detail_screen'),
      backgroundColor: context.colors.surfaceBase,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _StockDetailHeader(
              stock: widget.stock,
              favoriteController: widget.favoriteController,
              onBackPressed: () {
                Navigator.of(context).pop();
              },
              onFavoritePressed: _toggleFavorite,
            ),
            Divider(
              height: 1,
              thickness: context.dimens.borderHairline,
              color: context.colors.borderSubtle,
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _detailController,
                builder: (BuildContext context, Widget? child) {
                  return _buildContent();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_detailController.status) {
      case StockDetailStatus.loading:
        return const _StockDetailLoadingView();
      case StockDetailStatus.success:
        return _StockDetailContent(
          detail: _detailController.detail!,
          controller: _detailController,
        );
      case StockDetailStatus.failure:
        return _StockDetailFailureView(onRetry: _detailController.retry);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final FavoriteChange? change = await widget.favoriteController
          .toggleFavorite(widget.stock.symbol);

      if (!mounted || change == null) {
        return;
      }

      _showFavoriteToast(change);
    } on Object {
      if (!mounted) {
        return;
      }

      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surfaceSunken,
          content: Text(
            '관심 종목을 저장하지 못했습니다',
            style: TextStyle(color: context.colors.textPrimary),
          ),
        ),
      );
    }
  }

  void _showFavoriteToast(FavoriteChange change) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final bool wasAdded = change == FavoriteChange.added;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceSunken,
        margin: EdgeInsets.fromLTRB(
          dimens.space4,
          0,
          dimens.space4,
          dimens.space3,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          vertical: dimens.space3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimens.radiusLg),
        ),
        duration: const Duration(seconds: 2),
        content: Row(
          children: <Widget>[
            Icon(
              wasAdded ? Icons.star : Icons.star_border,
              color: wasAdded ? colors.favoriteActive : colors.favoriteInactive,
              size: 24,
            ),
            SizedBox(width: dimens.space3),
            Text(
              wasAdded ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockDetailHeader extends StatelessWidget {
  const _StockDetailHeader({
    required this.stock,
    required this.favoriteController,
    required this.onBackPressed,
    required this.onFavoritePressed,
  });

  final Stock stock;
  final FavoriteController favoriteController;
  final VoidCallback onBackPressed;
  final VoidCallback onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return AnimatedBuilder(
      animation: favoriteController,
      builder: (BuildContext context, Widget? child) {
        final bool isFavorite = favoriteController.isFavorite(stock.symbol);
        final bool isUpdating = favoriteController.isUpdating(stock.symbol);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            dimens.space2,
            dimens.space4,
            dimens.space3,
            dimens.space4,
          ),
          child: Row(
            children: <Widget>[
              IconButton(
                key: const Key('stock_detail_back_button'),
                onPressed: onBackPressed,
                icon: Icon(Icons.arrow_back, color: colors.textSecondary),
              ),
              SizedBox(width: dimens.space1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    SizedBox(height: dimens.space1),
                    Text(
                      '${stock.symbol} · ${stock.market}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: AppTypography.regular,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('favorite_button_${stock.symbol}'),
                onPressed: isUpdating ? null : onFavoritePressed,
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  key: Key(
                    isFavorite
                        ? 'favorite_active_${stock.symbol}'
                        : 'favorite_inactive_${stock.symbol}',
                  ),
                  color: isFavorite
                      ? colors.favoriteActive
                      : colors.favoriteInactive,
                  size: 30,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockDetailLoadingView extends StatelessWidget {
  const _StockDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: context.colors.accentDefault,
        strokeWidth: 2,
      ),
    );
  }
}

class _StockDetailFailureView extends StatelessWidget {
  const _StockDetailFailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '종목 정보를 불러오지 못했습니다',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 18,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: context.dimens.space3),
          TextButton(
            key: const Key('stock_detail_retry_button'),
            onPressed: onRetry,
            child: Text(
              '다시 시도',
              style: TextStyle(color: context.colors.accentDefault),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockDetailContent extends StatelessWidget {
  const _StockDetailContent({required this.detail, required this.controller});

  final StockDetail detail;
  final StockDetailController controller;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return SingleChildScrollView(
      padding: EdgeInsets.all(dimens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CurrentPrice(quote: detail.quote),
          SizedBox(height: dimens.space6),
          StockPriceChart(controller: controller),
          SizedBox(height: dimens.space6),
          _QuoteStatistics(quote: detail.quote),
          SizedBox(height: dimens.space6),
          DailyPriceTable(controller: controller),
        ],
      ),
    );
  }
}

class _CurrentPrice extends StatelessWidget {
  const _CurrentPrice({required this.quote});

  final StockQuote quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final Color changeColor;
    final IconData changeIcon;

    if (quote.changeAmount > 0) {
      changeColor = colors.priceUpText;
      changeIcon = Icons.arrow_drop_up;
    } else if (quote.changeAmount < 0) {
      changeColor = colors.priceDownText;
      changeIcon = Icons.arrow_drop_down;
    } else {
      changeColor = colors.priceFlatText;
      changeIcon = Icons.remove;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          formatInteger(quote.currentPrice),
          key: const Key('stock_detail_current_price'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 36,
            fontWeight: AppTypography.bold,
            height: 1,
          ),
        ),
        SizedBox(width: dimens.space2),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: <Widget>[
              Icon(changeIcon, color: changeColor, size: 28),
              Text(
                '${formatInteger(quote.changeAmount.abs())} '
                '(${formatSignedRate(quote.changeRate)})',
                style: TextStyle(
                  color: changeColor,
                  fontSize: 18,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuoteStatistics extends StatelessWidget {
  const _QuoteStatistics({required this.quote});

  final StockQuote quote;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final List<Widget> cards = <Widget>[
      _StatisticCard(label: '시가', value: formatInteger(quote.openPrice)),
      _StatisticCard(label: '고가', value: formatInteger(quote.highPrice)),
      _StatisticCard(label: '저가', value: formatInteger(quote.lowPrice)),
      _StatisticCard(
        label: '거래량',
        value: '${formatInteger(quote.accumulatedTradingVolume ~/ 1000)}천',
      ),
      _StatisticCard(
        label: '시가총액',
        value: '${formatInteger(quote.marketCapitalization ~/ 1000000000000)}조',
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double threeColumnWidth =
            (constraints.maxWidth - dimens.space2 * 2) / 3;
        final double twoColumnWidth =
            (constraints.maxWidth - dimens.space2) / 2;
        final List<Widget> rows = <Widget>[];

        for (int index = 0; index < cards.length; index += 1) {
          final bool isBottomRow = index >= 3;
          rows.add(
            SizedBox(
              width: isBottomRow ? twoColumnWidth : threeColumnWidth,
              child: cards[index],
            ),
          );
        }

        return Wrap(
          spacing: dimens.space2,
          runSpacing: dimens.space2,
          children: rows,
        );
      },
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      padding: EdgeInsets.all(dimens.space3),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: AppTypography.regular,
            ),
          ),
          SizedBox(height: dimens.space2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }
}
