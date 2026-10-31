class DurationFormatter {
  const DurationFormatter._();

  static String formatMs(int ms) {
    final isNegative = ms < 0;
    final absMs = ms.abs();
    final totalSeconds = (absMs / 1000).floor();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    final prefix = (isNegative && totalSeconds > 0) ? '-' : '';
    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$prefix$hStr:$mStr:$sStr';
    }
    return '$prefix$mStr:$sStr';
  }

  static String formatDurationSummary(int? ms) {
    if (ms == null) return 'Open-ended';
    final clampedMs = ms < 0 ? 0 : ms;
    final totalMinutes = (clampedMs / 60000).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      final mStr = minutes.toString().padLeft(2, '0');
      return '${hours}h ${mStr}m';
    }
    return '${minutes}m';
  }
}
