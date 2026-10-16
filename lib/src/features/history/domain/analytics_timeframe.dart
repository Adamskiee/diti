import 'package:flutter/material.dart';

enum AnalyticsTimeframe {
  today,
  thisWeek,
  last30Days;

  DateTimeRange computeRange(DateTime now) {
    final localNow = now.isUtc ? now.toLocal() : now;
    final todayStart = DateTime(localNow.year, localNow.month, localNow.day);

    switch (this) {
      case AnalyticsTimeframe.today:
        return DateTimeRange(
          start: todayStart,
          end: todayStart.add(const Duration(days: 1)),
        );
      case AnalyticsTimeframe.thisWeek:
        // Week starts Monday (weekday = 1)
        final daysFromMonday = localNow.weekday - DateTime.monday;
        final mondayStart = todayStart.subtract(Duration(days: daysFromMonday));
        return DateTimeRange(
          start: mondayStart,
          end: mondayStart.add(const Duration(days: 7)),
        );
      case AnalyticsTimeframe.last30Days:
        final thirtyDaysAgo = todayStart.subtract(const Duration(days: 29));
        return DateTimeRange(
          start: thirtyDaysAgo,
          end: todayStart.add(const Duration(days: 1)),
        );
    }
  }

  String get label {
    switch (this) {
      case AnalyticsTimeframe.today:
        return 'Today';
      case AnalyticsTimeframe.thisWeek:
        return 'This Week';
      case AnalyticsTimeframe.last30Days:
        return 'Last 30 Days';
    }
  }
}
