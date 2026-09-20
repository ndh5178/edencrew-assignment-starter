import 'package:edencrew_assignment_starter/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '실제 API로 검색부터 상세 차트와 관심 저장까지 확인한다',
    (WidgetTester tester) async {
      await _launchRealApp(tester);

      expect(find.byKey(const Key('watchlist_screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('bottom_nav_search')));
      await _waitFor(tester, find.byKey(const Key('search_screen')));

      await tester.enterText(
        find.byKey(const Key('stock_search_field')),
        '삼성',
      );
      await _waitFor(
        tester,
        find.byKey(const Key('search_result_005930')),
      );
      await _pauseForObservation(tester);

      await _removeSamsungFavoriteIfNeeded(tester);

      await tester.tap(find.byKey(const Key('favorite_button_005930')));
      await _waitFor(
        tester,
        find.byKey(const Key('favorite_active_005930')),
      );
      await _waitFor(tester, find.text('관심이 등록되었습니다'));
      expect(find.text('관심이 등록되었습니다'), findsOneWidget);
      await _pauseForObservation(tester);

      await tester.tap(find.byKey(const Key('bottom_nav_watchlist')));
      await _waitFor(
        tester,
        find.byKey(const Key('watchlist_item_005930')),
      );

      await tester.tap(find.byKey(const Key('watchlist_sort_button')));
      await _waitFor(
        tester,
        find.byKey(const Key('sort_option_currentPrice')),
      );
      await tester.tap(find.byKey(const Key('sort_option_currentPrice')));
      await _pauseForObservation(tester);

      await tester.tap(find.byKey(const Key('watchlist_item_005930')));
      await _waitFor(
        tester,
        find.byKey(const Key('stock_detail_screen')),
      );
      await _waitFor(
        tester,
        find.byKey(const Key('stock_detail_current_price')),
      );
      await _waitFor(
        tester,
        find.byKey(const Key('candlestick_chart')),
        maximumWait: const Duration(seconds: 60),
      );
      await _pauseForObservation(tester);

      await tester.tap(find.byKey(const Key('period_3_months')));
      await tester.pump(const Duration(milliseconds: 300));
      await _waitFor(
        tester,
        find.byKey(const Key('candlestick_chart')),
        maximumWait: const Duration(seconds: 90),
      );
      await _waitFor(
        tester,
        find.byKey(const Key('daily_price_list')),
      );
      await _pauseForObservation(tester);

      await tester.tap(find.byKey(const Key('favorite_button_005930')));
      await _waitFor(
        tester,
        find.byKey(const Key('favorite_inactive_005930')),
      );
      await _waitFor(tester, find.text('관심이 해제되었습니다'));
      expect(find.text('관심이 해제되었습니다'), findsOneWidget);

      await tester.tap(find.byKey(const Key('stock_detail_back_button')));
      await _waitForAbsent(
        tester,
        find.byKey(const Key('watchlist_item_005930')),
      );

      await tester.tap(find.byKey(const Key('bottom_nav_search')));
      await _waitFor(
        tester,
        find.byKey(const Key('search_result_005930')),
      );
      await tester.tap(find.byKey(const Key('favorite_button_005930')));
      await _waitFor(
        tester,
        find.byKey(const Key('favorite_active_005930')),
      );

      await _launchRealApp(tester);
      await tester.tap(find.byKey(const Key('bottom_nav_search')));
      await _waitFor(tester, find.byKey(const Key('search_screen')));
      await tester.enterText(
        find.byKey(const Key('stock_search_field')),
        '삼성',
      );
      await _waitFor(
        tester,
        find.byKey(const Key('favorite_active_005930')),
      );
      await _pauseForObservation(tester);

      // 다음 실행도 같은 초기 조건에서 시작하도록 테스트가 만든 관심 상태를 정리합니다.
      await tester.tap(find.byKey(const Key('favorite_button_005930')));
      await _waitFor(
        tester,
        find.byKey(const Key('favorite_inactive_005930')),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _launchRealApp(WidgetTester tester) async {
  runApp(const EdencrewAssignmentApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _removeSamsungFavoriteIfNeeded(WidgetTester tester) async {
  final Finder activeFavorite = find.byKey(
    const Key('favorite_active_005930'),
  );

  if (activeFavorite.evaluate().isEmpty) {
    return;
  }

  await tester.tap(find.byKey(const Key('favorite_button_005930')));
  await _waitFor(
    tester,
    find.byKey(const Key('favorite_inactive_005930')),
  );
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration maximumWait = const Duration(seconds: 30),
}) async {
  const Duration interval = Duration(milliseconds: 250);
  final int maximumAttempts =
      maximumWait.inMilliseconds ~/ interval.inMilliseconds;

  for (int attempt = 0; attempt < maximumAttempts; attempt += 1) {
    await tester.pump(interval);

    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('제한 시간 안에 위젯을 찾지 못했습니다: $finder');
}

Future<void> _waitForAbsent(
  WidgetTester tester,
  Finder finder, {
  Duration maximumWait = const Duration(seconds: 30),
}) async {
  const Duration interval = Duration(milliseconds: 250);
  final int maximumAttempts =
      maximumWait.inMilliseconds ~/ interval.inMilliseconds;

  for (int attempt = 0; attempt < maximumAttempts; attempt += 1) {
    await tester.pump(interval);

    if (finder.evaluate().isEmpty) {
      return;
    }
  }

  throw TestFailure('제한 시간 안에 위젯이 사라지지 않았습니다: $finder');
}

Future<void> _pauseForObservation(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
}
