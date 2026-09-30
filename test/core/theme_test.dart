import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fabric_haven/core/theme/app_colors.dart';
import 'package:fabric_haven/core/theme/app_theme.dart';

void main() {
  group('theme palette is unified with AppColors', () {
    test('AppTheme tokens alias the enterprise palette', () {
      expect(AppTheme.primaryColor, AppColors.primary);
      expect(AppTheme.secondaryColor, AppColors.accent);
      expect(AppTheme.backgroundColor, AppColors.background);
      expect(AppTheme.errorColor, AppColors.error);
    });

    test('the app bar does not fall back to the old purple', () {
      final theme = AppTheme.lightTheme;
      expect(theme.appBarTheme.backgroundColor, AppColors.primary);
      expect(theme.colorScheme.primary, AppColors.primary);
      // The splash screens use AppColors; launch and screens must agree.
      expect(AppColors.primary, const Color(0xFF0A6847));
    });
  });
}
