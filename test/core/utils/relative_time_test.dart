import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/core/utils/relative_time.dart';

void main() {
  group('formatRelativeTime', () {
    final now = DateTime(2026, 5, 20, 12, 0, 0);

    test('renders seconds as "just now"', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(seconds: 30)), now: now),
        'just now',
      );
    });

    test('renders minutes, singular and plural', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now),
        '5 minutes ago',
      );
    });

    test('renders hours', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now),
        '3 hours ago',
      );
    });

    test('renders days', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 2)), now: now),
        '2 days ago',
      );
    });

    test('rolls days into weeks, months and years', () {
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 14)), now: now),
        '2 weeks ago',
      );
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 60)), now: now),
        '2 months ago',
      );
      expect(
        formatRelativeTime(now.subtract(const Duration(days: 400)), now: now),
        '1 year ago',
      );
    });

    test('treats a future timestamp as "just now" rather than negative', () {
      expect(
        formatRelativeTime(now.add(const Duration(minutes: 5)), now: now),
        'just now',
      );
    });
  });
}
