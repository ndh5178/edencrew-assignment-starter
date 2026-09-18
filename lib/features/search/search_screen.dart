import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return SafeArea(
      key: const Key('search_screen'),
      bottom: false,
      child: Center(
        child: Text(
          '검색 화면을 준비 중입니다.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            fontWeight: AppTypography.regular,
          ),
        ),
      ),
    );
  }
}
