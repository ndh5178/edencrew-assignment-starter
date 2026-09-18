import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/daily_price.dart';
import '../../shared/formatters/number_formatter.dart';
import '../../theme/theme.dart';
import 'stock_detail_controller.dart';

class StockPriceChart extends StatelessWidget {
  const StockPriceChart({required this.controller, super.key});

  final StockDetailController controller;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final List<Widget> periodButtons = <Widget>[];

    for (final DailyPricePeriod period in DailyPricePeriod.values) {
      periodButtons.add(
        Expanded(
          child: _PeriodButton(
            period: period,
            isSelected: controller.selectedPeriod == period,
            onPressed: () {
              unawaited(controller.selectPeriod(period));
            },
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Row(children: periodButtons),
        SizedBox(height: dimens.space5),
        SizedBox(height: 210, child: _buildChartState(context)),
      ],
    );
  }

  Widget _buildChartState(BuildContext context) {
    switch (controller.dailyPriceStatus) {
      case DailyPriceStatus.loading:
        return Center(
          child: CircularProgressIndicator(
            color: context.colors.accentDefault,
            strokeWidth: 2,
          ),
        );
      case DailyPriceStatus.success:
        if (controller.dailyPrices.isEmpty) {
          return const _ChartMessage(message: '표시할 일별 시세가 없습니다');
        }

        return CustomPaint(
          key: const Key('candlestick_chart'),
          painter: _CandlestickChartPainter(
            prices: controller.dailyPrices,
            colors: context.colors,
          ),
          child: const SizedBox.expand(),
        );
      case DailyPriceStatus.failure:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const _ChartMessage(message: '차트 데이터를 불러오지 못했습니다'),
            SizedBox(height: context.dimens.space2),
            TextButton(
              key: const Key('daily_price_retry_button'),
              onPressed: controller.retryDailyPrices,
              child: Text(
                '다시 시도',
                style: TextStyle(color: context.colors.accentDefault),
              ),
            ),
          ],
        );
    }
  }
}

class DailyPriceTable extends StatelessWidget {
  const DailyPriceTable({required this.controller, super.key});

  final StockDetailController controller;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    if (controller.dailyPriceStatus != DailyPriceStatus.success ||
        controller.dailyPrices.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> rows = <Widget>[
      Text(
        '일별 시세',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: AppTypography.bold,
        ),
      ),
      SizedBox(height: dimens.space3),
      const _DailyPriceHeader(),
    ];

    for (final DailyPrice price in controller.dailyPrices) {
      rows.add(_DailyPriceRow(price: price));
    }

    return Column(
      key: const Key('daily_price_list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.period,
    required this.isSelected,
    required this.onPressed,
  });

  final DailyPricePeriod period;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextButton(
        key: Key(_periodKey(period)),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: isSelected
              ? colors.accentDefault
              : colors.textSecondary,
          backgroundColor: isSelected ? colors.accentBg : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.dimens.radiusMd),
          ),
        ),
        child: Text(
          period.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected
                ? AppTypography.medium
                : AppTypography.regular,
          ),
        ),
      ),
    );
  }

  String _periodKey(DailyPricePeriod period) {
    switch (period) {
      case DailyPricePeriod.oneMonth:
        return 'period_1_month';
      case DailyPricePeriod.threeMonths:
        return 'period_3_months';
      case DailyPricePeriod.sixMonths:
        return 'period_6_months';
      case DailyPricePeriod.oneYear:
        return 'period_1_year';
    }
  }
}

class _ChartMessage extends StatelessWidget {
  const _ChartMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: context.colors.textTertiary, fontSize: 14),
      ),
    );
  }
}

class _CandlestickChartPainter extends CustomPainter {
  _CandlestickChartPainter({required this.prices, required this.colors});

  final List<DailyPrice> prices;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) {
      return;
    }

    int highestPrice = prices.first.highPrice;
    int lowestPrice = prices.first.lowPrice;

    for (final DailyPrice price in prices) {
      highestPrice = math.max(highestPrice, price.highPrice);
      lowestPrice = math.min(lowestPrice, price.lowPrice);
    }

    final double priceRange = math
        .max(1, highestPrice - lowestPrice)
        .toDouble();
    final double horizontalStep = size.width / prices.length;
    final double candleWidth = math.max(1.0, horizontalStep * 0.62);
    final List<DailyPrice> chronologicalPrices = prices.reversed.toList();

    double priceToY(int price) {
      final double normalized = (highestPrice - price) / priceRange;
      return 8 + normalized * (size.height - 16);
    }

    for (int index = 0; index < chronologicalPrices.length; index += 1) {
      final DailyPrice price = chronologicalPrices[index];
      final double centerX = horizontalStep * index + horizontalStep / 2;
      final Color candleColor;

      if (price.closePrice > price.openPrice) {
        candleColor = colors.chartLineUp;
      } else if (price.closePrice < price.openPrice) {
        candleColor = colors.chartLineDown;
      } else {
        candleColor = colors.chartLineFlat;
      }

      final Paint paint = Paint()
        ..color = candleColor
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(centerX, priceToY(price.highPrice)),
        Offset(centerX, priceToY(price.lowPrice)),
        paint,
      );

      final double openY = priceToY(price.openPrice);
      final double closeY = priceToY(price.closePrice);
      final double bodyTop = math.min(openY, closeY);
      final double bodyHeight = math.max(1.5, (openY - closeY).abs());
      final Rect body = Rect.fromLTWH(
        centerX - candleWidth / 2,
        bodyTop,
        candleWidth,
        bodyHeight,
      );
      canvas.drawRect(body, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickChartPainter oldDelegate) {
    return oldDelegate.prices != prices || oldDelegate.colors != colors;
  }
}

class _DailyPriceHeader extends StatelessWidget {
  const _DailyPriceHeader();

  @override
  Widget build(BuildContext context) {
    return _DailyPriceTableRow(
      date: '날짜',
      closePrice: '종가',
      changeAmount: '등락',
      volume: '거래량',
      textColor: context.colors.textSecondary,
      isHeader: true,
    );
  }
}

class _DailyPriceRow extends StatelessWidget {
  const _DailyPriceRow({required this.price});

  final DailyPrice price;

  @override
  Widget build(BuildContext context) {
    final Color changeColor;

    if (price.changeAmount > 0) {
      changeColor = context.colors.priceUpText;
    } else if (price.changeAmount < 0) {
      changeColor = context.colors.priceDownText;
    } else {
      changeColor = context.colors.priceFlatText;
    }

    return _DailyPriceTableRow(
      date: _formatDate(price.localDate),
      closePrice: formatInteger(price.closePrice),
      changeAmount: formatSignedInteger(price.changeAmount),
      volume: formatInteger(price.accumulatedTradingVolume),
      textColor: changeColor,
    );
  }

  String _formatDate(String localDate) {
    if (localDate.length != 8) {
      return localDate;
    }

    return '${localDate.substring(4, 6)}.${localDate.substring(6, 8)}';
  }
}

class _DailyPriceTableRow extends StatelessWidget {
  const _DailyPriceTableRow({
    required this.date,
    required this.closePrice,
    required this.changeAmount,
    required this.volume,
    required this.textColor,
    this.isHeader = false,
  });

  final String date;
  final String closePrice;
  final String changeAmount;
  final String volume;
  final Color textColor;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      color: isHeader ? context.colors.textSecondary : textColor,
      fontSize: isHeader ? 13 : 14,
      fontWeight: AppTypography.regular,
    );

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colors.borderSubtle,
            width: context.dimens.borderHairline,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              date,
              style: style.copyWith(color: context.colors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              closePrice,
              textAlign: TextAlign.right,
              style: style.copyWith(color: context.colors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(changeAmount, textAlign: TextAlign.right, style: style),
          ),
          Expanded(
            child: Text(
              volume,
              textAlign: TextAlign.right,
              style: style.copyWith(color: context.colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
