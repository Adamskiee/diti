import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/theme/app_colors.dart';
import 'package:diti/src/features/plan/presentation/widgets/conflict_warning_banner.dart';

void main() {
  group('ConflictWarningBanner', () {
    testWidgets('renders warning icon and description text', (tester) async {
      const description = '⚠️ Overlaps with Deep Work (09:00 - 10:00)';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConflictWarningBanner(
              description: description,
            ),
          ),
        ),
      );

      expect(find.text(description), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      final icon =
          tester.widget<Icon>(find.byIcon(Icons.warning_amber_rounded));
      expect(icon.color, AppColors.pausedAmber);
      expect(icon.size, 16);

      final text = tester.widget<Text>(find.text(description));
      expect(text.style?.color, AppColors.pausedAmber);
      expect(text.style?.fontSize, 12);
      expect(text.style?.fontWeight, FontWeight.w500);
    });
  });
}
