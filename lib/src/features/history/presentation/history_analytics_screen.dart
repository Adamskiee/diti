import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_providers.dart';
import 'widgets/analytics_view.dart';
import 'widgets/history_feed_view.dart';

class HistoryAnalyticsScreen extends ConsumerWidget {
  const HistoryAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(historyActiveTabProvider);

    return Scaffold(
      appBar: AppBar(
        title: SegmentedButton<HistoryTab>(
          segments: const [
            ButtonSegment(
              value: HistoryTab.analytics,
              label: Text('Analytics'),
              icon: Icon(Icons.bar_chart),
            ),
            ButtonSegment(
              value: HistoryTab.history,
              label: Text('History'),
              icon: Icon(Icons.history),
            ),
          ],
          selected: {activeTab},
          onSelectionChanged: (selection) {
            ref.read(historyActiveTabProvider.notifier).state = selection.first;
          },
        ),
        centerTitle: true,
      ),
      body: activeTab == HistoryTab.analytics
          ? const AnalyticsView()
          : const HistoryFeedView(),
    );
  }
}
