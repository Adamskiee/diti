import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/timer_engine_provider.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../providers/plan_providers.dart';

/// Date navigation strip showing previous/next day arrows, date picker dialog trigger,
/// "Today" chip if date is not today, and planned vs done duration metrics.
class DateSelectorStrip extends ConsumerWidget {
  final int totalPlannedMs;
  final int totalActualMs;

  const DateSelectorStrip({
    super.key,
    required this.totalPlannedMs,
    required this.totalActualMs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final controller = ref.read(dailyPlanControllerProvider.notifier);
    final theme = Theme.of(context);

    final now = ref.watch(wallClockProvider).utcNow.toLocal();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final plannedText = DurationFormatter.formatDurationSummary(totalPlannedMs);
    final actualText = DurationFormatter.formatDurationSummary(totalActualMs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('date_nav_prev'),
                icon: const Icon(Icons.chevron_left),
                onPressed: () => controller.previousDay(),
                tooltip: 'Previous day',
              ),
              Expanded(
                child: InkWell(
                  key: const Key('date_picker_button'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      controller.setDate(picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.MMMMEEEEd().format(selectedDate),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('date_nav_next'),
                icon: const Icon(Icons.chevron_right),
                onPressed: () => controller.nextDay(),
                tooltip: 'Next day',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isToday)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('Today'),
                    onPressed: () => controller.setToday(),
                  ),
                ),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  'Planned: $plannedText · Done: $actualText',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
