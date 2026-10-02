/// Compact, human-readable "time ago" text for dashboards and lists.
///
/// Kept pure (the reference time is injectable) so it can be unit-tested
/// without freezing the clock.
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time);

  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h ${h == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }
  if (diff.inDays < 30) {
    final w = diff.inDays ~/ 7;
    return '$w ${w == 1 ? 'week' : 'weeks'} ago';
  }
  if (diff.inDays < 365) {
    final mo = diff.inDays ~/ 30;
    return '$mo ${mo == 1 ? 'month' : 'months'} ago';
  }
  final y = diff.inDays ~/ 365;
  return '$y ${y == 1 ? 'year' : 'years'} ago';
}
