import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/analytics_timeframe.dart';
import '../../providers/history_providers.dart';

class TimeframeSelectorBar extends ConsumerWidget {
  const TimeframeSelectorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(analyticsTimeframeProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: AnalyticsTimeframe.values.map((timeframe) {
          final isSelected = active == timeframe;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(timeframe.label),
              selected: isSelected,
              onSelected: (_) {
                ref.read(analyticsTimeframeProvider.notifier).state = timeframe;
                ref.read(analyticsControllerProvider.notifier).setTimeframe(timeframe);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
