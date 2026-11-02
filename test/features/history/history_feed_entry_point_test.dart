import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti/src/features/history/presentation/widgets/history_feed_view.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti/src/core/di/repositories_provider.dart';

class MockSessionRepo implements SessionRepository {
  @override
  Future<List<SessionRecord>> getSessionsInRange(DateTime startUtc, DateTime endUtc) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('HistoryFeedView shows Log Session action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(MockSessionRepo()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HistoryFeedView()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byTooltip('Log Past Session'), findsOneWidget);
  });
}
