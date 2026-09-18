import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SafeArea(
      key: const Key('watchlist_screen'),
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: dimens.space6),
            Text(
              '관심',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: AppTypography.bold,
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                '관심 화면을 준비 중입니다.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: AppTypography.regular,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
