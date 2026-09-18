import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edencrew_assignment_starter/app/app.dart';

void main() {
  testWidgets('관심 탭과 검색 탭을 전환한다', (WidgetTester tester) async {
    await tester.pumpWidget(const EdencrewAssignmentApp());

    expect(find.byKey(const Key('watchlist_screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottom_nav_search')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_screen')), findsOneWidget);
  });
}
