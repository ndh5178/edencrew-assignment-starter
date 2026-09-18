import 'package:flutter/material.dart';

import '../../data/models/stock.dart';
import '../../data/naver_stock_service.dart';
import '../favorites/favorite_controller.dart';
import '../../theme/theme.dart';
import 'search_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    required this.searchService,
    required this.favoriteController,
    super.key,
  });

  final StockSearchService searchService;
  final FavoriteController favoriteController;

  @override
  State<SearchScreen> createState() {
    return _SearchScreenState();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  late final StockSearchController _searchController;
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _searchController = StockSearchController(
      searchService: widget.searchService,
    );
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SafeArea(
      key: const Key('search_screen'),
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              dimens.space4,
              dimens.space4,
              dimens.space4,
              dimens.space3,
            ),
            child: SizedBox(
              height: 40,
              child: TextField(
                key: const Key('stock_search_field'),
                controller: _textEditingController,
                onChanged: _searchController.onQueryChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: AppTypography.medium,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '종목명 또는 종목코드',
                  hintStyle: TextStyle(
                    color: colors.textDisabled,
                    fontSize: 16,
                    fontWeight: AppTypography.medium,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colors.textDisabled,
                    size: 22,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  suffixIcon: IconButton(
                    key: const Key('clear_search_button'),
                    onPressed: _clearSearch,
                    icon: Icon(
                      Icons.close,
                      color: colors.textDisabled,
                      size: 22,
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  filled: true,
                  fillColor: colors.surfaceRaised,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(dimens.radiusMd),
                    borderSide: BorderSide(
                      color: colors.borderStrong,
                      width: dimens.borderHairline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(dimens.radiusMd),
                    borderSide: BorderSide(
                      color: colors.borderStrong,
                      width: dimens.borderHairline,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _searchController,
                widget.favoriteController,
              ]),
              builder: (BuildContext context, Widget? child) {
                return _buildSearchContent(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _textEditingController.clear();
    _searchController.clearSearch();
  }

  Widget _buildSearchContent(BuildContext context) {
    switch (_searchController.status) {
      case SearchStatus.initial:
        return const _SearchInitialView();
      case SearchStatus.loading:
        return const _SearchLoadingView();
      case SearchStatus.success:
        return _SearchResultList(
          stocks: _searchController.results,
          query: _searchController.query,
          favoriteController: widget.favoriteController,
          onFavoritePressed: _toggleFavorite,
        );
      case SearchStatus.empty:
        return _SearchEmptyView(query: _searchController.query);
      case SearchStatus.failure:
        return _SearchFailureView(onRetry: _searchController.retry);
    }
  }

  Future<void> _toggleFavorite(Stock stock) async {
    try {
      final FavoriteChange? change =
          await widget.favoriteController.toggleFavorite(stock.symbol);

      if (!mounted || change == null) {
        return;
      }

      _showFavoriteToast(change);
    } on Object {
      if (!mounted) {
        return;
      }

      _showStorageFailureToast();
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
              color: wasAdded
                  ? colors.favoriteActive
                  : colors.favoriteInactive,
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

  void _showStorageFailureToast() {
    final AppColors colors = context.colors;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceSunken,
        content: Text(
          '관심 종목을 저장하지 못했습니다',
          style: TextStyle(color: colors.textPrimary),
        ),
      ),
    );
  }
}

class _SearchInitialView extends StatelessWidget {
  const _SearchInitialView();

  @override
  Widget build(BuildContext context) {
    return const _CenteredSearchMessage(
      icon: Icons.search,
      title: '종목을 검색해 보세요',
      description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
    );
  }
}

class _SearchLoadingView extends StatelessWidget {
  const _SearchLoadingView();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: colors.accentDefault,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _SearchEmptyView extends StatelessWidget {
  const _SearchEmptyView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return _CenteredSearchMessage(
      icon: Icons.search_off,
      title: '검색 결과가 없습니다',
      description: '‘$query’와\n일치하는 검색 결과를 찾지 못했습니다.',
    );
  }
}

class _SearchFailureView extends StatelessWidget {
  const _SearchFailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: colors.textTertiary,
            size: 40,
          ),
          SizedBox(height: dimens.space3),
          Text(
            '검색 결과를 불러오지 못했습니다',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 18,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: dimens.space4),
          TextButton(
            onPressed: onRetry,
            child: Text(
              '다시 시도',
              style: TextStyle(
                color: colors.accentDefault,
                fontSize: 14,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredSearchMessage extends StatelessWidget {
  const _CenteredSearchMessage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            color: colors.textTertiary,
            size: 40,
          ),
          SizedBox(height: dimens.space3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 20,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: dimens.space2),
          Text(
            description,
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

class _SearchResultList extends StatelessWidget {
  const _SearchResultList({
    required this.stocks,
    required this.query,
    required this.favoriteController,
    required this.onFavoritePressed,
  });

  final List<Stock> stocks;
  final String query;
  final FavoriteController favoriteController;
  final ValueChanged<Stock> onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: stocks.length,
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          height: 1,
          thickness: context.dimens.borderHairline,
          color: context.colors.borderSubtle,
        );
      },
      itemBuilder: (BuildContext context, int index) {
        final Stock stock = stocks[index];

        return _SearchResultRow(
          stock: stock,
          query: query,
          isFavorite: favoriteController.isFavorite(stock.symbol),
          isUpdating: favoriteController.isUpdating(stock.symbol),
          onFavoritePressed: () {
            onFavoritePressed(stock);
          },
        );
      },
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.stock,
    required this.query,
    required this.isFavorite,
    required this.isUpdating,
    required this.onFavoritePressed,
  });

  final Stock stock;
  final String query;
  final bool isFavorite;
  final bool isUpdating;
  final VoidCallback onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      key: Key('search_result_${stock.symbol}'),
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
                _HighlightedStockName(name: stock.name, query: query),
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
            padding: EdgeInsets.only(left: dimens.space3),
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
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
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedStockName extends StatelessWidget {
  const _HighlightedStockName({
    required this.name,
    required this.query,
  });

  final String name;
  final String query;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String lowerName = name.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final int matchStart = lowerName.indexOf(lowerQuery);
    final TextStyle normalStyle = TextStyle(
      color: colors.textPrimary,
      fontSize: 16,
      fontWeight: AppTypography.medium,
    );

    if (matchStart < 0 || query.isEmpty) {
      return Text(name, style: normalStyle);
    }

    final int matchEnd = matchStart + query.length;

    return Text.rich(
      TextSpan(
        style: normalStyle,
        children: <InlineSpan>[
          TextSpan(text: name.substring(0, matchStart)),
          TextSpan(
            text: name.substring(matchStart, matchEnd),
            style: normalStyle.copyWith(color: colors.searchHighlight),
          ),
          TextSpan(text: name.substring(matchEnd)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
